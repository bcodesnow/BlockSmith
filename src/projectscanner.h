#pragma once

#include <QObject>
#include <QStringList>
#include <QtQml/qqmlregistration.h>

class ConfigManager;
class ProjectTreeModel;
class TreeNode;

class ProjectScanner : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Use via AppController.projectScanner")

public:
    explicit ProjectScanner(ConfigManager *config, ProjectTreeModel *model,
                            QObject *parent = nullptr);

    Q_INVOKABLE void scan();

signals:
    void scanStarted();
    void scanComplete(int projectCount);

private:
    bool isIgnored(const QString &dirName) const;
    bool containsTriggerFile(const QString &dirPath) const;
    void scanRecursive(const QString &dirPath, int depth, int maxDepth,
                        TreeNode *shadowRoot, int &projectCount);
    void collectMdFiles(const QString &dirPath, TreeNode *parentNode, int depth = 0);
    void collectAllFiles(const QString &dirPath, TreeNode *parentNode, int depth = 0);

    ConfigManager *m_config;
    ProjectTreeModel *m_model;
};
