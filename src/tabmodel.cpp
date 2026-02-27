#include "tabmodel.h"
#include "document.h"
#include "blockstore.h"
#include "configmanager.h"
#include "utils.h"

#include <QDir>
#include <QFileInfo>
#include <QJsonObject>

using Utils::samePath;

TabModel::TabModel(BlockStore *blockStore, ConfigManager *config, QObject *parent)
    : QAbstractListModel(parent)
    , m_blockStore(blockStore)
    , m_configManager(config)
{
}

TabModel::~TabModel()
{
    // Documents are parented to us, so they'll be deleted automatically
}

// --- QAbstractListModel ---

int TabModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_tabs.size();
}

QVariant TabModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_tabs.size())
        return {};

    const Tab &tab = m_tabs[index.row()];
    switch (role) {
    case FilePathRole:
        return tab.document->filePath();
    case FileNameRole:
        return QFileInfo(tab.document->filePath()).fileName();
    case FileTypeRole:
        return static_cast<int>(tab.document->fileType());
    case IsModifiedRole:
        return tab.document->modified();
    case IsPinnedRole:
        return tab.isPinned;
    case ViewModeRole:
        return tab.state.viewMode;
    case IsActiveRole:
        return index.row() == m_activeIndex;
    default:
        return {};
    }
}

QHash<int, QByteArray> TabModel::roleNames() const
{
    return {
        { FilePathRole,   "filePath" },
        { FileNameRole,   "fileName" },
        { FileTypeRole,   "fileType" },
        { IsModifiedRole, "isModified" },
        { IsPinnedRole,   "isPinned" },
        { ViewModeRole,   "viewMode" },
        { IsActiveRole,   "isActive" }
    };
}

// --- Properties ---

int TabModel::count() const { return m_tabs.size(); }

int TabModel::activeIndex() const { return m_activeIndex; }

void TabModel::setActiveIndex(int index)
{
    if (index < -1 || index >= m_tabs.size())
        return;
    if (index == m_activeIndex)
        return;

    int oldIndex = m_activeIndex;
    emit aboutToSwitchTab(oldIndex, index);

    // Update isActive role for old and new
    m_activeIndex = index;

    if (oldIndex >= 0 && oldIndex < m_tabs.size()) {
        QModelIndex mi = createIndex(oldIndex, 0);
        emit dataChanged(mi, mi, { IsActiveRole });
    }
    if (index >= 0) {
        QModelIndex mi = createIndex(index, 0);
        emit dataChanged(mi, mi, { IsActiveRole });
    }

    emit activeIndexChanged();
    emit activeDocumentChanged();
}

Document *TabModel::activeDocument() const
{
    if (m_activeIndex < 0 || m_activeIndex >= m_tabs.size())
        return nullptr;
    return m_tabs[m_activeIndex].document;
}

bool TabModel::hasModifiedTabs() const
{
    for (const auto &tab : m_tabs) {
        if (tab.document->modified())
            return true;
    }
    return false;
}

// --- Tab operations ---

int TabModel::openTab(const QString &filePath)
{
    // Check if already open
    int existing = findTab(filePath);
    if (existing >= 0) {
        setActiveIndex(existing);
        return existing;
    }

    // Create new Document
    auto *doc = new Document(this);
    doc->setBlockStore(m_blockStore);

    // Apply auto-save settings
    if (m_configManager)
        doc->setAutoSave(m_configManager->autoSaveEnabled(),
                         m_configManager->autoSaveInterval());

    doc->load(filePath);
    connectDocument(doc);

    Tab tab;
    tab.document = doc;

    int insertIdx = m_tabs.size();
    beginInsertRows(QModelIndex(), insertIdx, insertIdx);
    m_tabs.append(tab);
    endInsertRows();

    emit countChanged();
    setActiveIndex(insertIdx);

    if (m_configManager)
        m_configManager->addRecentFile(filePath);

    return insertIdx;
}

void TabModel::closeTab(int index)
{
    if (index < 0 || index >= m_tabs.size())
        return;

    Tab &tab = m_tabs[index];

    // Block close if dirty — let QML handle the dialog
    if (tab.document->modified()) {
        emit tabCloseBlocked(index);
        return;
    }

    pushRecentlyClosed(tab);

    beginRemoveRows(QModelIndex(), index, index);
    delete tab.document;
    m_tabs.remove(index);
    endRemoveRows();

    // Adjust active index
    int newActive = normalizeActiveIndex(index);
    m_activeIndex = -1; // force re-emit
    emit countChanged();
    emit modifiedTabsChanged();

    if (newActive >= 0)
        setActiveIndex(newActive);
    else {
        emit activeIndexChanged();
        emit activeDocumentChanged();
    }
}

