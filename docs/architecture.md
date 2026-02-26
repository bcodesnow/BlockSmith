# Architecture

## Overview

BlockSmith uses a 3-pane SplitView layout with a C++ backend exposing models and services to QML.

```
NavPanel (left)  |  MainContent (center)  |  RightPane (right)
Project tree     |  Markdown editor/preview|  Blocks / Prompts tabs
```

## QML Module

- URI: `BlockSmith`, loaded via `loadFromModule("BlockSmith", "Main")`
- Registration: `QML_ELEMENT` / `QML_SINGLETON` / `QML_UNCREATABLE` macros
- Policies: `QTP0001` and `QTP0004` (NEW)

## C++ Backend

**AppController** (singleton) owns and exposes all managers:

| Class | Role |
|-------|------|
| NavigationManager | Browser-style back/forward navigation, file opening, history |
| SearchManager | Async file content search, fuzzy file filtering |
| ConfigManager | Search paths, ignore patterns, trigger files, window geometry, settings |
| ProjectScanner | Walks search paths, finds projects by trigger files |
| ProjectTreeModel | QAbstractItemModel for tree view navigation |
| Document | File loading, block parsing, content management, format detection |
| BlockStore | Block registry, QAbstractListModel |
| PromptStore | Prompt library, QAbstractListModel |
| SyncEngine | Push/pull/diff blocks across files |
| Md4cRenderer | md4c markdown-to-HTML wrapper |
| SyntaxHighlighter | Unified QSyntaxHighlighter with Markdown/JSON/YAML/PlainText modes |
| FileManager | File operations (create, rename, delete, duplicate, move) |
| ImageHandler | Clipboard image paste, drag-drop copy, image path utilities |
| JsonlStore | JSONL transcript viewer — threaded parser, filtered list model |
| ExportManager | Export to HTML, PDF (WebEngine), DOCX (pandoc) |

### Document Format Detection

`Document` exposes format-aware enums derived from the file extension:

| Enum | Values | Purpose |
|------|--------|---------|
| `FileType` | `Markdown`, `Json`, `Yaml`, `PlainText` | Core format identification |
| `SyntaxMode` | `SyntaxPlainText`, `SyntaxMarkdown`, `SyntaxJson`, `SyntaxYaml` | Drives `SyntaxHighlighter.mode` |
| `ToolbarKind` | `ToolbarNone`, `ToolbarMarkdown`, `ToolbarJson`, `ToolbarYaml` | Drives toolbar Loader in Editor.qml |
| `PreviewKind` | `PreviewNone`, `PreviewMarkdown` | Determines whether preview pane is available |

To add a new format: add extension check in `fileType()`, add enum values, add highlighter mode in `SyntaxHighlighter`, add toolbar/preview Components as needed.

## Project Structure

