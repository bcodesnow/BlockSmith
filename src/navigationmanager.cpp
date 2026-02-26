#include "navigationmanager.h"

#include "document.h"
#include "jsonlstore.h"
#include "configmanager.h"

#include <QFileInfo>

NavigationManager::NavigationManager(Document *doc, JsonlStore *jsonl,
                                     ConfigManager *config, QObject *parent)
    : QObject(parent)
    , m_document(doc)
    , m_jsonlStore(jsonl)
    , m_configManager(config)
{
}

void NavigationManager::openFile(const QString &path)
{
    if (path == m_document->filePath())
        return;

    if (m_document->modified()) {
        emit unsavedChangesWarning(path);
        return;
    }

    m_pendingNavJump = false;
    m_pendingNavIndex = -1;
    navPush(path);
    openPathNoChecks(path);
    m_configManager->addRecentFile(path);
}

void NavigationManager::forceOpenFile(const QString &path)
{
    bool isPendingNavTarget = false;
    if (m_pendingNavJump
        && m_pendingNavIndex >= 0
        && m_pendingNavIndex < m_navHistory.size()
        && m_navHistory[m_pendingNavIndex] == path) {
        isPendingNavTarget = true;
    }

    if (isPendingNavTarget) {
        m_navigating = true;
        if (m_navIndex != m_pendingNavIndex) {
            m_navIndex = m_pendingNavIndex;
            emit navHistoryChanged();
        }
        openPathNoChecks(path);
        m_navigating = false;
    } else {
        openPathNoChecks(path);
        navPush(path);
    }

    m_pendingNavJump = false;
    m_pendingNavIndex = -1;
    m_configManager->addRecentFile(path);
}

void NavigationManager::openPathNoChecks(const QString &path)
{
    if (path.endsWith(QStringLiteral(".jsonl"), Qt::CaseInsensitive)) {
        m_document->clear();
        m_jsonlStore->load(path);
    } else {
        if (!m_jsonlStore->filePath().isEmpty())
            m_jsonlStore->clear();
        m_document->load(path);
    }
}

// --- Navigation history ---

void NavigationManager::navPush(const QString &path)
{
    if (m_navigating)
        return;

    // Trim forward history when navigating to a new file
    if (m_navIndex + 1 < m_navHistory.size())
        m_navHistory = m_navHistory.mid(0, m_navIndex + 1);

    // Don't push duplicates at the top
    if (!m_navHistory.isEmpty() && m_navHistory.last() == path)
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

    const int targetIndex = m_navIndex - 1;
    const QString path = m_navHistory[targetIndex];

    if (m_document->modified()) {
        m_pendingNavJump = true;
        m_pendingNavIndex = targetIndex;
        emit unsavedChangesWarning(path);
        return;
    }

    m_pendingNavJump = false;
    m_pendingNavIndex = -1;
    m_navigating = true;
    m_navIndex = targetIndex;
    emit navHistoryChanged();

    openPathNoChecks(path);
    m_navigating = false;
}

void NavigationManager::goForward()
{
    if (!canGoForward())
        return;

    const int targetIndex = m_navIndex + 1;
    const QString path = m_navHistory[targetIndex];

    if (m_document->modified()) {
        m_pendingNavJump = true;
        m_pendingNavIndex = targetIndex;
        emit unsavedChangesWarning(path);
        return;
    }

    m_pendingNavJump = false;
    m_pendingNavIndex = -1;
    m_navigating = true;
    m_navIndex = targetIndex;
    emit navHistoryChanged();

    openPathNoChecks(path);
    m_navigating = false;
}
