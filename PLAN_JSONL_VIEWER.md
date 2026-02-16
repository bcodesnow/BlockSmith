# Plan: JSONL Viewer

**Date:** 2026-02-16

## Overview

Read-only viewer for `.jsonl` files with field-level filtering. When a `.jsonl` file is opened from the project tree, MainContent swaps out the editor/preview for a dedicated JsonlViewer. Optimized for Claude Code conversation transcripts but works with any JSONL.

---

## Architecture

### Integration Point

When `AppController::openFile()` detects a `.jsonl` extension, it loads via `JsonlStore` instead of `MdDocument`. MainContent checks the file type and shows either the markdown editor or the JSONL viewer — never both.

```
MainContent.qml
├── .md files  → MdEditor / MdPreviewWeb (existing, unchanged)
└── .jsonl files → JsonlViewer (new)
```

No new view mode enum needed. The viewer replaces the content area based on file type.

### New Files

| File | LOC (est.) | Role |
|------|-----------|------|
| `src/jsonlstore.h` | ~60 | Model class header |
| `src/jsonlstore.cpp` | ~250 | Async JSONL loading, filtering, QAbstractListModel |
| `qml/components/JsonlViewer.qml` | ~200 | Main viewer layout: filter bar + list |
| `qml/components/JsonlEntryCard.qml` | ~150 | Collapsed/expanded entry display |

**Total: ~660 LOC across 4 files** — well under limits, follows BlockStore/BlockListPanel pattern.

### Modified Files

| File | Change |
|------|--------|
| `src/appcontroller.h/.cpp` | Add `JsonlStore*` property (+5 lines) |
| `qml/components/MainContent.qml` | Show JsonlViewer when `.jsonl` is open (~20 lines) |
| `CMakeLists.txt` | Add jsonlstore sources + QML files |

---

## Phase 1: JsonlStore (C++ Backend)

### Data Structure

```cpp
struct JsonlEntry {
    int lineNumber;          // 1-based line in file
    QJsonObject data;        // Full parsed JSON
    QString preview;         // First 120 chars of stringified content
    QString role;            // Extracted "role" field (empty if absent)
    bool hasToolUse;         // Has "tool_use" or "tool_calls" key
};
```

### Class Design

```cpp
class JsonlStore : public QAbstractListModel {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Use via AppController")

    Q_PROPERTY(QString filePath READ filePath NOTIFY filePathChanged)
    Q_PROPERTY(int totalCount READ totalCount NOTIFY totalCountChanged)
    Q_PROPERTY(int filteredCount READ filteredCount NOTIFY filteredCountChanged)
    Q_PROPERTY(QStringList availableRoles READ availableRoles NOTIFY availableRolesChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(int loadProgress READ loadProgress NOTIFY loadProgressChanged)

public:
    enum Roles {
        LineNumberRole = Qt::UserRole + 1,
        PreviewRole,
        RoleNameRole,
        HasToolUseRole,
        FullJsonRole,     // JSON.stringify on demand
        IsExpandedRole
    };

    Q_INVOKABLE void load(const QString &filePath);
    Q_INVOKABLE void clear();

    // Filtering
    Q_INVOKABLE void setTextFilter(const QString &text);
    Q_INVOKABLE void setRoleFilter(const QString &role);  // empty = all
    Q_INVOKABLE void setToolUseFilter(bool onlyToolUse);

    // Interaction
    Q_INVOKABLE void toggleExpanded(int index);
    Q_INVOKABLE QString entryJson(int index) const;  // Pretty-printed
    Q_INVOKABLE void copyEntry(int index);

signals:
    void filePathChanged();
    void totalCountChanged();
    void filteredCountChanged();
    void availableRolesChanged();
    void loadingChanged();
    void loadProgressChanged();
    void loadFailed(const QString &error);
    void copied(const QString &preview);
};
```

### Async Loading

First threaded code in BlockSmith. Uses `QThread` + `moveToThread`:

