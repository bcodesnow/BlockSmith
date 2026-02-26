#pragma once

#include <QObject>
#include <QVariantList>
#include <QStringList>
#include <atomic>
#include <memory>

class ProjectTreeModel;
class ConfigManager;

class SearchManager : public QObject
{
    Q_OBJECT

public:
    explicit SearchManager(ProjectTreeModel *tree, ConfigManager *config,
                           QObject *parent = nullptr);

    QStringList getAllFiles() const;
    QVariantList fuzzyFilterFiles(const QString &query) const;
    void searchFiles(const QString &query);

signals:
    void searchResultsReady(const QVariantList &results);

private:
    ProjectTreeModel *m_projectTreeModel;
    ConfigManager *m_configManager;
    std::shared_ptr<std::atomic<bool>> m_searchCancel;
};
