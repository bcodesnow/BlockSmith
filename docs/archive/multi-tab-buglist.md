# Multi-Tab Implementation Bug List

Bugs found during code review of Phase 13 multi-tab implementation.
Ordered by severity. All items need fixing before the feature is stable.

---

## Critical

### 1. `_docConns` disconnect pattern broken — leaked signal connections

**Files:** `qml/Main.qml`, `qml/components/EditorStatusBar.qml`, `qml/components/FileChangedBanner.qml`, `qml/components/OutlinePanel.qml`

In QML JavaScript, `signal.connect(func)` returns `undefined`, not a connection object. The `_docConns` array ends up as `[undefined, undefined, ...]`. When `reconnectDocSignals()` runs on the next tab switch, `c.disconnect()` throws a `TypeError` on `undefined`, so old connections are never cleaned up. Every tab switch leaks signal connections — handlers from the previous document keep firing (e.g., save flash animates for the wrong document).

**Fix:** Store the document reference and function references. Disconnect using `doc.signalName.disconnect(funcRef)`:

```javascript
property var _oldDoc: null
property var _connFuncs: []

function reconnectDocSignals() {
    if (_oldDoc) {
        for (let entry of _connFuncs)
            _oldDoc[entry.sig].disconnect(entry.fn)
    }
    _connFuncs = []
    let d = AppController.currentDocument
    _oldDoc = d
    if (!d) return
    let f1 = function() { saveFlash.restart() }
    d.saved.connect(f1)
    _connFuncs.push({ sig: "saved", fn: f1 })
}
```

### 2. Missing `Q_ENUM(Roles)` in TabModel — pin/unpin broken in QML

**File:** `src/tabmodel.h`

The `Roles` enum is not registered with `Q_ENUM(Roles)`. QML code in TabBar.qml references `TabModel.IsPinnedRole` which resolves to `undefined` at runtime. The `data()` call receives an invalid role, so pin/unpin context menu always shows "Pin Tab" and the toggle never works.

**Fix:** Add `Q_ENUM(Roles)` immediately after the enum declaration in `tabmodel.h`.

### 3. `closeSavedTabs()` never restores active tab — UI goes blank

**File:** `src/tabmodel.cpp`, `closeSavedTabs()` around line 306

`m_activeIndex` is set to `-1`, then `qMin(m_activeIndex, m_tabs.size() - 1)` always evaluates to `qMin(-1, N)` = `-1`. `setActiveIndex(-1)` early-returns because it matches the current value. No tab becomes active, `currentDocument()` returns `nullptr`, and the UI shows a blank editor.

**Fix:** Capture the desired active index before resetting. For example:

```cpp
int target = m_tabs.isEmpty() ? -1 : qMin(qMax(m_activeIndex, 0), m_tabs.size() - 1);
m_activeIndex = -1;
emit countChanged();
emit modifiedTabsChanged();
if (target >= 0)
    setActiveIndex(target);
else {
    emit activeIndexChanged();
    emit activeDocumentChanged();
}
```

---

## High

### 4. `closeOtherTabs()` partially mutates before dirty-tab bail-out

**File:** `src/tabmodel.cpp`, `closeOtherTabs()` around line 213

The method closes tabs right-to-left. If a dirty tab is encountered partway through, it emits `tabCloseBlocked` and returns — but tabs already closed in the loop are gone. The user sees a save dialog, but if they cancel, those earlier-closed tabs are permanently lost.

Also, when a dirty tab is at index `i < index`, the `index--` adjustment hasn't run (because of the early return), so the remaining `index` value may be wrong.

**Fix:** Two-pass approach. First scan for any dirty non-pinned non-target tabs. If found, emit `tabCloseBlocked` immediately without closing anything. Only proceed to close if all candidates are clean.

### 5. `repointOpenDocuments` only updates the active tab — non-active tabs keep stale paths

**File:** `src/filemanager.cpp`, `repointOpenDocuments()` around line 276

After a file rename/move, only the active tab's Document gets `load(newPath)`. Non-active tabs still hold the old `filePath()`. Consequences:
- Tab bar shows old filename for non-active renamed tabs
- Saving a non-active tab after activation writes to the old (now-nonexistent) path
- `findTab(newPath)` won't find the tab, so opening the same file creates a duplicate tab

**Fix:** TabModel needs to expose the Document pointer by index (e.g., `Document* tabDocument(int index)`), so FileManager can repoint all affected documents, not just the active one.

---

## Medium

### 6. Auto-save config changes don't propagate to existing tabs

**File:** `src/appcontroller.cpp`, around line 115

The `applyAutoSave` lambda connected to `autoSaveEnabledChanged` and `autoSaveIntervalChanged` is empty. Only newly-opened tabs get the current auto-save settings via `TabModel::openTab()`. If a user toggles auto-save at runtime, already-open documents ignore the change.

**Fix:** Iterate all tabs and call `doc->setAutoSave(...)` on each when the config changes. Could be a method on TabModel like `applyAutoSaveSettings(bool enabled, int interval)`.

### 7. Dirty-tab guard blocks closing already-deleted files

**File:** `src/filemanager.cpp`, `clearOpenDocumentsForDeletedPath()` line 334

When a file is deleted from disk, this method calls `m_tabModel->closeTab(i)`, which checks `document->modified()` and emits `tabCloseBlocked` instead of closing. The user sees a "save changes?" dialog for a file that no longer exists. Saving would recreate the deleted file.

