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
| ConfigManager | Search paths, ignore patterns, trigger files, window geometry, settings |
| ProjectScanner | Walks search paths, finds projects by trigger files |
| ProjectTreeModel | QAbstractItemModel for tree view navigation |
| MdDocument | File loading, block parsing, content management |
| BlockStore | Block registry, QAbstractListModel |
| PromptStore | Prompt library, QAbstractListModel |
| SyncEngine | Push/pull/diff blocks across files |
| Md4cRenderer | md4c markdown-to-HTML wrapper |
| MdSyntaxHighlighter | QSyntaxHighlighter for markdown editing |
| FileManager | File operations (create, rename, delete, duplicate, move) |
| ImageHandler | Clipboard image paste, drag-drop copy, image path utilities |
| JsonlStore | JSONL transcript viewer — threaded parser, filtered list model |

## Project Structure

```
CMakeLists.txt
src/
  main.cpp
  appcontroller.h / .cpp      # QML singleton, owns all managers
  configmanager.h / .cpp       # Search paths, settings persistence
  blockstore.h / .cpp          # Block registry, list model
  promptstore.h / .cpp         # Prompt library, list model
  projectscanner.h / .cpp      # Walks search paths, finds projects
  projecttreemodel.h / .cpp    # Tree model for nav panel
  mddocument.h / .cpp          # File loading, block parsing
  syncengine.h / .cpp          # Push/pull/diff blocks across files
  md4crenderer.h / .cpp        # md4c markdown-to-HTML wrapper
  mdsyntaxhighlighter.h / .cpp # QSyntaxHighlighter for markdown
  filemanager.h / .cpp         # File create/rename/delete/duplicate/move
  imagehandler.h / .cpp        # Clipboard/file image operations
  jsonlstore.h / .cpp          # JSONL transcript viewer (threaded parser + list model)
third_party/
  md4c/                        # md4c library (MIT license)
qml/
  Main.qml                     # ApplicationWindow, 3-pane layout
  components/
    Theme.qml                  # Singleton — shared design tokens
    NavPanel.qml               # Left pane — tree + file management context menu
    MainContent.qml            # Center — editor/preview + find bar + toolbar toggle
    MdEditor.qml               # TextArea with toolbar, gutter, syntax highlighting
    MdToolbar.qml              # Markdown formatting toolbar
    MdPreview.qml              # Lightweight HTML preview (popups)
    MdPreviewWeb.qml           # WebEngine preview with mermaid support
    RightPane.qml              # TabBar: Blocks / Prompts
    BlockListPanel.qml         # Block list with search + tag filter
    BlockCard.qml              # Block card with insert button
    BlockEditorPopup.qml       # Modal block editor
    BlockDiffPopup.qml         # Diff view for conflicts
    AddBlockDialog.qml         # Create block from selection
    PromptListPanel.qml        # Prompt list by category
    PromptCard.qml             # Prompt card with copy button
    PromptEditorPopup.qml      # Modal prompt editor
    SettingsDialog.qml         # App configuration
    SearchDialog.qml           # Global file search
    FindReplaceBar.qml         # In-editor find/replace
    NewProjectDialog.qml       # Create new project
    FileOperationDialog.qml    # New file/folder, rename dialog
    Toast.qml                  # Notification overlay
    SplashOverlay.qml          # Startup splash with logo + spinner
    JsonlViewer.qml            # JSONL transcript viewer panel
    JsonlEntryCard.qml         # Entry card with role badge + preview
resources/
  icons/                       # Multi-size app icons (16-1024px)
  preview/
    index.html                 # WebEngine preview template (dark theme CSS)
    mermaid.min.js             # Mermaid diagram renderer (~2MB)
```

## Data Storage

All data stored in `QStandardPaths::AppConfigLocation`:
- Windows: `%LOCALAPPDATA%/BlockSmith`
- Linux: `~/.local/share/BlockSmith`
- macOS: `~/Library/Application Support/BlockSmith`

| File | Purpose |
|------|---------|
| `config.json` | Search paths, ignore patterns, trigger files, window geometry, toolbar visibility, image subfolder, status bar toggles |
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
- Tree view with expand/collapse all, project/directory/file icons
- Block usage highlighting in tree (files containing blocks are marked)
- File management context menu: New File, New Folder, Rename, Duplicate, Cut, Paste, Delete
- Delete confirmation dialog for files/folders
- Reveal in Explorer, Copy Path, Copy Name
- Create new projects with folder picker and trigger file dropdown
- Auto-scan on startup (configurable) with splash overlay (logo + spinner)

### Markdown Editor
- Three view modes: Edit, Split (side-by-side), Preview — cycle with Ctrl+E
- Split view with draggable handle and percentage-based scroll sync
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
- Recursively indexes .md, .jsonl, .json files from the Claude internal folder
- Auto-rescan when integration setting changes

### Search
- Global search across all project files (Ctrl+Shift+F)
- Navigate to search results
- Find & Replace in editor (Ctrl+F / Ctrl+H) — undo-safe, scroll-to-match, Shift+Enter for previous

### UI & Polish
- Dark theme (Fusion style) with centralized Theme singleton
- 3-pane SplitView layout
- Startup splash overlay with app logo, spinner, and status text (fades out after scan)
- Toast notifications for save, load errors, scan results, clipboard
- Unsaved changes dialog (Save/Discard/Cancel on file switch)
- Status bar with save-state dot, cursor position, encoding, configurable word/char/line/reading-time stats
- Pointer cursor on all clickable elements
- Keyboard shortcuts:
  - Ctrl+S (save), Ctrl+R (reload), Ctrl+E (cycle Edit/Split/Preview)
  - Ctrl+F (find), Ctrl+H (replace), Ctrl+Shift+F (global search)
  - Ctrl+Shift+S / F5 (scan), Ctrl+, (settings)
  - Ctrl+B (bold), Ctrl+I (italic), Ctrl+Shift+K (inline code)
  - Ctrl+D (duplicate line), Tab/Shift+Tab (indent/outdent)
- Window geometry persistence
- Multi-size app icon (16-1024px PNGs + ICO)
- File encoding detection (UTF-8, UTF-8 BOM, UTF-16 LE/BE)
- Compiler warnings enabled (-Wall -Wextra -Wpedantic), zero warnings
