#pragma once

#include <QObject>
#include <QStringList>

class Document;
class JsonlStore;
class ConfigManager;

class NavigationManager : public QObject
{
    Q_OBJECT

public:
    explicit NavigationManager(Document *doc, JsonlStore *jsonl,
                               ConfigManager *config, QObject *parent = nullptr);

    void openFile(const QString &path);
    void forceOpenFile(const QString &path);
    void goBack();
    void goForward();
    bool canGoBack() const;
    bool canGoForward() const;

signals:
    void unsavedChangesWarning(const QString &pendingPath);
    void navHistoryChanged();

private:
    void navPush(const QString &path);
    void openPathNoChecks(const QString &path);

    Document *m_document;
    JsonlStore *m_jsonlStore;
    ConfigManager *m_configManager;

    QStringList m_navHistory;
    int m_navIndex = -1;
    bool m_navigating = false;
    bool m_pendingNavJump = false;
    int m_pendingNavIndex = -1;
};
