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
| ConfigManager | Search paths, ignore patterns, trigger files, window geometry |
| ProjectScanner | Walks search paths, finds projects by trigger files |
| ProjectTreeModel | QAbstractItemModel for tree view navigation |
| MdDocument | File loading, block parsing, content management |
| BlockStore | Block registry, QAbstractListModel |
| PromptStore | Prompt library, QAbstractListModel |
| SyncEngine | Push/pull/diff blocks across files |
| Md4cRenderer | md4c markdown-to-HTML wrapper |
| MdSyntaxHighlighter | QSyntaxHighlighter for markdown editing |

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
third_party/
  md4c/                        # md4c library (MIT license)
qml/
  Main.qml                     # ApplicationWindow, 3-pane layout
  components/
    NavPanel.qml               # Left pane — tree + buttons
    MainContent.qml            # Center — editor/preview + find bar
    MdEditor.qml               # TextArea with syntax highlighting
    MdPreview.qml              # Rendered HTML preview
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
    Toast.qml                  # Notification overlay
resources/
  icons/blocksmith.ico
```

## Data Storage

All data stored in `QStandardPaths::AppConfigLocation`:
- Windows: `%LOCALAPPDATA%/BlockSmith`
- Linux: `~/.local/share/BlockSmith`
- macOS: `~/Library/Application Support/BlockSmith`

| File | Purpose |
|------|---------|
| `config.json` | Search paths, ignore patterns, trigger files, window geometry |
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
- Configurable search paths with ignore patterns
- Trigger file detection (CLAUDE.md, AGENTS.md, .git, etc.)
- Tree view with expand/collapse all, project/directory/file icons
- Block usage highlighting in tree (files containing blocks are marked)
- Right-click context menu: Open, Reveal in Explorer, Copy Path, Copy Name
- Create new projects with folder picker and trigger file dropdown
- Auto-scan on startup (configurable)

### Markdown Editor
- Syntax highlighting (configurable, C++ QSyntaxHighlighter)
- Line number gutter
- Block gutter markers with sync status indicators
- Edit/Preview toggle (Ctrl+E)
- Live preview rendered via md4c
- Right-click context menu: Cut, Copy, Paste, Select All, Add as Block, Create Prompt

### Block System
- Block registry with JSON persistence
- Create blocks from editor selection
- Edit blocks with split editor/preview popup
- Push block changes to all files containing the block
- Pull changes from file back to registry
- Diff view for conflict resolution (side-by-side comparison)
- Bidirectional sync engine
- Tag-based filtering and search
- Insert blocks at cursor position

### Prompt Library
- Prompt registry with categories
- One-click copy to clipboard
- Split editor/preview for prompt editing
- Create prompts from editor selection

### Search
- Global search across all project files (Ctrl+Shift+F)
- Navigate to search results
- Find & Replace in editor (Ctrl+F / Ctrl+H)

### UI & Polish
- Dark theme (Fusion style)
- 3-pane SplitView layout
- Toast notifications
- Status bar with word/char/line count
- Keyboard shortcuts (Ctrl+S, Ctrl+R, F5, Ctrl+,, Ctrl+E, Ctrl+Shift+S)
- Window geometry persistence
- Custom app icon
