#include "projectscanner.h"
#include "configmanager.h"
#include "projecttreemodel.h"

#include <QCoreApplication>
#include <QDir>
#include <QFileInfo>
#include <QPointer>
#include <QTimer>
#include <QtConcurrent>

namespace {

constexpr int kMaxCollectDepth = 20;

bool isIgnored(const QString &dirName, const QStringList &patterns)
{
    for (const QString &pattern : patterns) {
        if (dirName.compare(pattern, Qt::CaseInsensitive) == 0)
            return true;
    }
    return false;
}

bool containsTriggerFile(const QString &dirPath, const QStringList &triggers)
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

void collectAllFiles(const QString &dirPath, TreeNode *parentNode,
                     const QStringList &patterns,
                     const std::shared_ptr<std::atomic<bool>> &cancel,
                     int depth = 0)
{
    if (depth >= kMaxCollectDepth || cancel->load())
        return;

    QDir dir(dirPath);

    const auto subdirs = dir.entryInfoList(QDir::Dirs | QDir::NoDotAndDotDot | QDir::Hidden,
                                           QDir::Name);
    for (const QFileInfo &subdir : subdirs) {
        if (cancel->load())
            return;
        if (isIgnored(subdir.fileName(), patterns))
            continue;

        auto *dirNode = new TreeNode(
            subdir.fileName(), subdir.absoluteFilePath(),
            TreeNode::Directory, false, parentNode);
        dirNode->setCreatedDate(subdir.birthTime());

        collectAllFiles(subdir.absoluteFilePath(), dirNode, patterns, cancel, depth + 1);

        if (dirNode->childCount() > 0)
            parentNode->appendChild(dirNode);
        else
            delete dirNode;
    }

    const auto files = dir.entryInfoList({"*.md", "*.markdown", "*.jsonl", "*.json", "*.yaml", "*.yml", "*.txt"},
                                         QDir::Files, QDir::Name);
    for (const QFileInfo &file : files) {
        if (cancel->load())
            return;

        auto *fileNode = new TreeNode(
            file.fileName(), file.absoluteFilePath(),
            TreeNode::FileNode, false, parentNode);
        parentNode->appendChild(fileNode);
    }
}

void collectProjectFiles(const QString &dirPath, TreeNode *parentNode,
                         const QStringList &patterns, const QStringList &triggers,
                         const std::shared_ptr<std::atomic<bool>> &cancel,
                         int depth = 0)
{
    if (depth >= kMaxCollectDepth || cancel->load())
        return;

    QDir dir(dirPath);

    const auto subdirs = dir.entryInfoList(QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name);
    for (const QFileInfo &subdir : subdirs) {
        if (cancel->load())
            return;
        if (isIgnored(subdir.fileName(), patterns))
            continue;

        auto *dirNode = new TreeNode(
            subdir.fileName(), subdir.absoluteFilePath(),
            TreeNode::Directory, false, parentNode);
        dirNode->setCreatedDate(subdir.birthTime());

        collectProjectFiles(subdir.absoluteFilePath(), dirNode, patterns, triggers, cancel, depth + 1);

        if (dirNode->childCount() > 0)
            parentNode->appendChild(dirNode);
        else
            delete dirNode;
    }

    const auto files = dir.entryInfoList({"*.md", "*.markdown", "*.jsonl", "*.json", "*.yaml", "*.yml", "*.txt"},
                                         QDir::Files, QDir::Name);
    for (const QFileInfo &file : files) {
        if (cancel->load())
            return;

        bool isTrigger = false;
        for (const QString &trigger : triggers) {
            if (file.fileName().compare(trigger, Qt::CaseInsensitive) == 0) {
                isTrigger = true;
                break;
            }
        }

        auto *fileNode = new TreeNode(
            file.fileName(), file.absoluteFilePath(),
            TreeNode::FileNode, isTrigger, parentNode);
        parentNode->appendChild(fileNode);
    }
}

void scanRecursive(const QString &dirPath, int depth, int maxDepth,
                   const QStringList &patterns, const QStringList &triggers,
                   TreeNode *shadowRoot, int &projectCount,
                   const std::shared_ptr<std::atomic<bool>> &cancel)
{
    if ((maxDepth > 0 && depth > maxDepth) || cancel->load())
        return;

    QDir dir(dirPath);
    const auto entries = dir.entryInfoList(QDir::Dirs | QDir::NoDotAndDotDot);

    for (const QFileInfo &entry : entries) {
        if (cancel->load())
            return;
        if (isIgnored(entry.fileName(), patterns))
            continue;

        const QString entryPath = entry.absoluteFilePath();
        if (containsTriggerFile(entryPath, triggers)) {
            auto *projectNode = new TreeNode(
                entry.fileName(), entryPath,
                TreeNode::ProjectRoot, false, shadowRoot);
            projectNode->setCreatedDate(entry.birthTime());

            collectProjectFiles(entryPath, projectNode, patterns, triggers, cancel);
            shadowRoot->appendChild(projectNode);
            projectCount++;
        } else {
            scanRecursive(entryPath, depth + 1, maxDepth,
                          patterns, triggers, shadowRoot, projectCount, cancel);
        }
    }
}

} // namespace

