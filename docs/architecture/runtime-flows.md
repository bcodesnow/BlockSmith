# Runtime Flows

## Open File

1. User selects a file from tree, quick switcher, or search result.
2. `AppController.openFile(path)` is called.
3. For text/viewable files:
   - `TabModel.openTab(path)` opens or reuses a tab.
   - Active tab changes.
   - `currentDocument` updates.
4. For `.jsonl` files:
   - `JsonlStore.load(path)` starts threaded parse.
   - Center pane switches to JSONL viewer mode.

## Edit and Save

1. Editor updates `Document.rawContent`.
2. `Document.modified` tracks dirty state.
3. Save (`Ctrl+S`) calls `Document.save()`.
4. `QSaveFile` writes atomically and watcher is reattached.
5. Signals update tab UI, status bar, and sync index refresh triggers.

## Tab Switching

1. `TabModel.aboutToSwitchTab` is emitted.
2. QML stores cursor, scroll, selection, and view mode into active tab state.
3. `TabModel.activeIndex` changes.
4. QML restores saved state for incoming tab.

## Project Scan

1. `ProjectScanner.scan()` runs asynchronously.
2. Trigger-file detection identifies project roots.
3. Tree shadow model is built.
4. `ProjectTreeModel.syncChildren(...)` applies a model-safe incremental update.
5. `SyncEngine.rebuildIndex()` refreshes markdown block index.

## Block Sync

1. `SyncEngine` caches block occurrences per markdown file.
2. Push updates file content from `BlockStore` to all occurrences.
3. Pull updates `BlockStore` from selected file occurrence.
4. `blockSyncStatus()` reports synced/diverged state for UI.

## Export

1. User opens `ExportDialog`.
2. Markdown content is passed to `ExportManager`.
3. Engine depends on target:
   - PDF: WebEngine print pipeline
   - HTML: standalone HTML generation
   - DOCX: pandoc subprocess
4. Completion/error signals return to QML.