```cpp
void JsonlStore::load(const QString &filePath) {
    m_loading = true;
    emit loadingChanged();

    auto *worker = new JsonlWorker(filePath);
    auto *thread = new QThread();
    worker->moveToThread(thread);

    connect(thread, &QThread::started, worker, &JsonlWorker::process);
    connect(worker, &JsonlWorker::chunkReady, this, &JsonlStore::appendChunk);
    connect(worker, &JsonlWorker::finished, this, &JsonlStore::onLoadFinished);
    connect(worker, &JsonlWorker::finished, thread, &QThread::quit);
    connect(thread, &QThread::finished, worker, &QObject::deleteLater);
    connect(thread, &QThread::finished, thread, &QObject::deleteLater);

    thread->start();
}
```

Worker parses 100 lines per chunk, emits progress. UI stays responsive.

### Filtering

Parse once during loading — extract `role`, `hasToolUse`, `preview` into the struct. Filtering rebuilds `m_filteredIndices` (vector of ints into `m_entries`), same pattern as BlockStore's `m_filteredIds`.

```cpp
void JsonlStore::rebuildFiltered() {
    beginResetModel();
    m_filteredIndices.clear();
    for (int i = 0; i < m_entries.size(); ++i) {
        const auto &e = m_entries[i];
        if (!m_roleFilter.isEmpty() && e.role != m_roleFilter) continue;
        if (m_toolUseOnly && !e.hasToolUse) continue;
        if (!m_textFilter.isEmpty() && !e.preview.contains(m_textFilter, Qt::CaseInsensitive)) continue;
        m_filteredIndices.append(i);
    }
    endResetModel();
    emit filteredCountChanged();
}
```

### Memory Budget

10MB file / 5000 lines: ~50MB peak during parse, ~40MB sustained. Acceptable for desktop. Add console warning if file >100MB.

---

## Phase 2: JsonlViewer (QML)

### Layout

```
┌─────────────────────────────────────────────┐
│ Filter Bar                                  │
│ [🔍 Search...          ] [user|asst|sys] [⚙]│
├─────────────────────────────────────────────┤
│ Entry Cards (ListView, virtualized)         │
│                                             │
│  Ln 1  │ system │ You are a helpful...      │
│  Ln 3  │ user   │ How do I set up...        │
│  Ln 5  │ asst   │ To set up, first... ⚙    │
│  ▼ Ln 7│ user   │ Can you fix...            │
│  ┌──────────────────────────────────┐       │
│  │ {                                │       │
│  │   "role": "user",               │       │
│  │   "content": "Can you fix the..."│       │
│  │ }                                │       │
│  └──────────────────────────────────┘       │
│  Ln 9  │ asst   │ Sure, here's the...  ⚙   │
│                                             │
├─────────────────────────────────────────────┤
│ Status: 5000 entries │ Showing 1234 │ 10.2MB│
└─────────────────────────────────────────────┘
```

### JsonlViewer.qml (~200 LOC)

```qml
Rectangle {
    color: Theme.bg

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Filter bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            color: Theme.bgHeader

            RowLayout {
                anchors.fill: parent
                anchors.margins: Theme.sp8

                // Text search (debounced 200ms)
                TextField { id: searchField; placeholderText: "Search..." }

                // Role pills (from availableRoles)
                Flow {
                    Repeater {
                        model: AppController.jsonlStore.availableRoles
                        delegate: RolePill { /* toggle filter */ }
                    }
                }

                // Tool use toggle
                Rectangle { /* ⚙ toggle button */ }

                // Count label
                Label {
                    text: AppController.jsonlStore.filteredCount + " / " +
                          AppController.jsonlStore.totalCount
                    color: Theme.textMuted
                }
            }
        }

        // Entry list
        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: AppController.jsonlStore
            clip: true
            delegate: JsonlEntryCard {}

            // Loading indicator
            BusyIndicator {
                visible: AppController.jsonlStore.loading
            }
        }
    }
}
```

### JsonlEntryCard.qml (~150 LOC)

Two states: collapsed (1 row) and expanded (+ JSON block).

**Collapsed:**
```
[Ln 42] [user] How do I set up the project?       [⎘]
```

