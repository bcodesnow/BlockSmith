# Phase 12 — Code Quality (Archived)

Address remaining findings from the latest code audit.

## 12.1 QML Refactoring

- Extracted `EditorPopupBase.qml` shared component (BlockEditorPopup + PromptEditorPopup)
- Split SettingsDialog.qml into SettingsProjectsTab, SettingsEditorTab, SettingsIntegrationsTab
- Split MainContent.qml — extracted EditorHeader, FileChangedBanner
- Split Editor.qml — extracted EditorContextMenu, ImageDropZone
- Split Main.qml — extracted UnsavedChangesDialog

## 12.2 Move Logic to C++

- Fuzzy matching already in C++ (`AppController::fuzzyFilterFiles`) — no work needed
- Block range parsing already in C++ (`Document::computeBlockRanges`) — no work needed
- Find/replace properly split: FindReplaceController.qml + Document::findMatches in C++. Replace ops stay in QML to preserve TextArea undo stack.

## 12.3 Architecture

- Extracted NavigationManager (browser-style nav history + file opening) from AppController
- Extracted SearchManager (async file search + fuzzy filtering) from AppController
- AppController reduced to thin facade with forwarding calls (~260 LOC, down from ~515)
- `Result<T>` pattern deferred — low priority, current error handling adequate
