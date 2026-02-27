#include "navigationmanager.h"
#include "utils.h"

NavigationManager::NavigationManager(QObject *parent)
    : QObject(parent)
{
}

void NavigationManager::navPushPublic(const QString &path)
{
    if (m_navigating)
        return;

    // Trim forward history when navigating to a new file
    if (m_navIndex + 1 < m_navHistory.size())
        m_navHistory = m_navHistory.mid(0, m_navIndex + 1);

    // Don't push duplicates at the top (case-insensitive on Windows)
    if (!m_navHistory.isEmpty() && Utils::samePath(m_navHistory.last(), path))
        return;

    m_navHistory.append(path);

    // Cap history at 50 entries
    if (m_navHistory.size() > 50)
        m_navHistory.removeFirst();

    m_navIndex = m_navHistory.size() - 1;
    emit navHistoryChanged();
}

bool NavigationManager::canGoBack() const
{
    return m_navIndex > 0;
}

bool NavigationManager::canGoForward() const
{
    return m_navIndex >= 0 && m_navIndex < m_navHistory.size() - 1;
}

void NavigationManager::goBack()
{
    if (!canGoBack())
        return;

    m_navigating = true;
    m_navIndex--;
    emit navHistoryChanged();
    emit navigateToPath(m_navHistory[m_navIndex]);
    m_navigating = false;
}

void NavigationManager::goForward()
{
    if (!canGoForward())
        return;

    m_navigating = true;
    m_navIndex++;
    emit navHistoryChanged();
    emit navigateToPath(m_navHistory[m_navIndex]);
    m_navigating = false;
}