**Fix:** Either force-close the tab (bypass dirty check) or clear the modified flag before closing, since the underlying file is gone. Could add a `forceCloseTab(int index)` method to TabModel.

### 8. `restoreSession()` missing `dataChanged` emits for pin/viewMode

**File:** `src/tabmodel.cpp`, `restoreSession()` around line 488

After `openTab()` creates a tab, `isPinned` and `state.viewMode` are set directly on the Tab struct without emitting `dataChanged`. QML views bound to `IsPinnedRole` or `ViewModeRole` show default values. Pinned tabs from a previous session won't appear pinned in the tab bar.

**Fix:** Emit `dataChanged` after mutation:
```cpp
QModelIndex mi = createIndex(idx, 0);
emit dataChanged(mi, mi, { IsPinnedRole, ViewModeRole });
```

### 9. `UnsavedChangesDialog` saves the wrong document for non-active tab close

**File:** `qml/components/UnsavedChangesDialog.qml`, `onAccepted` handler

The handler uses `AppController.currentDocument` (the active tab's document) rather than the document at `pendingTabIndex`. If `tabCloseBlocked` fires for a non-active tab (possible from `closeOtherTabs` etc.), the wrong document gets saved.

**Fix:** Get the document for the pending tab via `AppController.tabModel` instead of using `AppController.currentDocument`. TabModel could expose a `Q_INVOKABLE Document* tabDocument(int index)` method.

### 10. TabBar anchor binding loop between ListView and scroll buttons

**File:** `qml/components/TabBar.qml`, around line 40

The ListView anchors depend on scroll button visibility (`scrollLeftBtn.visible ? scrollLeftBtn.right : parent.left`), and scroll button visibility depends on ListView geometry (`tabListView.contentWidth - tabListView.width > 0`). This creates a circular dependency. Qt may log "Binding loop detected" warnings and settle unpredictably.

**Fix:** Use fixed anchors with conditional margins instead of switching anchor targets. Always anchor to `parent.left`/`parent.right` and adjust `anchors.leftMargin`/`anchors.rightMargin` based on button visibility.

---

## Low

### 11. Overflow delegate uses `model.isActive` instead of bare `isActive`

**File:** `qml/components/TabBar.qml`, around line 243

The delegate declares `required property bool isActive` but line 243 uses `model.isActive`. With required properties declared, QML uses the "required properties" code path and `model.xxx` attached properties may not be populated.

**Fix:** Change `model.isActive` to `isActive`.

### 12. `unsavedChangesWarning` signal is dead code

**Files:** `src/appcontroller.h` line 88, `src/navigationmanager.h` line 22

Neither class ever emits this signal. The unsaved-change flow now uses `TabModel::tabCloseBlocked` instead.

**Fix:** Remove from both classes.

### 13. NavigationManager constructor takes 3 unused parameters

**File:** `src/appcontroller.cpp` line 66

`new NavigationManager(nullptr, nullptr, nullptr, this)` — all three pointer params are ignored in the constructor body. Leftover from the old single-document architecture.

**Fix:** Simplify constructor to `NavigationManager(QObject *parent)`.

### 14. `navPushPublic` duplicate check is case-sensitive on Windows

**File:** `src/navigationmanager.cpp` line 19

`m_navHistory.last() == path` uses raw `QString::operator==`, which is case-sensitive. On Windows, `C:/Foo/bar.md` and `c:/foo/bar.md` are treated as different entries, causing duplicate history entries for the same file.

**Fix:** Normalize and compare case-insensitively, matching the pattern used in `tabmodel.cpp` and `filemanager.cpp`.

### 15. `m_connectedDocument` can be dangling after tab close

**File:** `src/appcontroller.cpp`, around line 98

When `TabModel::closeTab()` deletes a Document, then emits `activeDocumentChanged`, the handler runs `disconnectActiveDocument(m_connectedDocument)` where `m_connectedDocument` points to the deleted object. Currently safe because `disconnectActiveDocument` only calls `disconnect()` on stored `QMetaObject::Connection` handles (not dereferencing the pointer), but fragile.

**Fix:** Null out `m_connectedDocument` before tab close, or check validity in the handler.

### 16. `ExportDialog.exporting` stuck true if doc is null

**File:** `qml/components/ExportDialog.qml`, around line 266

`dialog.exporting = true` is set before the `if (!doc) return` null check. If doc is null, `exporting` stays true and the dialog shows a permanent busy indicator.

**Fix:** Move `dialog.exporting = true` after the null check.

### 17. Duplicate `normalizePath`/`samePath` utility functions

**Files:** `src/appcontroller.cpp`, `src/tabmodel.cpp`, `src/filemanager.cpp`

Identical anonymous-namespace functions in three files.

**Fix:** Move to `src/utils.h`/`src/utils.cpp` (already exists).

### 18. Context menu `tabIndex` can go stale

**File:** `qml/components/TabBar.qml`, around line 288

`tabContextMenu.tabIndex` is set on right-click but may be invalidated if the model changes while the menu is open (e.g., a keyboard shortcut closes another tab). Actions like `closeOtherTabs(tabContextMenu.tabIndex)` could operate on the wrong tab.

**Fix:** Store `filePath` instead of index, resolve via `findTab()` at action time.