```
CMakeLists.txt
src/
  main.cpp
  appcontroller.h / .cpp      # QML singleton facade, owns all managers
  navigationmanager.h / .cpp   # Browser-style nav history, file opening
  searchmanager.h / .cpp       # Async file search, fuzzy file filtering
  configmanager.h / .cpp       # Search paths, settings persistence
  blockstore.h / .cpp          # Block registry, list model
  promptstore.h / .cpp         # Prompt library, list model
  projectscanner.h / .cpp      # Walks search paths, finds projects
  projecttreemodel.h / .cpp    # Tree model for nav panel
  document.h / .cpp             # File loading, block parsing
  syncengine.h / .cpp          # Push/pull/diff blocks across files
  md4crenderer.h / .cpp        # md4c markdown-to-HTML wrapper
  syntaxhighlighter.h / .cpp   # Unified QSyntaxHighlighter (Markdown/JSON/YAML/PlainText modes)
  filemanager.h / .cpp         # File create/rename/delete/duplicate/move
  imagehandler.h / .cpp        # Clipboard/file image operations
  jsonlstore.h / .cpp          # JSONL transcript viewer (threaded parser + list model)
  exportmanager.h / .cpp       # Export to HTML, PDF, DOCX
third_party/
  md4c/                        # md4c library (MIT license)
  yaml-cpp (FetchContent)      # YAML parser/emitter (MIT license, fetched via CMake)
qml/
  Main.qml                     # ApplicationWindow, 3-pane layout
  components/
    Theme.qml                  # Singleton — shared design tokens (dark/light)
    NavPanel.qml               # Left pane — tree + file management context menu
    NavContextMenu.qml         # Right-click context menu for nav tree
    NavFooterBar.qml           # Footer bar for nav panel
    MainContent.qml            # Center — editor/preview + find bar + scroll sync
    EditorHeader.qml           # File path, view mode toggle, undo/redo, save
    FileChangedBanner.qml      # External file change/delete notification banner
    Editor.qml                 # TextArea with toolbar, gutter, syntax highlighting
    EditorContextMenu.qml      # Right-click menu: Cut/Copy/Paste/Add Block/Create Prompt
    ImageDropZone.qml          # Drag-and-drop image overlay
    MdToolbar.qml              # Markdown formatting toolbar
    JsonToolbar.qml            # JSON format toolbar
    YamlToolbar.qml            # YAML format toolbar
    MdPreview.qml              # Lightweight HTML preview (popups)
    MdPreviewWeb.qml           # WebEngine preview with mermaid support
    RightPane.qml              # TabBar: Blocks / Prompts / Outline
    BlockListPanel.qml         # Block list with search + tag filter
    BlockCard.qml              # Block card with insert button
    BlockEditorPopup.qml       # Modal block editor (extends EditorPopupBase)
    BlockDiffPopup.qml         # Diff view for conflicts
    AddBlockDialog.qml         # Create block from selection
    PromptListPanel.qml        # Prompt list by category
    PromptCard.qml             # Prompt card with copy button
    PromptEditorPopup.qml      # Modal prompt editor (extends EditorPopupBase)
    EditorPopupBase.qml        # Shared base for Block/Prompt editor popups
    SettingsDialog.qml         # App configuration (tabbed)
    SettingsProjectsTab.qml    # Settings: search paths, ignore patterns, scan options
    SettingsEditorTab.qml      # Settings: theme, font, syntax, word wrap, auto-save
    SettingsIntegrationsTab.qml # Settings: Claude Code folder toggle
    SearchDialog.qml           # Global file search
    FindReplaceBar.qml         # In-editor find/replace UI
    FindReplaceController.qml  # Find/replace logic (QtObject controller)
    NewProjectDialog.qml       # Create new project
    FileOperationDialog.qml    # New file/folder, rename dialog
    UnsavedChangesDialog.qml   # Save/Discard/Cancel on file switch
    Toast.qml                  # Notification overlay
    SplashOverlay.qml          # Startup splash with logo + spinner
    JsonlViewer.qml            # JSONL transcript viewer panel
    JsonlEntryCard.qml         # Entry card with role badge + preview
    JsonlFilterBar.qml         # JSONL filter bar
    ExportDialog.qml           # Export format picker (PDF/HTML/DOCX)
    QuickSwitcher.qml          # Fuzzy file finder popup (Ctrl+P)
    OutlinePanel.qml           # Document heading outline panel
    EditorStatusBar.qml        # Cursor position, encoding, stats
    LineNumberGutter.qml       # Line number gutter component
resources/
  icons/                       # Multi-size app icons (16-1024px)
  preview/
    index.html                 # WebEngine preview template (dark/light theme CSS)
    mermaid.min.js             # Mermaid diagram renderer (~2MB)
```

## Data Storage

All data stored in `QStandardPaths::AppConfigLocation`:
- Windows: `%LOCALAPPDATA%/BlockSmith`
- Linux: `~/.local/share/BlockSmith`
- macOS: `~/Library/Application Support/BlockSmith`

| File | Purpose |
|------|---------|
| `config.json` | Search paths, ignore patterns, trigger files, window geometry, toolbar visibility, image subfolder, status bar toggles, splitter widths, auto-save settings, search format toggles (md/json/yaml/jsonl), zoom level, theme mode, editor font, word wrap |
| `blocks.db.json` | Block registry |
| `prompts.db.json` | Prompt library |

## Block Format

```markdown
<!-- block: code-style [id:a3f8b2] -->
Content here...
<!-- /block:a3f8b2 -->
```

- **Name** (`code-style`): human-readable label
- **ID** (`a3f8b2`): 6-char hex, generated on creation, never changes

## Features (Complete)

### Project Discovery & Navigation
- Configurable search paths with ignore patterns and scan depth
- Trigger file detection (CLAUDE.md, AGENTS.md, .git, etc.)
- Indexes .md, .markdown, .jsonl, .json, .yaml, and .yml files within discovered projects
- Tree view with expand/collapse all, project/directory/file icons
- Block usage highlighting in tree (files containing blocks are marked)
- File management context menu: New File, New Folder, Rename, Duplicate, Cut, Paste, Delete
- Delete confirmation dialog for files/folders
- Reveal in Explorer, Copy Path, Copy Name
- Create new projects with folder picker and trigger file dropdown
- Auto-scan on startup (configurable) with splash overlay (logo + spinner)

