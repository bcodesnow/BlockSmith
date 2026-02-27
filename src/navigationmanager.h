#pragma once

#include <QObject>
#include <QStringList>

class NavigationManager : public QObject
{
    Q_OBJECT

public:
    explicit NavigationManager(QObject *parent = nullptr);

    void goBack();
    void goForward();
    bool canGoBack() const;
    bool canGoForward() const;

    void navPushPublic(const QString &path);

signals:
    void navHistoryChanged();
    void navigateToPath(const QString &path);

private:
    QStringList m_navHistory;
    int m_navIndex = -1;
    bool m_navigating = false;
};
