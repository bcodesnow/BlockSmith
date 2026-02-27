# Phase 13: Multi-Tab Editor — Implementation Plan

## Overview

Replace the single-document model with a tabbed editor. Each tab owns its own Document instance and editor state (cursor, scroll, undo, view mode). A single Editor component swaps its backing document on tab switch — no per-tab Editor duplication.

---

## Architecture

### Current Model (Single Document)

```
AppController (singleton)
  └─ m_currentDocument (Document*)      ← one file at a time
  └─ m_navigationManager                ← linear history
  └─ m_jsonlStore                       ← replaces editor for .jsonl

MainContent.qml
  └─ Editor.qml → binds to AppController.currentDocument
  └─ viewMode (global Edit/Split/Preview)
```

### Target Model (Multi-Tab)

```
AppController (singleton)
  └─ m_tabModel (TabModel*)             ← list of open tabs
  └─ m_navigationManager                ← now tab-aware
  └─ m_jsonlStore                       ← per-tab for .jsonl

TabModel : QAbstractListModel
  └─ Tab { document*, editorState, viewMode, isPinned }
  └─ activeIndex
  └─ recentlyClosedStack

MainContent.qml
  └─ TabBar.qml → reads from TabModel
  └─ Editor.qml → binds to TabModel.activeDocument
  └─ viewMode per-tab (from TabModel.activeTab.viewMode)
```

### Design Principle: Single Editor, Swapped Documents

Only one `Editor.qml` instance exists. On tab switch:
1. Save current cursor position, scroll offset, selection to outgoing tab's `EditorState`
2. Swap `Editor.textArea.textDocument` to incoming tab's `Document`
3. Restore cursor, scroll, selection from incoming tab's `EditorState`

This matches VS Code's model — memory-efficient, scales to 50+ tabs.

---

## Phase 13.1 — Tab Bar & Core Infrastructure

### New C++ Class: TabModel

**Files:** `src/tabmodel.h`, `src/tabmodel.cpp` (~200 LOC)

```cpp
struct EditorState {
    int cursorPosition = 0;
    double scrollY = 0.0;
    int selectionStart = -1;
    int selectionEnd = -1;
    int viewMode = 0;           // Edit=0, Split=1, Preview=2
};

class TabModel : public QAbstractListModel {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(int activeIndex READ activeIndex WRITE setActiveIndex NOTIFY activeIndexChanged)
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(Document* activeDocument READ activeDocument NOTIFY activeDocumentChanged)

public:
    enum Roles {
        FilePathRole = Qt::UserRole + 1,
        FileNameRole,
        FileTypeRole,
        IsModifiedRole,
        IsPinnedRole,
        ViewModeRole
    };

    // Tab operations
    Q_INVOKABLE int openTab(const QString &filePath);  // returns tab index
    Q_INVOKABLE void closeTab(int index);
    Q_INVOKABLE void closeOtherTabs(int index);
    Q_INVOKABLE void closeTabsToRight(int index);
    Q_INVOKABLE void closeAllTabs();
    Q_INVOKABLE void closeSavedTabs();
    Q_INVOKABLE void moveTab(int from, int to);
    Q_INVOKABLE void pinTab(int index);
    Q_INVOKABLE void unpinTab(int index);
    Q_INVOKABLE int findTab(const QString &filePath);  // -1 if not open
    Q_INVOKABLE void reopenClosedTab();

    // State management
    void saveEditorState(int index, const EditorState &state);
    EditorState editorState(int index) const;

signals:
    void activeIndexChanged();
    void activeDocumentChanged();
    void countChanged();
    void tabCloseRequested(int index);        // for dirty-file prompt
    void allTabsCloseRequested(QStringList dirtyPaths);  // for batch save dialog
};
```

**Roles for QML:**
| Role | Type | Description |
|------|------|-------------|
| `filePath` | string | Full path |
| `fileName` | string | Basename only |
| `fileType` | int | Document::FileType enum |
| `isModified` | bool | Unsaved changes |
| `isPinned` | bool | Pinned state |
| `viewMode` | int | Edit/Split/Preview |

**Internal storage:**
```cpp
struct Tab {
    Document *document;
    EditorState editorState;
    bool isPinned = false;
};
QVector<Tab> m_tabs;
int m_activeIndex = -1;
QVector<QPair<QString, EditorState>> m_recentlyClosed;  // stack, max 20
```

### Tab Lifecycle

**Opening a tab:**
1. Check if file already open → `findTab(path)` → switch to it if found
2. Create new `Document` instance, parent to TabModel
3. Call `document->load(filePath)`
4. Append to `m_tabs`, emit `rowsInserted`
5. Set as active tab

