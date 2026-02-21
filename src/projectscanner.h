#pragma once

#include <QObject>
#include <QStringList>
#include <QtQml/qqmlregistration.h>
#include <atomic>
#include <memory>

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
    bool isIgnored(const QString &dirName, const QStringList &patterns) const;
    bool containsTriggerFile(const QString &dirPath, const QStringList &triggers) const;
    void scanRecursive(const QString &dirPath, int depth, int maxDepth,
                        const QStringList &patterns, const QStringList &triggers,
                        TreeNode *shadowRoot, int &projectCount,
                        const std::shared_ptr<std::atomic<bool>> &cancel);
    void collectMdFiles(const QString &dirPath, TreeNode *parentNode,
                        const QStringList &patterns, const QStringList &triggers,
                        int depth = 0);
    void collectAllFiles(const QString &dirPath, TreeNode *parentNode,
                         const QStringList &patterns, int depth = 0);

    ConfigManager *m_config;
    ProjectTreeModel *m_model;
    std::shared_ptr<std::atomic<bool>> m_scanCancel;
};