### Markdown Editor
- Three view modes: Edit, Split (side-by-side), Preview — cycle with Ctrl+E
- Split view with draggable handle and line-based scroll sync (data-source-line injection)
- WebEngine preview (Qt WebEngine / Chromium) with dark theme CSS
- Mermaid diagram rendering (` ```mermaid ` code blocks → SVG)
- Markdown formatting toolbar (H1-H3, Bold, Italic, Strikethrough, Code, Code Block, Lists, Link, Image, Table, HR, Blockquote)
- Toolbar toggle button (persisted in config)
- Syntax highlighting (configurable, C++ QSyntaxHighlighter)
- Line number gutter with dynamic width
- Block gutter markers with sync status indicators (synced/diverged/local)
- Current-line background highlight
- Live preview rendered via md4c (styled tables, code blocks, images, hr, lists)
- Tab/Shift+Tab indent/outdent (4 spaces, multi-line selection)
- Auto-continue lists on Enter (bullet, numbered, checkbox — removes empty items)
- Auto-close brackets and backticks with selection wrapping
- Ctrl+D duplicate line
- Image paste from clipboard (Ctrl+V) — auto-saves to configurable subfolder
- Image drag-and-drop from file explorer with visual drop overlay
- Relative image paths resolved to file:// URLs in preview
- Right-click context menu: Cut, Copy, Paste, Select All, Add as Block, Create Prompt

### JSON Editor
- Opens `.json` files from the project tree in the same editor
- Syntax highlighting (keys=blue, strings=green, numbers=orange, booleans/null=purple)
- Format JSON button — prettifies minified JSON via QJsonDocument
- Edit-only mode (no preview/split)
- Highlighter swap: only one QSyntaxHighlighter per document, switched imperatively on file change

### YAML Editor
- Opens `.yaml` and `.yml` files from the project tree in the same editor
- Syntax highlighting (keys=blue, values=green, numbers=orange, booleans/null=purple, comments=grey italic, anchors/aliases=cyan, tags=purple)
- Format YAML button — parses and re-emits via yaml-cpp (validates + prettifies)
- Edit-only mode (no preview/split)
- Supports YAML anchors (`&name`), aliases (`*name`), tags (`!!type`), and document markers (`---`, `...`)

### Block System
- Block registry with JSON persistence
- Create blocks from editor selection
- Edit blocks with split editor/preview popup (two-stage delete confirmation)
- Push block changes to all files containing the block
- Pull changes from file back to registry
- Diff view for conflict resolution (side-by-side comparison)
- Bidirectional sync engine
- Diverged block highlighting in right pane (orange left border on cards with out-of-sync files)
- Tag-based filtering and search
- Insert blocks at cursor position

### Prompt Library
- Prompt registry with categories
- One-click copy to clipboard
- Split editor/preview for prompt editing (two-stage delete confirmation)
- Create prompts from editor selection

### JSONL Transcript Viewer
- Opens .jsonl files automatically when clicked in the project tree
- Background-threaded parsing with chunked loading (handles large transcripts)
- Role-based filtering (user, assistant, tool, system, progress)
- Text search across entry previews
- Tool-use-only filter toggle
- Expand entries to view formatted raw JSON
- Copy individual entries to clipboard
- Content block type detection per the [Claude Messages API](https://docs.anthropic.com/en/api/messages):
  - `text` — plain text content
  - `tool_use` — tool invocations with name + argument preview
  - `tool_result` — tool output (distinguishes errors via `is_error`)
  - `thinking` / `redacted_thinking` — extended thinking blocks
  - `image` — image attachments with media type
  - `document` — document attachments with title
  - `server_tool_use` — server-side tool calls
  - `web_search_tool_result` — web search queries + results
- Claude Code transcript format support (nested `message` object with `uuid`, `parentUuid`, `sessionId`)
- If Anthropic adds new content block types, update the parser in `src/jsonlstore.cpp` (the `Build preview from content` section) — reference: https://docs.anthropic.com/en/api/messages

### Claude Code Integration
- Optional `~/.claude` folder added to project tree via Settings > Integrations toggle
- Recursively indexes .md, .markdown, .jsonl, .json, .yaml, and .yml files from the Claude Code folder
- Auto-rescan when integration setting changes

### Navigation
- Quick Switcher (Ctrl+P) — fuzzy file finder with recent files, keyboard navigation
- Outline Panel — third tab in right pane, heading hierarchy (H1-H6), click-to-navigate, active heading highlight
- Recent files tracking (last 10 opened files, persisted in config)
- Back/forward navigation — browser-style history with Alt+Left/Alt+Right and mouse side buttons (Button 4/5)

### Search
- Global search across enabled file formats (Ctrl+Shift+F, configurable in Settings > Projects)
- Navigate to search results
- Find & Replace in editor (Ctrl+F / Ctrl+H) — undo-safe, scroll-to-match, Shift+Enter for previous

### File Safety
- File watcher (QFileSystemWatcher) — detects external changes to the open file
  - Unmodified documents: auto-reload silently
  - Modified documents: non-modal banner "File changed on disk. [Reload] [Ignore]"
  - Deleted files: banner "File was deleted from disk. [Close]" — Close clears the document
- Auto-save (opt-in via Settings)
  - Configurable interval (5-600 seconds, default 30)
  - Save on window focus loss (ApplicationState → Inactive)
  - Status bar "Auto-saved" flash — only shown on successful save
- Save-safe file switching: unsaved dialog waits for confirmed save before switching
- Dirty-buffer protection: rename/move preserves unsaved edits via `saveTo(newPath)`
- Async scan + index: project scanning and block indexing run off the UI thread
- JSONL worker isolation: generation tokens prevent stale worker signals from leaking
- Drop URL path decoding: dropped image URLs decoded for %20 and unicode

### Export
- Export current document to HTML, PDF, or DOCX via Ctrl+Shift+E
- **HTML** — standalone HTML5 with embedded dark theme CSS, relative images resolved to file:// URLs
- **PDF** — pixel-perfect via QWebEnginePage::printToPdf() (offscreen Chromium, A4, 15mm margins)
- **DOCX** — pandoc via QProcess (graceful degradation if not installed)
- Export dialog with format radio buttons, output path picker, browse FileDialog, progress indicator
- Font size selector: Small / Medium / Large (applies to PDF and HTML body + code)
- Open after export checkbox — launches exported file with system default app
- Default output path: same directory as source file, matching extension

### Theme & Appearance
- Dark and Light themes, switchable in Settings > Editor > Theme
- All colors defined in `Theme.qml` singleton via `isDark` ternary expressions
- `ConfigManager.themeMode` persists choice (`"dark"` / `"light"`) in `config.json`
- `ConfigManager.editorFontFamily` — configurable monospace font (default: Consolas)
- `SyntaxHighlighter.isDarkTheme` — swaps all format colors and rehighlights on change
- Preview HTML (`index.html`) uses `.light` CSS class toggled via `setTheme()` JS function
- Mermaid diagrams re-initialize with matching theme

### UI & Polish
- Dark and Light themes with centralized Theme singleton
- Forced English UI locale (QLocale::setDefault) — consistent button labels
- 3-pane SplitView layout with custom draggable handles (6px transparent + 2px visual line) and persisted splitter widths
- Startup splash overlay with app logo, spinner, and status text (fades out after scan)
- Toast notifications for save, load errors, scan results, clipboard
- Unsaved changes dialog (Save/Discard/Cancel on file switch)
- Status bar with save-state dot, cursor position, encoding, auto-save indicator, configurable word/char/line/reading-time stats
- Pointer cursor on all clickable elements
- Keyboard shortcuts:
  - Ctrl+S (save), Ctrl+R (reload), Ctrl+E (cycle Edit/Split/Preview)
  - Ctrl+F (find), Ctrl+H (replace), Ctrl+Shift+F (global search)
  - Ctrl+Shift+E (export), Ctrl+Shift+S / F5 (scan), Ctrl+, (settings)
  - Ctrl+B (bold), Ctrl+I (italic), Ctrl+Shift+K (inline code)
  - Ctrl+D (duplicate line), Tab/Shift+Tab (indent/outdent)
  - Ctrl+P (quick switcher)
  - Alt+Left / Alt+Right (back/forward navigation), mouse side buttons
  - Ctrl+W (close file), Ctrl+Q (quit), Ctrl+=/Ctrl+- (zoom), Ctrl+0 (reset zoom)
- Window geometry persistence
- Splitter width persistence (left nav + right pane)
- Multi-size app icon (16-1024px PNGs + ICO)
- File encoding detection (UTF-8, UTF-8 BOM, UTF-16 LE/BE)
- Compiler warnings enabled (-Wall -Wextra -Wpedantic), zero warnings
