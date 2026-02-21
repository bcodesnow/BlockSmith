# Bugs

## Resolved

1. **Tree collapse on file add** — Replaced `beginResetModel()/endResetModel()` with incremental `syncChildren()` diff algorithm. Tree now preserves expand/collapse state across file operations.

2. **Zoom + split view resize** — Implemented zoom feature: `zoomLevel` in ConfigManager (50-200%), Ctrl++/Ctrl+-/Ctrl+0 shortcuts, Ctrl+MouseWheel, WebEngineView zoomFactor, status bar indicator.

3. **Search in file and all files** — Ctrl+F FindReplaceBar was invisible due to `height` vs `implicitHeight` in ColumnLayout. Fixed.

4. **Preview scroll sync with editor** — Implemented bidirectional scroll sync via WebChannel bridge (ScrollBridge), debounced editor→preview + preview→editor sync, cursor-move sync, heading click-to-scroll.

5. **Active cursor position not visible** — Added custom `cursorDelegate` (2px, #d4d4d4, smooth blink), bumped current-line highlight from 4% to 8% opacity.

## Open

(none)
