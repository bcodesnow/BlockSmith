# User Manual

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Ctrl+S | Save current document |
| Ctrl+R | Reload current document |
| Ctrl+E | Toggle edit / preview mode |
| Ctrl+F | Find in editor |
| Ctrl+H | Find & Replace in editor |
| Ctrl+Shift+F | Global search across all project files |
| Ctrl+Shift+S | Scan projects |
| F5 | Scan projects |
| Ctrl+, | Open settings |
| Escape | Close find bar / dialogs |
| Enter | Find next match (in find bar) |

## Data Storage

All application data is stored at the OS config location:

| OS | Path |
|----|------|
| Windows | `%LOCALAPPDATA%\BlockSmith\` |
| Linux | `~/.local/share/BlockSmith/` |
| macOS | `~/Library/Application Support/BlockSmith/` |

### Files

| File | Contents |
|------|----------|
| `config.json` | Search paths, ignore patterns, trigger files, window geometry, settings |
| `blocks.db.json` | Block registry (all blocks with id, name, content, tags, timestamps) |
| `prompts.db.json` | Prompt library (all prompts with id, name, content, category, timestamps) |

## Default Settings

| Setting | Default |
|---------|---------|
| Auto-scan on startup | Enabled |
| Syntax highlighting | Enabled |
| Ignore patterns | `node_modules`, `.git`, `dist`, `build`, `__pycache__`, `.venv`, `venv`, `target`, `.build` |
| Trigger files | `CLAUDE.md`, `claude.md`, `.claude.md`, `AGENTS.md`, `agents.md`, `.agents.md`, `.git` |

## Layout

BlockSmith uses a 3-pane layout:

```
 NavPanel (left)  |  MainContent (center)  |  RightPane (right)
 Project tree     |  Editor or Preview     |  Blocks / Prompts
```

- **Left pane** — project tree with expand/collapse all, block usage highlighting
- **Center pane** — markdown editor with line numbers and gutter markers, or rendered preview
- **Right pane** — tabbed panel for Blocks and Prompts

## Working with Blocks

1. **Create a block** — select text in the editor, right-click, choose "Add as Block"
2. **Edit a block** — click a block card in the right pane to open the editor popup
3. **Push** — update all files containing the block with the latest registry content
4. **Pull** — update the registry with content from a file (when the file version diverges)
5. **Diff** — view side-by-side differences when a block has diverged between registry and file
6. **Insert** — click the insert button on a block card to insert it at the cursor position
7. **Filter** — use the search bar or tag filter in the block panel

## Working with Prompts

1. **Create a prompt** — select text in the editor, right-click, choose "Create Prompt", or use the add button in the prompt panel
2. **Copy** — click the copy button on a prompt card to copy to clipboard
3. **Edit** — click a prompt card to open the editor popup
4. **Categories** — organize prompts by category, filter by category in the panel

## Context Menus

### Editor (right-click)
- Cut, Copy, Paste, Select All
- Add as Block
- Create Prompt

### Project Tree (right-click)
- Open
- Reveal in Explorer
- Copy Path
- Copy Name