**Closing a tab:**
1. Check if modified → emit `tabCloseRequested(index)` for QML to show dialog
2. If confirmed: push to `m_recentlyClosed` stack
3. Delete `Document`, remove from `m_tabs`
4. Adjust `m_activeIndex` (prefer right neighbor, fall back to left)
5. If no tabs remain → emit `countChanged()` → show welcome view

**Switching tabs:**
1. Save outgoing tab's EditorState (cursor, scroll, selection, viewMode)
2. Set `m_activeIndex` to new index
3. Emit `activeDocumentChanged()` → Editor rebinds
4. QML restores EditorState from incoming tab

### New QML Component: TabBar.qml

**File:** `qml/components/TabBar.qml` (~150 LOC)

**Structure:**
```
Rectangle (tab bar background, slightly darker than editor bg)
├─ ListView (horizontal, clip: true)
│   ├─ delegate: TabButton
│   │   ├─ FileTypeIcon (16x16, left)
│   │   ├─ Label (filename, center, elide right)
│   │   ├─ ModifiedDot / CloseButton (right, swap on hover)
│   │   └─ MouseArea (click=switch, middle=close, right=context menu)
│   └─ DragHandler (reorder within bar)
├─ ScrollLeftButton (visible when overflow)
├─ ScrollRightButton (visible when overflow)
└─ TabListDropdown (overflow menu listing all tabs)
```

**Tab sizing:**
- Variable width, min 80px, max 220px
- Shrink toward min before activating overflow scroll

**Tab styling:**

| Property | Active | Inactive | Hovered |
|----------|--------|----------|---------|
| Background | `Theme.bg` | `Theme.bgDarker` | `Theme.bgHover` |
| Text color | `Theme.textPrimary` | `Theme.textMuted` | `Theme.textSecondary` |
| Bottom border | 2px `Theme.accent` | none | none |
| Close button | Always visible | Hidden | Visible |
| Modified dot | Left of close btn | Replaces close btn | Hidden (close btn shows) |

**Context menu (right-click):**

| Action | Shortcut |
|--------|----------|
| Close | Ctrl+W |
| Close Others | — |
| Close to the Right | — |
| Close All | — |
| Close Saved | — |
| ── separator ── | |
| Copy File Path | — |
| Reveal in Explorer | — |
| ── separator ── | |
| Pin / Unpin Tab | — |

**Overflow behavior:**
1. Tabs compress toward 80px minimum width
2. Scroll arrows appear at edges when tabs overflow
3. Mouse wheel scrolls tab bar horizontally
4. "..." dropdown button lists all tabs (active tab highlighted)

**Drag reorder:**
- `DragHandler` on each tab delegate
- Visual drop indicator (vertical line) between tabs
- On drop: call `TabModel.moveTab(from, to)`
- Pinned tabs stay left, cannot be dragged past pinned boundary

### Keyboard Shortcuts

| Action | Shortcut | Notes |
|--------|----------|-------|
| Next tab | Ctrl+Tab | Linear order (left → right) |
| Previous tab | Ctrl+Shift+Tab | Linear order (right → left) |
| Close tab | Ctrl+W | Prompt if dirty |
| Reopen closed tab | Ctrl+Shift+T | From recently-closed stack |
| Go to tab 1-8 | Ctrl+1 through Ctrl+8 | Positional |
| Go to last tab | Ctrl+9 | Always last tab |

**Note:** Ctrl+W currently calls `Document.clear()`. This will be repurposed to close the active tab. Ctrl+N (new untitled file) can be added later.

**Shortcut conflict check:** Ctrl+1-9 are currently unused. Ctrl+Tab/Ctrl+Shift+Tab are unused. Ctrl+Shift+T is unused. No conflicts.

---

## Phase 13.2 — State Management

### Per-Tab State

Each tab independently tracks:

| State | Stored in | Persisted to session? |
|-------|-----------|----------------------|
| File path | `Document.filePath` | Yes |
| File content | `Document.rawContent` | No (reloaded from disk) |
| Modified flag | `Document.modified` | No |
| Cursor position | `EditorState.cursorPosition` | Yes |
| Scroll Y | `EditorState.scrollY` | Yes |
| Selection | `EditorState.selectionStart/End` | No |
| Undo/redo stack | `QTextDocument` (implicit) | No |
| View mode | `EditorState.viewMode` | Yes |
| File watcher | `Document.m_watcher` | No (recreated) |
| Auto-save timer | `Document.m_autoSaveTimer` | No (recreated) |
| Syntax mode | `Document.syntaxMode` | No (derived from extension) |
| Pinned | `Tab.isPinned` | Yes |

### Tab Switch Flow (Detailed)