void TabModel::closeOtherTabs(int index)
{
    if (index < 0 || index >= m_tabs.size())
        return;

    // First pass: bail out if any candidate is dirty (no tabs closed yet)
    for (int i = m_tabs.size() - 1; i >= 0; --i) {
        if (i == index || m_tabs[i].isPinned)
            continue;
        if (m_tabs[i].document->modified()) {
            emit tabCloseBlocked(i);
            return;
        }
    }

    // Second pass: all candidates are clean, close them
    for (int i = m_tabs.size() - 1; i >= 0; --i) {
        if (i == index || m_tabs[i].isPinned)
            continue;
        pushRecentlyClosed(m_tabs[i]);
        beginRemoveRows(QModelIndex(), i, i);
        delete m_tabs[i].document;
        m_tabs.remove(i);
        endRemoveRows();
        if (i < index) index--;
    }

    m_activeIndex = -1;
    emit countChanged();
    emit modifiedTabsChanged();
    setActiveIndex(index >= 0 && index < m_tabs.size() ? index : m_tabs.size() - 1);
}

void TabModel::closeTabsToRight(int index)
{
    if (index < 0 || index >= m_tabs.size() - 1)
        return;

    // First pass: bail if any candidate is dirty (no tabs closed yet)
    for (int i = m_tabs.size() - 1; i > index; --i) {
        if (m_tabs[i].isPinned)
            continue;
        if (m_tabs[i].document->modified()) {
            emit tabCloseBlocked(i);
            return;
        }
    }

    // Second pass: all candidates are clean, close them
    for (int i = m_tabs.size() - 1; i > index; --i) {
        if (m_tabs[i].isPinned)
            continue;
        pushRecentlyClosed(m_tabs[i]);
        beginRemoveRows(QModelIndex(), i, i);
        delete m_tabs[i].document;
        m_tabs.remove(i);
        endRemoveRows();
    }

    m_activeIndex = -1;
    emit countChanged();
    emit modifiedTabsChanged();
    setActiveIndex(qMin(index, m_tabs.size() - 1));
}

void TabModel::closeAllTabs()
{
    // First pass: bail if any non-pinned tab is dirty (no tabs closed yet)
    for (int i = m_tabs.size() - 1; i >= 0; --i) {
        if (m_tabs[i].isPinned)
            continue;
        if (m_tabs[i].document->modified()) {
            emit tabCloseBlocked(i);
            return;
        }
    }

    // Second pass: all candidates are clean, close them
    for (int i = m_tabs.size() - 1; i >= 0; --i) {
        if (m_tabs[i].isPinned)
            continue;
        pushRecentlyClosed(m_tabs[i]);
        beginRemoveRows(QModelIndex(), i, i);
        delete m_tabs[i].document;
        m_tabs.remove(i);
        endRemoveRows();
    }

    m_activeIndex = -1;
    emit countChanged();
    emit modifiedTabsChanged();

    if (!m_tabs.isEmpty())
        setActiveIndex(0);
    else {
        emit activeIndexChanged();
        emit activeDocumentChanged();
    }
}

void TabModel::closeSavedTabs()
{
    int target = m_activeIndex;

    for (int i = m_tabs.size() - 1; i >= 0; --i) {
        if (m_tabs[i].isPinned || m_tabs[i].document->modified())
            continue;
        if (i < target)
            target--;
        pushRecentlyClosed(m_tabs[i]);
        beginRemoveRows(QModelIndex(), i, i);
        delete m_tabs[i].document;
        m_tabs.remove(i);
        endRemoveRows();
    }

    m_activeIndex = -1;
    emit countChanged();
    emit modifiedTabsChanged();

    if (!m_tabs.isEmpty()) {
        target = qMax(0, qMin(target, m_tabs.size() - 1));
        setActiveIndex(target);
    } else {
        emit activeIndexChanged();
        emit activeDocumentChanged();
    }
}

