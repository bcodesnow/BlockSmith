#pragma once

#include <QAbstractListModel>
#include <QJsonArray>
#include <QtQml/qqmlregistration.h>

class Document;
class BlockStore;
class ConfigManager;

struct EditorState {
    int cursorPosition = 0;
    double scrollY = 0.0;
    int selectionStart = -1;
    int selectionEnd = -1;
    int viewMode = 0; // Edit=0, Split=1, Preview=2
};

class TabModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Use via AppController.tabModel")

    Q_PROPERTY(int activeIndex READ activeIndex WRITE setActiveIndex NOTIFY activeIndexChanged)
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(Document* activeDocument READ activeDocument NOTIFY activeDocumentChanged)
    Q_PROPERTY(bool hasModifiedTabs READ hasModifiedTabs NOTIFY modifiedTabsChanged)

public:
    enum Roles {
        FilePathRole = Qt::UserRole + 1,
        FileNameRole,
        FileTypeRole,
        IsModifiedRole,
        IsPinnedRole,
        ViewModeRole,
        IsActiveRole
    };
    Q_ENUM(Roles)

    explicit TabModel(BlockStore *blockStore, ConfigManager *config,
                      QObject *parent = nullptr);
    ~TabModel() override;

    // QAbstractListModel
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    // Properties
    int count() const;
    int activeIndex() const;
    void setActiveIndex(int index);
    Document *activeDocument() const;
    bool hasModifiedTabs() const;

    // Tab operations
    Q_INVOKABLE int openTab(const QString &filePath);
    Q_INVOKABLE void closeTab(int index);
    Q_INVOKABLE void closeOtherTabs(int index);
    Q_INVOKABLE void closeTabsToRight(int index);
    Q_INVOKABLE void closeAllTabs();
    Q_INVOKABLE void closeSavedTabs();
    Q_INVOKABLE void moveTab(int from, int to);
    Q_INVOKABLE void pinTab(int index);
    Q_INVOKABLE void unpinTab(int index);
    Q_INVOKABLE int findTab(const QString &filePath) const;
    Q_INVOKABLE void reopenClosedTab();
    Q_INVOKABLE bool canReopenClosedTab() const;
    Q_INVOKABLE QString tabFilePath(int index) const;
    Q_INVOKABLE Document* tabDocument(int index) const;
    Q_INVOKABLE void forceCloseTab(int index);
    Q_INVOKABLE QStringList dirtyTabPaths() const;
    Q_INVOKABLE void saveAllDirtyTabs();
    Q_INVOKABLE void forceCloseAllDirtyTabs();

    // State management (called from QML before/after tab switch)
    Q_INVOKABLE void saveEditorState(int cursorPos, double scrollY,
                                     int selStart, int selEnd, int viewMode);
    Q_INVOKABLE QVariantMap editorState() const; // returns active tab's state

    // Session save/restore
    QJsonArray saveSession() const;
    void restoreSession(const QJsonArray &tabs, int activeIdx);

signals:
    void activeIndexChanged();
    void activeDocumentChanged();
    void countChanged();
    void modifiedTabsChanged();
    void tabCloseBlocked(int index); // dirty tab — QML shows dialog
    void aboutToSwitchTab(int oldIndex, int newIndex);
    void allDirtyTabsSaved();

private:
    struct Tab {
        Document *document = nullptr;
        EditorState state;
        bool isPinned = false;
    };

    void connectDocument(Document *doc);
    void pushRecentlyClosed(const Tab &tab);
    int normalizeActiveIndex(int closedIndex) const;

    QVector<Tab> m_tabs;
    int m_activeIndex = -1;
    BlockStore *m_blockStore = nullptr;
    ConfigManager *m_configManager = nullptr;

    struct ClosedTab {
        QString filePath;
        EditorState state;
    };
    QVector<ClosedTab> m_recentlyClosed;
};
