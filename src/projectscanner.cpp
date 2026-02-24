#include "projectscanner.h"
#include "configmanager.h"
#include "projecttreemodel.h"

#include <QDir>
#include <QDirIterator>
#include <QFileInfo>
#include <QtConcurrent>
#include <QTimer>

ProjectScanner::ProjectScanner(ConfigManager *config, ProjectTreeModel *model,
                               QObject *parent)
    : QObject(parent)
    , m_config(config)
    , m_model(model)
{
}

void ProjectScanner::scan()
{
    // Cancel any in-flight scan
    if (m_scanCancel)
        m_scanCancel->store(true);

    emit scanStarted();

    // Snapshot config values for thread-safe access
    const QStringList searchPaths = m_config->searchPaths();
    const QStringList ignorePatterns = m_config->ignorePatterns();
    const QStringList triggerFiles = m_config->triggerFiles();
    const int maxDepth = m_config->scanDepth();
    const bool includeClaudeCode = m_config->includeClaudeCodeFolder();
    const QString claudePath = m_config->claudeCodeFolderPath();

    auto cancel = std::make_shared<std::atomic<bool>>(false);
    m_scanCancel = cancel;

    // Capture raw pointer — safe because ProjectScanner lives for the entire
    // application lifetime (owned by AppController).
    ProjectScanner *ctx = this;

    QtConcurrent::run([ctx, searchPaths, ignorePatterns, triggerFiles,
                       maxDepth, includeClaudeCode, claudePath, cancel]() {
        // Build shadow tree on background thread (pure file I/O, no model signals)
        auto *shadowRoot = new TreeNode("root", "", TreeNode::Directory);
        int projectCount = 0;

        for (const QString &searchPath : searchPaths) {
            if (cancel->load()) break;

            QDir dir(searchPath);
            if (!dir.exists())
                continue;

            // Check if the search path itself is a project root
            if (ctx->containsTriggerFile(searchPath, triggerFiles)) {
                QFileInfo pathInfo(searchPath);
                auto *projectNode = new TreeNode(
                    pathInfo.fileName(), searchPath,
                    TreeNode::ProjectRoot, false, shadowRoot);
                projectNode->setCreatedDate(pathInfo.birthTime());

                ctx->collectMdFiles(searchPath, projectNode, ignorePatterns, triggerFiles);
                shadowRoot->appendChild(projectNode);
                projectCount++;
            }

            if (cancel->load()) break;

            ctx->scanRecursive(searchPath, 1, maxDepth,
                               ignorePatterns, triggerFiles,
                               shadowRoot, projectCount, cancel);
        }

        // Claude Code folder
        if (!cancel->load() && includeClaudeCode) {
            QDir claudeDir(claudePath);
            if (claudeDir.exists()) {
                QFileInfo claudeInfo(claudePath);
                auto *claudeNode = new TreeNode(
                    QStringLiteral(".claude"), claudePath,
                    TreeNode::ProjectRoot, false, shadowRoot);
                claudeNode->setCreatedDate(claudeInfo.birthTime());

                ctx->collectAllFiles(claudePath, claudeNode, ignorePatterns);
                if (claudeNode->childCount() > 0) {
                    shadowRoot->appendChild(claudeNode);
                    projectCount++;
                } else {
                    delete claudeNode;
                }
            }
        }

        if (cancel->load()) {
            delete shadowRoot;
            return;
        }

        // Deliver results to main thread via QTimer::singleShot
        QTimer::singleShot(0, ctx, [ctx, shadowRoot, projectCount]() {
            // Diff the shadow tree against the live model tree (on main thread)
            ctx->m_model->syncChildren(ctx->m_model->rootNode(), shadowRoot);
            delete shadowRoot;

            emit ctx->scanComplete(projectCount);
        });
    });
}

void ProjectScanner::scanRecursive(const QString &dirPath, int depth,
                                    int maxDepth,
                                    const QStringList &patterns,
                                    const QStringList &triggers,
                                    TreeNode *shadowRoot, int &projectCount,
                                    const std::shared_ptr<std::atomic<bool>> &cancel)
{
    if (maxDepth > 0 && depth > maxDepth)
        return;
    if (cancel->load())
        return;

    QDir dir(dirPath);
    const auto entries = dir.entryInfoList(QDir::Dirs | QDir::NoDotAndDotDot);

    for (const QFileInfo &entry : entries) {
        if (cancel->load()) return;
        if (isIgnored(entry.fileName(), patterns))
            continue;

        const QString entryPath = entry.absoluteFilePath();

        if (containsTriggerFile(entryPath, triggers)) {
            auto *projectNode = new TreeNode(
                entry.fileName(), entryPath,
                TreeNode::ProjectRoot, false, shadowRoot);
            projectNode->setCreatedDate(entry.birthTime());

            collectMdFiles(entryPath, projectNode, patterns, triggers);
            shadowRoot->appendChild(projectNode);
            projectCount++;
        } else {
            scanRecursive(entryPath, depth + 1, maxDepth,
                          patterns, triggers, shadowRoot, projectCount, cancel);
        }
    }
}

