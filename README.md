# BlockSmith

A desktop application for centrally managing reusable content blocks across CLAUDE.md and agent instruction files scattered across project roots. Built with C++17 / Qt 6 / QML.

## The Problem

Agent instruction files (CLAUDE.md, AGENTS.md) exist in every project root. Many share common sections — coding standards, response style, tool configs — but they drift out of sync. There's no way to see what's where, update a shared block in one place and push it everywhere, or build a personal library of reusable blocks and prompts.

## The Solution

Tag reusable sections in md files as **blocks** with unique IDs. Manage them from a central registry. Push, pull, diff, sync across all projects. A second mode manages a prompt library for quick clipboard copy.

## Features

### Project Discovery & Navigation
- Configurable search paths with trigger file detection (CLAUDE.md, AGENTS.md, .git, etc.)
- Tree view with expand/collapse all, project/directory/file icons
- Right-click context menu: Open, Reveal in Explorer, Copy Path, Copy Name
- Create new projects with folder picker and trigger file dropdown
- Auto-scan on startup (optional)
- Block usage highlighting in tree

### Editor
- Markdown editor with syntax highlighting (optional, C++ QSyntaxHighlighter)
- Live preview with md4c rendering
- Edit/Preview toggle (Ctrl+E)
- Find & Replace (Ctrl+F / Ctrl+H)
- Line number gutter
- Block gutter markers with sync status indicators
- Right-click context menu: Cut, Copy, Paste, Select All, Add as Block, Create Prompt

### Block System
- Block registry with JSON persistence
- Block format: `<!-- block: name [id:hexid] -->content<!-- /block:hexid -->`
- Create blocks from editor selection
- Edit blocks with split editor/preview popup
- Push changes to all files containing the block
- Pull changes from file back to registry
- Diff view for conflict resolution
- Bidirectional sync engine
- Tag-based filtering and search

### Prompt Library
- Prompt registry with categories
- One-click copy to clipboard
- Split editor/preview for prompt editing
- Create prompts from editor selection

### Global Search
- Search across all project files (Ctrl+Shift+F)
- Navigate to results

### UI & Polish
- Dark theme, 3-pane SplitView layout
- Toast notifications
- Keyboard shortcuts (Ctrl+S, F5, Ctrl+R, Ctrl+,)
- Window geometry persistence
- Custom app icon
- Status bar

## Block Format

```markdown
<!-- block: code-style [id:a3f8b2] -->
Content here...
<!-- /block:a3f8b2 -->
```

- **Name** (`code-style`): human-readable label
- **ID** (`a3f8b2`): 6-char hex, generated on creation, never changes

## Build

### Requirements
- Qt 6.10+ with Quick, QuickControls2, Core modules
- CMake 3.21+
- C++17 compiler (MinGW 13.1+ or MSVC)

### Build Commands
```bash
cmake -B build -G Ninja \
  -DCMAKE_BUILD_TYPE=Debug \
  -DCMAKE_PREFIX_PATH="C:/Qt/6.10.1/mingw_64"
cmake --build build
```

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

All data stored in `QStandardPaths::AppConfigLocation` (Windows: `%LOCALAPPDATA%/BlockSmith`):

| File | Purpose |
|------|---------|
| `config.json` | Search paths, ignore patterns, trigger files, window geometry |
| `blocks.db.json` | Block registry |
| `prompts.db.json` | Prompt library |

## License

Copyright (C) 2026 Danube Mechatronics Kft.

Authors: kb (kb@danube-mechatronics.com) & Claude (Anthropic)

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

See [LICENSE](LICENSE) for details.
