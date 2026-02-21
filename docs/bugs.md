# Bugs

## Resolved

1. **Tree collapse on file add** — Replaced `beginResetModel()/endResetModel()` with incremental `syncChildren()` diff algorithm. Tree now preserves expand/collapse state across file operations.

2. **Zoom + split view resize** — Implemented zoom feature: `zoomLevel` in ConfigManager (50-200%), Ctrl++/Ctrl+-/Ctrl+0 shortcuts, Ctrl+MouseWheel, WebEngineView zoomFactor, status bar indicator.

3. **Search in file and all files** — Ctrl+F FindReplaceBar was invisible due to `height` vs `implicitHeight` in ColumnLayout. Fixed.

4. **Preview scroll sync with editor** — Implemented bidirectional scroll sync via WebChannel bridge (ScrollBridge), debounced editor→preview + preview→editor sync, cursor-move sync, heading click-to-scroll.

5. **Active cursor position not visible** — Added custom `cursorDelegate` (2px, #d4d4d4, smooth blink), bumped current-line highlight from 4% to 8% opacity.

## Open

### 2026-02-21 Full Review (Priority Order)

1. **[HIGH] Save-and-switch can lose unsaved changes if save fails**
   - `qml/Main.qml:103` calls `save()` and immediately calls `forceOpenFile()`.
   - `src/mddocument.cpp:91` can fail save and return.
   - Action: only switch file on confirmed successful save.

2. **[HIGH] Rename/move can drop dirty buffer of currently open file**
   - `src/filemanager.cpp:99` and `src/filemanager.cpp:132` reload file after rename/move.
   - No modified-check gate before reload.
   - Action: block operation or require Save/Discard/Cancel when target file is open and dirty.

3. **[HIGH] Startup appears stuck while scanning**
   - `src/projectscanner.cpp:17` scan is synchronous on the UI thread.
   - `src/appcontroller.cpp:32` emits `scanComplete` only after `rebuildIndex()`.
   - `qml/Main.qml:148` dismisses splash only on `scanComplete`.
   - Action: move scan/index to worker thread, provide progress + cancel.

4. **[MEDIUM] JSONL worker cancellation can mix stale chunks into a new load**
   - `src/jsonlstore.cpp:36` worker loop has no interruption token.
   - `src/jsonlstore.cpp:307` starts new worker after a timed wait.
   - Action: add per-load generation token/cancel flag and ignore stale worker signals.

5. **[MEDIUM] Auto-save success UI can be incorrect**
   - `src/mddocument.cpp:243` emits `autoSaved()` even when `save()` fails.
   - `src/appcontroller.cpp:65` also emits `autoSaved()` after focus-loss save call.
   - Action: make `save()` return status and emit auto-save success only on true commit.

6. **[MEDIUM] Deleted-file banner "Close" does not close document**
   - `qml/components/MainContent.qml:349` label says "Close".
   - `qml/components/MainContent.qml:363` only hides banner.
   - Action: call `AppController.currentDocument.clear()` on deleted-file close action.

7. **[LOW] Drag-drop image path decoding fails on encoded paths**
   - `qml/components/MdEditor.qml:42` strips `file:///` but does not decode `%20`, etc.
   - Action: decode dropped URL path before copy.