void TabModel::moveTab(int from, int to)
{
    if (from < 0 || from >= m_tabs.size() || to < 0 || to >= m_tabs.size() || from == to)
        return;

    // Adjust for Qt's move semantics
    int dest = to > from ? to + 1 : to;
    beginMoveRows(QModelIndex(), from, from, QModelIndex(), dest);

    Tab tab = m_tabs[from];
    m_tabs.remove(from);
    m_tabs.insert(to, tab);

    endMoveRows();

    // Update active index to follow the moved tab
    if (m_activeIndex == from) {
        m_activeIndex = to;
        emit activeIndexChanged();
    } else if (from < m_activeIndex && to >= m_activeIndex) {
        m_activeIndex--;
        emit activeIndexChanged();
    } else if (from > m_activeIndex && to <= m_activeIndex) {
        m_activeIndex++;
        emit activeIndexChanged();
    }
}

void TabModel::pinTab(int index)
{
    if (index < 0 || index >= m_tabs.size() || m_tabs[index].isPinned)
        return;

    m_tabs[index].isPinned = true;
    QModelIndex mi = createIndex(index, 0);
    emit dataChanged(mi, mi, { IsPinnedRole });

    // Move to end of pinned section
    int pinnedEnd = 0;
    for (int i = 0; i < m_tabs.size(); ++i) {
        if (m_tabs[i].isPinned && i != index)
            pinnedEnd = i + 1;
    }
    if (index != pinnedEnd)
        moveTab(index, pinnedEnd);
}

void TabModel::unpinTab(int index)
{
    if (index < 0 || index >= m_tabs.size() || !m_tabs[index].isPinned)
        return;

    m_tabs[index].isPinned = false;
    QModelIndex mi = createIndex(index, 0);
    emit dataChanged(mi, mi, { IsPinnedRole });
}

int TabModel::findTab(const QString &filePath) const
{
    for (int i = 0; i < m_tabs.size(); ++i) {
        if (samePath(m_tabs[i].document->filePath(), filePath))
            return i;
    }
    return -1;
}

void TabModel::reopenClosedTab()
{
    if (m_recentlyClosed.isEmpty())
        return;

    ClosedTab closed = m_recentlyClosed.takeLast();

    // Don't reopen if already open
    if (findTab(closed.filePath) >= 0) {
        setActiveIndex(findTab(closed.filePath));
        return;
    }

    // Check file still exists
    if (!QFileInfo::exists(closed.filePath))
        return;

    int idx = openTab(closed.filePath);
    if (idx >= 0 && idx < m_tabs.size())
        m_tabs[idx].state = closed.state;
}

bool TabModel::canReopenClosedTab() const
{
    return !m_recentlyClosed.isEmpty();
}

QString TabModel::tabFilePath(int index) const
{
    if (index < 0 || index >= m_tabs.size())
        return {};
    return m_tabs[index].document->filePath();
}

Document *TabModel::tabDocument(int index) const
{
    if (index < 0 || index >= m_tabs.size())
        return nullptr;
    return m_tabs[index].document;
}

void TabModel::forceCloseTab(int index)
{
    if (index < 0 || index >= m_tabs.size())
        return;

    pushRecentlyClosed(m_tabs[index]);

    beginRemoveRows(QModelIndex(), index, index);
    delete m_tabs[index].document;
    m_tabs.remove(index);
    endRemoveRows();

    int newActive = normalizeActiveIndex(index);
    m_activeIndex = -1; // force re-emit
    emit countChanged();
    emit modifiedTabsChanged();

    if (newActive >= 0)
        setActiveIndex(newActive);
    else {
        emit activeIndexChanged();
        emit activeDocumentChanged();
    }
}

QStringList TabModel::dirtyTabPaths() const
{
    QStringList paths;
    for (const auto &tab : m_tabs) {
        if (tab.document->modified())
            paths.append(tab.document->filePath());
    }
    return paths;
}

void TabModel::saveAllDirtyTabs()
{
    for (auto &tab : m_tabs) {
        if (tab.document->modified())
            tab.document->save();
    }
    if (!hasModifiedTabs())
        emit allDirtyTabsSaved();
}

void TabModel::forceCloseAllDirtyTabs()
{
    for (int i = m_tabs.size() - 1; i >= 0; --i) {
        if (m_tabs[i].document->modified() && !m_tabs[i].isPinned)
            forceCloseTab(i);
    }
}