bool ProjectScanner::isIgnored(const QString &dirName, const QStringList &patterns) const
{
    for (const QString &pattern : patterns) {
        if (dirName.compare(pattern, Qt::CaseInsensitive) == 0)
            return true;
    }
    return false;
}

bool ProjectScanner::containsTriggerFile(const QString &dirPath,
                                          const QStringList &triggers) const
{
    QDir dir(dirPath);

    const auto files = dir.entryList(QDir::Files);
    for (const QString &fileName : files) {
        for (const QString &trigger : triggers) {
            if (fileName.compare(trigger, Qt::CaseInsensitive) == 0)
                return true;
        }
    }

    const auto dirs = dir.entryList(QDir::Dirs | QDir::NoDotAndDotDot | QDir::Hidden);
    for (const QString &dirName : dirs) {
        for (const QString &trigger : triggers) {
            if (dirName.compare(trigger, Qt::CaseInsensitive) == 0)
                return true;
        }
    }

    return false;
}

void ProjectScanner::collectAllFiles(const QString &dirPath, TreeNode *parentNode,
                                      const QStringList &patterns, int depth)
{
    static constexpr int kMaxCollectDepth = 20;
    if (depth >= kMaxCollectDepth)
        return;

    QDir dir(dirPath);

    const auto subdirs = dir.entryInfoList(QDir::Dirs | QDir::NoDotAndDotDot | QDir::Hidden,
                                            QDir::Name);
    for (const QFileInfo &subdir : subdirs) {
        if (isIgnored(subdir.fileName(), patterns))
            continue;

        auto *dirNode = new TreeNode(
            subdir.fileName(), subdir.absoluteFilePath(),
            TreeNode::Directory, false, parentNode);
        dirNode->setCreatedDate(subdir.birthTime());

        collectAllFiles(subdir.absoluteFilePath(), dirNode, patterns, depth + 1);

        if (dirNode->childCount() > 0) {
            parentNode->appendChild(dirNode);
        } else {
            delete dirNode;
        }
    }

    const auto files = dir.entryInfoList({"*.md", "*.jsonl", "*.json"}, QDir::Files, QDir::Name);
    for (const QFileInfo &file : files) {
        auto *fileNode = new TreeNode(
            file.fileName(), file.absoluteFilePath(),
            TreeNode::MdFile, false, parentNode);
        parentNode->appendChild(fileNode);
    }
}

void ProjectScanner::collectMdFiles(const QString &dirPath, TreeNode *parentNode,
                                     const QStringList &patterns,
                                     const QStringList &triggers, int depth)
{
    static constexpr int kMaxCollectDepth = 20;
    if (depth >= kMaxCollectDepth)
        return;

    QDir dir(dirPath);

    const auto subdirs = dir.entryInfoList(QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name);
    for (const QFileInfo &subdir : subdirs) {
        if (isIgnored(subdir.fileName(), patterns))
            continue;

        auto *dirNode = new TreeNode(
            subdir.fileName(), subdir.absoluteFilePath(),
            TreeNode::Directory, false, parentNode);
        dirNode->setCreatedDate(subdir.birthTime());

        collectMdFiles(subdir.absoluteFilePath(), dirNode, patterns, triggers, depth + 1);

        if (dirNode->childCount() > 0) {
            parentNode->appendChild(dirNode);
        } else {
            delete dirNode;
        }
    }

    const auto files = dir.entryInfoList({"*.md", "*.jsonl", "*.json"}, QDir::Files, QDir::Name);
    for (const QFileInfo &file : files) {
        bool isTrigger = false;
        for (const QString &trigger : triggers) {
            if (file.fileName().compare(trigger, Qt::CaseInsensitive) == 0) {
                isTrigger = true;
                break;
            }
        }

        auto *fileNode = new TreeNode(
            file.fileName(), file.absoluteFilePath(),
            TreeNode::MdFile, isTrigger, parentNode);
        parentNode->appendChild(fileNode);
    }
}
