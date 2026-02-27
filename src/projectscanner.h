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
    ConfigManager *m_config;
    ProjectTreeModel *m_model;
    std::shared_ptr<std::atomic<bool>> m_scanCancel;
};