```
User clicks tab[2]:

1. QML TabBar → TabModel.setActiveIndex(2)

2. TabModel (C++):
   a. Emit aboutToSwitchTab(oldIndex)
   b. [QML catches signal, reads Editor state]:
      - editorState.cursorPosition = editor.textArea.cursorPosition
      - editorState.scrollY = editor.scrollFlickable.contentY
      - editorState.selectionStart = editor.textArea.selectionStart
      - editorState.selectionEnd = editor.textArea.selectionEnd
      - editorState.viewMode = mainContent.viewMode
      - TabModel.saveEditorState(oldIndex, state)
   c. Set m_activeIndex = 2
   d. Emit activeDocumentChanged()

3. QML MainContent:
   a. Editor.text rebinds to new Document.rawContent
   b. SyntaxHighlighter.mode updates from new Document.syntaxMode
   c. Toolbar switches based on new Document.toolbarKind
   d. viewMode restores from TabModel.activeTab.viewMode
   e. [QML restores EditorState]:
      - editor.textArea.cursorPosition = state.cursorPosition
      - editor.scrollFlickable.contentY = state.scrollY
      - (selection restored if stored)

4. Special viewers:
   - If new tab is .jsonl → show JsonlViewer, hide Editor
   - If new tab is .pdf → show PdfViewer, hide Editor
   - If new tab is .docx → show DocxViewer, hide Editor
```

### Document Instance Lifecycle

- **Creation:** On `openTab()`, `new Document(tabModel)` — parented to TabModel for cleanup
- **Loading:** Immediate for active tab; lazy for session-restored background tabs
- **File watching:** Each Document has its own `QFileSystemWatcher` — works independently
- **Auto-save:** Each Document has its own timer — ConfigManager settings apply globally
- **Destruction:** On `closeTab()`, `delete document` — QObject parent cleanup handles children
- **Memory:** ~100KB per typical document. 50 tabs ≈ 5MB — negligible

### Dirty File Handling

**Closing one dirty tab:**
```
Dialog: "Do you want to save changes to {filename}?"
Buttons: [Save] [Don't Save] [Cancel]
```

**Closing multiple dirty tabs (Close All / quit app):**
```
Dialog: "The following files have unsaved changes:"
  ☑ README.md
  ☑ config.json
  ☐ notes.txt
Buttons: [Save Selected] [Don't Save] [Cancel]
```

**Pinned tabs:** "Close All" and "Close Others" skip pinned tabs. Explicit close via context menu or middle-click still works on pinned tabs (with dirty prompt).

### Integration with Existing Systems

**NavigationManager:**
- Back/forward history becomes per-session (across all tabs)
- History entries include tab reference: navigating back may switch tabs
- `openFile()` now calls `TabModel.openTab()` instead of replacing Document

**SyncEngine:**
- Block index rebuilds when any tab saves (debounced — 500ms timer)
- Global block registry unchanged
- `pushBlock()` affects all files, may update content in multiple open tabs

**FileManager:**
- `renameItem()` → iterate all tabs, update any matching Document paths
- `deleteItem()` → close any tab with matching path
- `moveItem()` → same as rename, update paths

**Quick Switcher (Ctrl+P):**
- If file is already open in a tab → switch to that tab
- If not open → `openTab(path)` creates new tab

**Project tree click:**
- Same behavior as Quick Switcher: switch to existing tab or open new

---

## Phase 13.3 — Session Restore & Polish

### Session Persistence

**File:** `AppData/Local/BlockSmith/session.json` (separate from config.json)

```json
{
  "tabs": [
    {
      "path": "C:/projects/foo/README.md",
      "viewMode": 1,
      "cursorPosition": 245,
      "scrollY": 120.5,
      "isPinned": true
    },
    {
      "path": "C:/projects/foo/config.json",
      "viewMode": 0,
      "cursorPosition": 0,
      "scrollY": 0.0,
      "isPinned": false
    }
  ],
  "activeIndex": 0
}
```

**Save:** On app close (`Main.qml onClosing`), TabModel serializes all tabs
**Restore:** On startup (after splash), TabModel deserializes and opens tabs
**Lazy loading:** Restore all tab metadata immediately (tab bar populated), load file content only for the active tab. Background tabs load on first activation.
**Missing files:** If a restored file no longer exists, show tab with "(deleted)" label and error state in content area. User can close it.

### Welcome View

When `TabModel.count === 0`, show a simple welcome view:

```
┌─────────────────────────────────┐
│                                 │
│       Select a file from        │
│       the project tree          │
│                                 │
│       Recent Files:             │
│       · README.md               │
│       · CLAUDE.md               │
│       · config.json             │
│                                 │
│       Ctrl+P  Quick Switcher    │
│       Ctrl+O  Open File         │
│                                 │
└─────────────────────────────────┘
```

### Recently Closed Tabs

- Stack of last 20 closed tabs (path + EditorState)
- `Ctrl+Shift+T` reopens most recent
- If file already open in another tab → switch to it instead of duplicate
- Stack clears on app exit (session-only convenience, not persisted)

---

## File Changes Summary

