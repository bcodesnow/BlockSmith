#include "projectscanner.h"
#include "configmanager.h"
#include "projecttreemodel.h"

#include <QDir>
#include <QDirIterator>
#include <QFileInfo>

ProjectScanner::ProjectScanner(ConfigManager *config, ProjectTreeModel *model,
                               QObject *parent)
    : QObject(parent)
    , m_config(config)
    , m_model(model)
{
}

void ProjectScanner::scan()
{
    emit scanStarted();

    m_model->clear();

    int maxDepth = m_config->scanDepth(); // 0 = unlimited
    int projectCount = 0;

    for (const QString &searchPath : m_config->searchPaths()) {
        QDir dir(searchPath);
        if (!dir.exists()) {
            qWarning("ProjectScanner: search path does not exist: %s",
                     qPrintable(searchPath));
            continue;
        }

        // Check if the search path itself is a project root
        if (containsTriggerFile(searchPath)) {
            QFileInfo pathInfo(searchPath);
            auto *projectNode = new TreeNode(
                pathInfo.fileName(),
                searchPath,
                TreeNode::ProjectRoot,
                false,
                m_model->rootNode());

            collectMdFiles(searchPath, projectNode);
            m_model->addProjectRoot(projectNode);
            projectCount++;
        }

        // Recurse into subdirectories looking for projects
        scanRecursive(searchPath, 1, maxDepth, projectCount);
    }

    emit scanComplete(projectCount);
}

void ProjectScanner::scanRecursive(const QString &dirPath, int depth,
                                    int maxDepth, int &projectCount)
{
    if (maxDepth > 0 && depth > maxDepth)
        return;

    QDir dir(dirPath);
    const auto entries = dir.entryInfoList(QDir::Dirs | QDir::NoDotAndDotDot);

    for (const QFileInfo &entry : entries) {
        if (isIgnored(entry.fileName()))
            continue;

        const QString entryPath = entry.absoluteFilePath();

        if (containsTriggerFile(entryPath)) {
            auto *projectNode = new TreeNode(
                entry.fileName(),
                entryPath,
                TreeNode::ProjectRoot,
                false,
                m_model->rootNode());

            collectMdFiles(entryPath, projectNode);
            m_model->addProjectRoot(projectNode);
            projectCount++;
            // Don't recurse into project roots — they're leaf projects
        } else {
            // Not a project, keep searching deeper
            scanRecursive(entryPath, depth + 1, maxDepth, projectCount);
        }
    }
}

bool ProjectScanner::isIgnored(const QString &dirName) const
{
    const auto &patterns = m_config->ignorePatterns();
    for (const QString &pattern : patterns) {
        if (dirName.compare(pattern, Qt::CaseInsensitive) == 0)
            return true;
    }
    return false;
}

bool ProjectScanner::containsTriggerFile(const QString &dirPath) const
{
    QDir dir(dirPath);
    const auto &triggers = m_config->triggerFiles();

    // Check files
    const auto files = dir.entryList(QDir::Files);
    for (const QString &fileName : files) {
        for (const QString &trigger : triggers) {
            if (fileName.compare(trigger, Qt::CaseInsensitive) == 0)
                return true;
        }
    }

    // Check directories (for markers like .git)
    const auto dirs = dir.entryList(QDir::Dirs | QDir::NoDotAndDotDot | QDir::Hidden);
    for (const QString &dirName : dirs) {
        for (const QString &trigger : triggers) {
            if (dirName.compare(trigger, Qt::CaseInsensitive) == 0)
                return true;
        }
    }

    return false;
}

void ProjectScanner::collectMdFiles(const QString &dirPath, TreeNode *parentNode)
{
    QDir dir(dirPath);
    const auto &triggers = m_config->triggerFiles();

    // Directories first
    const auto subdirs = dir.entryInfoList(QDir::Dirs | QDir::NoDotAndDotDot,
                                            QDir::Name);
    for (const QFileInfo &subdir : subdirs) {
        if (isIgnored(subdir.fileName()))
            continue;

        // Only add directory nodes if they contain .md files (directly or nested)
        auto *dirNode = new TreeNode(
            subdir.fileName(),
            subdir.absoluteFilePath(),
            TreeNode::Directory,
            false,
            parentNode);

        collectMdFiles(subdir.absoluteFilePath(), dirNode);

        // Only add directory if it has children
        if (dirNode->childCount() > 0) {
            parentNode->appendChild(dirNode);
        } else {
            delete dirNode;
        }
    }

    // Then files
    const auto files = dir.entryInfoList({"*.md"}, QDir::Files, QDir::Name);
    for (const QFileInfo &file : files) {
        bool isTrigger = false;
        for (const QString &trigger : triggers) {
            if (file.fileName().compare(trigger, Qt::CaseInsensitive) == 0) {
                isTrigger = true;
                break;
            }
        }

        auto *fileNode = new TreeNode(
            file.fileName(),
            file.absoluteFilePath(),
            TreeNode::MdFile,
            isTrigger,
            parentNode);
        parentNode->appendChild(fileNode);
    }
}