- Line number: `Theme.textMuted`, `Theme.fontMono`
- Role badge: colored pill — user=`Theme.accent`, assistant=`Theme.accentGreen`, system=`Theme.accentGold`
- Content preview: `Theme.textPrimary`, truncated to 1 line
- Tool use indicator: `⚙` badge if present
- Copy button: appears on hover (follows BlockCard pattern)

**Expanded (on click):**
```
[Ln 42] [user] How do I set up the project?       [⎘]
┌─────────────────────────────────────────────────┐
│ {                                               │
│   "role": "user",                               │
│   "content": "How do I set up the project?",    │
│   "timestamp": "2026-02-16T10:30:00Z"           │
│ }                                               │
└─────────────────────────────────────────────────┘
```

- JSON block: `Theme.bgPanel` background, `Theme.fontMono`, read-only TextEdit
- Pretty-printed via `JSON.stringify(data, null, 2)` (called on expand, not precomputed)

### Role Badge Colors

| Role | Color | Token |
|------|-------|-------|
| user | Blue | `Theme.accent` |
| assistant | Green | `Theme.accentGreen` |
| system | Gold | `Theme.accentGold` |
| tool | Muted | `Theme.textMuted` |
| Other/unknown | Default | `Theme.textSecondary` |

---

## Phase 3: MainContent Integration

### File Type Detection

In `MainContent.qml`, add a computed property:

```qml
readonly property bool isJsonlFile:
    AppController.currentDocument.filePath.endsWith(".jsonl")
```

When `isJsonlFile` is true:
- Hide MdEditor, MdPreviewWeb, MdToolbar, FindReplaceBar
- Hide Edit/Split/Preview toggle buttons
- Show JsonlViewer (full width)
- Status bar shows: entry count, file size

When switching back to a `.md` file, JsonlViewer hides and editor returns.

### AppController Changes

```cpp
// openFile() — detect extension
void AppController::openFile(const QString &path) {
    if (path.endsWith(".jsonl", Qt::CaseInsensitive)) {
        m_jsonlStore->load(path);
        // Still set filePath on MdDocument so MainContent can detect the switch
        m_currentDocument->setFilePath(path);  // lightweight, no content load
        return;
    }
    // ... existing markdown loading
}
```

Alternative: add a `Q_PROPERTY(QString currentFileType)` to avoid overloading MdDocument. Cleaner separation.

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Ctrl+F | Focus search field in filter bar |
| Ctrl+C | Copy selected/focused entry |
| Escape | Clear filters, collapse all |
| Up/Down | Navigate entries in list |

---

## Edge Cases

| Scenario | Handling |
|----------|----------|
| Empty file | Show "File is empty" centered label |
| Invalid JSON on a line | Show line with error badge, skip in filters, don't crash |
| Mixed valid/invalid lines | Show valid lines normally, mark invalid with red indicator |
| File >100MB | Log warning, load anyway (chunked loading handles it) |
| Binary/non-text file with .jsonl ext | First-line parse fails → show "Not a valid JSONL file" |
| File changed externally | No watcher (consistent with MdDocument behavior) |
| No role field | Role badge shows "—", entry still visible |

---

## Implementation Order

1. **JsonlStore** (C++ model + async worker) — core data layer
2. **JsonlEntryCard** (QML) — single entry display
3. **JsonlViewer** (QML) — filter bar + ListView
4. **MainContent integration** — file type switching
5. **AppController wiring** — property + openFile routing

---

## What This Does NOT Include

- Editing JSONL (read-only only)
- JSONL creation
- Export/transform
- Syntax highlighting in JSON block (plain mono text, could add later)
- Advanced query language (no JQ-style filters — just text + role + tool_use)

---

## Verification

1. Open a `.jsonl` from the tree → viewer appears, editor hidden
2. Switch to a `.md` file → editor returns, viewer hidden
3. 5000-line file loads with progress indicator, UI stays responsive
4. Role pills filter correctly, text search works
5. Click entry → expands with pretty JSON, click again → collapses
6. Copy button → clipboard + toast
7. Invalid JSON line → shown with error indicator, doesn't break viewer
8. Filter shows count: "Showing 42 / 5000"
