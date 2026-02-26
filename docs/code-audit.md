# BlockSmith Code Audit

**Date:** 2026-02-23 (audit performed)
**Updated:** 2026-02-26

## Summary

Code audit of the full BlockSmith codebase (~5,100 C++ LOC across 33 files, 38 QML components).

**Overall grade: A-** — Functional, no dead code, good Qt patterns. Domain managers extracted, clean separation of concerns.

---

## Resolved

| Finding | Resolution |
|---------|-----------|
| JsonlStore worker thread leak | Fixed — proper cleanup on timeout |
| Duplicated ID generation (BlockStore/PromptStore) | Extracted to `utils.h/cpp` |
| Duplicated BOM detection (SyncEngine/Document) | Extracted to `utils.h/cpp` |
| Duplicated roleColor() (JsonlEntryCard/JsonlViewer) | Moved to Theme.qml |
| Silent store load failures | Added qWarning logging |
| `nul` file in project root | Deleted |
| Extracted EditorStatusBar.qml | Done — from MainContent.qml |
| Extracted NavContextMenu.qml + NavFooterBar.qml | Done — from NavPanel.qml |
| Extracted JsonlFilterBar.qml | Done — from JsonlViewer.qml |
| SearchDialog keyboard navigation | Added arrow key support |
| Bloated QML: SettingsDialog.qml (472 lines) | Split into SettingsProjectsTab, SettingsEditorTab, SettingsIntegrationsTab (~88 lines) |
| Bloated QML: MainContent.qml (553 lines) | Extracted EditorHeader + FileChangedBanner (~275 lines) |
| Bloated QML: Editor.qml (550 lines) | Extracted EditorContextMenu + ImageDropZone (~452 lines) |
| Bloated QML: Main.qml (416 lines) | Extracted UnsavedChangesDialog (~375 lines) |
| BlockEditorPopup / PromptEditorPopup duplication | Extracted shared EditorPopupBase.qml |
| QML button styling duplication | Partially addressed by EditorPopupBase extraction |
| Hardcoded colors not in Theme | Resolved in Phase 11 (Theme system) |
| Fuzzy matching in QML (QuickSwitcher) | Already in C++ (`AppController::fuzzyFilterFiles`) |
| Block range parsing in QML (Editor) | Already in C++ (`Document::computeBlockRanges`) |
| Find/replace engine in QML | Properly split: FindReplaceController.qml + Document::findMatches in C++. Replace ops must stay in QML to preserve TextArea undo stack. |
| AppController god object | Extracted NavigationManager (nav history + file opening) and SearchManager (async search + fuzzy filtering). AppController is now a thin facade with forwarding calls. |

---

## Remaining Findings

### Other

- FileManager directly manipulates Document internals
- SyncEngine does raw file I/O (no abstraction layer)

---

## Recommended Actions

All remaining items are tracked in [ROADMAP.md Phase 12 — Code Quality](ROADMAP.md#phase-12--code-quality).

| Action | Effort |
|--------|--------|
| Add `Result<T>` error propagation pattern | 1-2 hrs |
