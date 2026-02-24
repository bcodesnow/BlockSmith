# BlockSmith Code Audit & Refactoring Roadmap

**Date:** 2026-02-23

## Audit Summary

Code audit of the full BlockSmith codebase (~4,950 C++ LOC across 31 files, 29 QML components).

**Overall grade: B+** — Functional, no dead code, good Qt patterns. Main weaknesses are bloated QML files, copy-paste duplication, and AppController doing too much.

---

## Findings

### Critical: Bloated Files

| File | Lines | Limit | Over by |
|------|-------|-------|---------|
| MainContent.qml | 723 | 300 | 423 |
| Editor.qml | 633 | 300 | 333 |
| NavPanel.qml | 543 | 300 | 243 |
| SettingsDialog.qml | 421 | 300 | 121 |
| Main.qml | 392 | 300 | 92 |
| jsonlstore.cpp | 470 | ~400 | 70 |

### High: God Object — AppController

AppController owns 12 subsystems, wires all signal chains, manages search threading, and handles cross-subsystem state. Classic SRP violation.

### High: Duplicated Code

- **ID generation** — Nearly identical in BlockStore and PromptStore
- **BOM detection** — Duplicated between SyncEngine and Document
- **QML button styling** — Same pattern copy-pasted across 6+ QML files (~50+ lines)
- **Editor popups** — BlockEditorPopup and PromptEditorPopup share identical layout structure
- **roleColor()** — Defined in both JsonlEntryCard and JsonlViewer

### Medium: Bug — JsonlStore Worker Thread Leak

`stopWorker()` calls `quit()` + `wait(2000)` but if the wait times out, the old thread pointer is overwritten without cleanup. Loading two JSONL files quickly leaks the first worker thread.

### Medium: Silent Error Handling

BlockStore and PromptStore `load()` methods silently return on file open failure or JSON parse error. No log, no signal, no user feedback.

### Medium: JS Logic in QML That Belongs in C++

- Find/replace regex engine (MainContent.qml, 100+ lines)
- Block range parsing (Editor.qml, 41 lines, runs on every keystroke)
- Fuzzy matching (QuickSwitcher.qml, 24 lines)
- Line calculation using `.substring().split("\n").length` on every access

### Medium: Coupling Issues

- AppController.h includes all 12 subsystem headers (forward declarations not viable — Qt 6.10 MOC requires full includes for Q_PROPERTY pointer types; splitting AppController is the real fix)
- FileManager directly manipulates Document internals
- SyncEngine does raw file I/O instead of going through an abstraction

### Low: Cleanup

- `nul` file in project root (accidental Windows artifact)
- Unused QML imports in several files
- Hardcoded colors that should be in Theme
- Magic numbers (0x1000000, 6-char IDs)

### Positive

- **Zero dead code** — no commented-out blocks, no `#if 0`, no unused Q_INVOKABLE methods
- All declared methods are called somewhere
- Good use of Qt patterns (QML_ELEMENT, signals/slots, models)
- No memory leaks detected (proper Qt parent ownership)
- All files under 1256 LOC limit

---

## Refactoring Roadmap

### Implemented (this session)

| Action | Status |
|--------|--------|
| Fix JsonlStore worker thread leak | Done |
| Extract `utils.h/cpp` (generateHexId + detectBomEncoding) | Done |
| Deduplicate BlockStore/PromptStore/SyncEngine/Document | Done |
| Add arrow key navigation to SearchDialog | Done |
| Extract EditorStatusBar.qml from MainContent.qml | Done |
| Extract NavContextMenu.qml from NavPanel.qml | Done |
| Extract NavFooterBar.qml from NavPanel.qml | Done |
| Extract JsonlFilterBar.qml from JsonlViewer.qml | Done |
| Move roleColor() to Theme.qml | Done |
| Add qWarning to store load failures | Done |
| Forward declarations in AppController.h | Reverted — Qt 6.10 MOC requires full includes for Q_PROPERTY pointer types |
| Remove unused QML imports | Checked — no unused imports found (audit was a false positive) |
| Delete `nul` file | Done |

### Future Recommendations

| Priority | Action | Effort |
|----------|--------|--------|
| Refactor | Extract shared `StyledButton.qml` / `EditorPopupBase.qml` components | 2-3 hrs |
| Move | Find/replace engine + block range parsing to C++ backend | 3-4 hrs |
| Refactor | Split Editor.qml (extract gutter, block ranges, image helpers) | 2-3 hrs |
| Refactor | Split SettingsDialog.qml (extract tab components, reusable TextArea) | 1-2 hrs |
| Refactor | Split Main.qml (extract shortcuts, toast connections, dialogs) | 1-2 hrs |
| Consider | Split AppController into domain managers (DocumentManager, BlockManager, ProjectManager, SearchManager) | 2-3 days |
| Consider | Move fuzzy matching (QuickSwitcher) to C++ for performance | 1 hr |
| Consider | Add `Result<T>` pattern for error propagation instead of silent returns | 1-2 hrs |