| File | Change | LOC |
|------|--------|-----|
| `src/tabmodel.h` | **New** — TabModel class + EditorState struct | ~80 |
| `src/tabmodel.cpp` | **New** — Tab lifecycle, model roles, session save/restore | ~200 |
| `src/appcontroller.h` | Replace `m_currentDocument` with `m_tabModel`, expose TabModel | ~20 |
| `src/appcontroller.cpp` | Rewire openFile/scan/nav to go through TabModel | ~60 |
| `src/navigationmanager.h/.cpp` | openFile calls TabModel.openTab, history entries tab-aware | ~30 |
| `src/filemanager.cpp` | Iterate tabs on rename/delete/move | ~20 |
| `src/syncengine.cpp` | Debounce rebuild on any-tab-save | ~10 |
| `qml/components/TabBar.qml` | **New** — Tab bar UI with overflow, drag, context menu | ~150 |
| `qml/components/MainContent.qml` | Add TabBar, bind to activeDocument, per-tab viewMode | ~40 |
| `qml/components/Editor.qml` | State save/restore hooks on tab switch | ~20 |
| `qml/Main.qml` | Session save/restore, tab shortcuts, update dirty handling | ~30 |
| `qml/components/UnsavedChangesDialog.qml` | Support batch-close mode (list of dirty files) | ~30 |
| `CMakeLists.txt` | Add tabmodel.h/.cpp, TabBar.qml | ~5 |
| **Total** | | **~695** |

---

## Implementation Order

### Step 1: TabModel C++ class
Create `tabmodel.h/.cpp` with core operations (open, close, switch, find). Unit-testable without QML. EditorState struct. Session save/load to JSON.

### Step 2: Wire AppController
Replace `m_currentDocument` singleton pattern. AppController now owns TabModel. `openFile()` delegates to TabModel. Ensure existing single-tab behavior works (open file replaces if same, creates tab if different).

### Step 3: TabBar.qml (basic)
Horizontal ListView with tab delegates. Click to switch, X to close, modified dot. No overflow or drag yet — just functional tabs.

### Step 4: MainContent + Editor rebinding
Editor binds to `TabModel.activeDocument`. ViewMode becomes per-tab. Save/restore EditorState on tab switch. Special viewers (JSONL/PDF/DOCX) route based on active tab's file type.

### Step 5: Dirty file handling
Single-tab close dialog. Batch close dialog for Close All / quit. Pinned tab protection.

### Step 6: Keyboard shortcuts
Ctrl+Tab, Ctrl+W, Ctrl+1-9, Ctrl+Shift+T.

### Step 7: Tab bar polish
Overflow scroll + dropdown. Drag reorder. Context menu. Pin/unpin. Middle-click close.

### Step 8: Session restore
Save/restore all tabs on close/startup. Lazy loading for background tabs. Handle missing files.

### Step 9: Integration fixes
NavigationManager tab-awareness. FileManager multi-tab path updates. SyncEngine debounced rebuild. Quick Switcher tab reuse.

---

## UX Decisions

### Tab switching order: Linear
Ctrl+Tab moves left-to-right through the tab bar (not MRU order). Simpler, more predictable, no popup needed.

### Single Editor instance
One Editor.qml, one TextArea, one QTextDocument at a time. Swap the backing Document on tab switch. Preserves undo via QTextDocument ownership in each Document's tab. Memory-efficient.

### View mode is per-tab
Each tab remembers Edit/Split/Preview independently. A markdown file in Split mode stays in Split when you return. PDF/DOCX tabs lock to their viewer.

### No tab limit
Soft guidance at 50 tabs (subtle toast), no hard limit. Per-tab memory is ~100KB for typical text files.

### Session file is separate
`session.json` is separate from `config.json` — session state changes frequently and is conceptually different from user preferences.

### File type icons
Simple monochrome icons per format in the tab. Helps distinguish tabs when many are open.

---

## Edge Cases

| Scenario | Behavior |
|----------|----------|
| Open same file twice | Switch to existing tab, don't duplicate |
| External file change while tab is backgrounded | Document's FileWatcher fires → if clean: auto-reload; if dirty: show banner when tab becomes active |
| Rename file that has an open tab | FileManager updates Document path, tab label updates |
| Delete file that has an open tab | Close the tab (with dirty prompt if modified) |
| Open 100 tabs | All work, tab bar scrolls, mild memory warning at 50 |
| Ctrl+W on last tab | Tab closes, welcome view shows |
| Close pinned tab via middle-click | Works (with dirty prompt). Only Close All/Close Others skip pinned |
| Session restore with missing file | Tab shows "(deleted)" label, error state in content area |
| JSONL file in a tab | JsonlStore is per-tab; switching away preserves JSONL state |
| Drag file from NavPanel to tab bar | Opens file at drop position |
