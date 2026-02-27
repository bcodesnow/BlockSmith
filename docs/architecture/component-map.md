# Component Map

## Backend (C++)

`AppController` exposes these components to QML:

| Component | Responsibility |
|----------|----------------|
| `TabModel` | Open tabs, active tab, tab state, session persistence |
| `Document` | File load/save, format detection, block parsing, watcher, auto-save |
| `ConfigManager` | Persistent settings and UI preferences |
| `ProjectScanner` | Project discovery from search paths and trigger files |
| `ProjectTreeModel` | Tree model used by navigation pane |
| `SearchManager` | Global content search and fuzzy quick-switch filtering |
| `NavigationManager` | Back/forward file navigation history |
| `BlockStore` | Persistent reusable block registry |
| `PromptStore` | Persistent prompt library |
| `SyncEngine` | Block index, push/pull operations, diff generation |
| `FileManager` | Create/rename/move/delete/duplicate operations |
| `ImageHandler` | Clipboard and drag-drop image handling |
| `JsonlStore` | Background JSONL parsing and filtered list model |
| `ExportManager` | Markdown export to PDF/HTML/DOCX |
| `Md4cRenderer` | Markdown to HTML conversion |
| `SyntaxHighlighter` | Format-aware syntax highlighting |

## Frontend (QML)

| Area | Main Components |
|------|------------------|
| Shell | `Main.qml`, `MainContent.qml`, `NavPanel.qml`, `RightPane.qml` |
| Tabs and editor | `TabBar.qml`, `Editor.qml`, `EditorHeader.qml`, `EditorStatusBar.qml` |
| Markdown preview | `MdPreviewWeb.qml` |
| File viewers | `JsonlViewer.qml`, `PdfViewer.qml`, `DocxViewer.qml` |
| Blocks and prompts | `BlockListPanel.qml`, `PromptListPanel.qml`, popups and dialogs |
| Search and navigation | `QuickSwitcher.qml`, `SearchDialog.qml`, `OutlinePanel.qml` |
| Settings | `SettingsDialog.qml` and tab subcomponents |

## Ownership Notes

- `TabModel` owns `Document` instances per open tab
- `AppController.currentDocument` maps to `TabModel.activeDocument`
- `JsonlStore` is currently global (not tab-scoped)