ProjectScanner::ProjectScanner(ConfigManager *config, ProjectTreeModel *model,
                               QObject *parent)
    : QObject(parent)
    , m_config(config)
    , m_model(model)
{
}

void ProjectScanner::scan()
{
    if (m_scanCancel)
        m_scanCancel->store(true);

    emit scanStarted();

    const QStringList searchPaths = m_config->searchPaths();
    const QStringList ignorePatterns = m_config->ignorePatterns();
    const QStringList triggerFiles = m_config->triggerFiles();
    const int maxDepth = m_config->scanDepth();
    const bool includeClaudeCode = m_config->includeClaudeCodeFolder();
    const QString claudePath = m_config->claudeCodeFolderPath();

    auto cancel = std::make_shared<std::atomic<bool>>(false);
    m_scanCancel = cancel;

    QPointer<ProjectScanner> receiver(this);
    (void)QtConcurrent::run([receiver, searchPaths, ignorePatterns, triggerFiles,
                             maxDepth, includeClaudeCode, claudePath, cancel]() {
        auto *shadowRoot = new TreeNode(QStringLiteral("root"), QString(), TreeNode::Directory);
        int projectCount = 0;

        for (const QString &searchPath : searchPaths) {
            if (cancel->load())
                break;

            QDir dir(searchPath);
            if (!dir.exists())
                continue;

            if (containsTriggerFile(searchPath, triggerFiles)) {
                QFileInfo pathInfo(searchPath);
                auto *projectNode = new TreeNode(
                    pathInfo.fileName(), searchPath,
                    TreeNode::ProjectRoot, false, shadowRoot);
                projectNode->setCreatedDate(pathInfo.birthTime());

                collectProjectFiles(searchPath, projectNode, ignorePatterns, triggerFiles, cancel);
                shadowRoot->appendChild(projectNode);
                projectCount++;
            }

            if (cancel->load())
                break;

            scanRecursive(searchPath, 1, maxDepth,
                          ignorePatterns, triggerFiles,
                          shadowRoot, projectCount, cancel);
        }

        if (!cancel->load() && includeClaudeCode) {
            QDir claudeDir(claudePath);
            if (claudeDir.exists()) {
                QFileInfo claudeInfo(claudePath);
                auto *claudeNode = new TreeNode(
                    QStringLiteral(".claude"), claudePath,
                    TreeNode::ProjectRoot, false, shadowRoot);
                claudeNode->setCreatedDate(claudeInfo.birthTime());

                collectAllFiles(claudePath, claudeNode, ignorePatterns, cancel);
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

        QTimer::singleShot(0, QCoreApplication::instance(), [receiver, shadowRoot, projectCount]() {
            if (!receiver) {
                delete shadowRoot;
                return;
            }

            receiver->m_model->syncChildren(receiver->m_model->rootNode(), shadowRoot);
            delete shadowRoot;
            emit receiver->scanComplete(projectCount);
        });
    });
}