// --- State management ---

void TabModel::saveEditorState(int cursorPos, double scrollY,
                               int selStart, int selEnd, int viewMode)
{
    if (m_activeIndex < 0 || m_activeIndex >= m_tabs.size())
        return;

    EditorState &s = m_tabs[m_activeIndex].state;
    s.cursorPosition = cursorPos;
    s.scrollY = scrollY;
    s.selectionStart = selStart;
    s.selectionEnd = selEnd;
    s.viewMode = viewMode;
}

QVariantMap TabModel::editorState() const
{
    QVariantMap map;
    if (m_activeIndex < 0 || m_activeIndex >= m_tabs.size())
        return map;

    const EditorState &s = m_tabs[m_activeIndex].state;
    map[QStringLiteral("cursorPosition")] = s.cursorPosition;
    map[QStringLiteral("scrollY")] = s.scrollY;
    map[QStringLiteral("selectionStart")] = s.selectionStart;
    map[QStringLiteral("selectionEnd")] = s.selectionEnd;
    map[QStringLiteral("viewMode")] = s.viewMode;
    return map;
}

// --- Session ---

QJsonArray TabModel::saveSession() const
{
    QJsonArray arr;
    for (const auto &tab : m_tabs) {
        QJsonObject obj;
        obj[QStringLiteral("path")] = tab.document->filePath();
        obj[QStringLiteral("viewMode")] = tab.state.viewMode;
        obj[QStringLiteral("cursorPosition")] = tab.state.cursorPosition;
        obj[QStringLiteral("scrollY")] = tab.state.scrollY;
        obj[QStringLiteral("isPinned")] = tab.isPinned;
        arr.append(obj);
    }
    return arr;
}

void TabModel::restoreSession(const QJsonArray &tabs, int activeIdx)
{
    for (const auto &val : tabs) {
        QJsonObject obj = val.toObject();
        QString path = obj[QStringLiteral("path")].toString();
        if (path.isEmpty() || !QFileInfo::exists(path))
            continue;

        int idx = openTab(path);
        if (idx < 0 || idx >= m_tabs.size())
            continue;

        Tab &tab = m_tabs[idx];
        tab.state.viewMode = obj[QStringLiteral("viewMode")].toInt(0);
        tab.state.cursorPosition = obj[QStringLiteral("cursorPosition")].toInt(0);
        tab.state.scrollY = obj[QStringLiteral("scrollY")].toDouble(0.0);
        tab.isPinned = obj[QStringLiteral("isPinned")].toBool(false);

        QModelIndex mi = createIndex(idx, 0);
        emit dataChanged(mi, mi, { IsPinnedRole, ViewModeRole });
    }

    if (activeIdx >= 0 && activeIdx < m_tabs.size())
        setActiveIndex(activeIdx);
    else if (!m_tabs.isEmpty())
        setActiveIndex(m_tabs.size() - 1);
}

// --- Private ---

void TabModel::connectDocument(Document *doc)
{
    connect(doc, &Document::modifiedChanged, this, [this, doc]() {
        for (int i = 0; i < m_tabs.size(); ++i) {
            if (m_tabs[i].document == doc) {
                QModelIndex mi = createIndex(i, 0);
                emit dataChanged(mi, mi, { IsModifiedRole });
                emit modifiedTabsChanged();
                return;
            }
        }
    });

    connect(doc, &Document::filePathChanged, this, [this, doc]() {
        for (int i = 0; i < m_tabs.size(); ++i) {
            if (m_tabs[i].document == doc) {
                QModelIndex mi = createIndex(i, 0);
                emit dataChanged(mi, mi, { FilePathRole, FileNameRole, FileTypeRole });
                return;
            }
        }
    });
}

void TabModel::pushRecentlyClosed(const Tab &tab)
{
    ClosedTab closed;
    closed.filePath = tab.document->filePath();
    closed.state = tab.state;
    m_recentlyClosed.append(closed);
    if (m_recentlyClosed.size() > 20)
        m_recentlyClosed.removeFirst();
}

int TabModel::normalizeActiveIndex(int closedIndex) const
{
    if (m_tabs.isEmpty())
        return -1;

    // Prefer the tab that was to the right (now at closedIndex)
    if (closedIndex < m_tabs.size())
        return closedIndex;

    // Fall back to the last tab
    return m_tabs.size() - 1;
}
