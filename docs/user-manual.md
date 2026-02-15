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
| Ctrl+B | Bold (**text**) |
| Ctrl+I | Italic (*text*) |
| Ctrl+Shift+K | Inline code (`text`) |
| Ctrl+D | Duplicate current line |
| Tab | Indent (4 spaces, multi-line with selection) |
| Shift+Tab | Outdent |
| Enter | Auto-continue lists (in list context) |
| Shift+Enter | Find previous match (in find bar) |
| Escape | Close find bar / dialogs |

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
| `config.json` | Search paths, ignore patterns, trigger files, window geometry, toolbar visibility, settings |
| `blocks.db.json` | Block registry (all blocks with id, name, content, tags, timestamps) |
| `prompts.db.json` | Prompt library (all prompts with id, name, content, category, timestamps) |

## Default Settings

| Setting | Default |
|---------|---------|
| Auto-scan on startup | Enabled |
| Syntax highlighting | Enabled |
| Markdown toolbar | Visible |
| Scan depth | Unlimited |
| Ignore patterns | `node_modules`, `.git`, `dist`, `build`, `__pycache__`, `.venv`, `venv`, `target`, `.build` |
| Trigger files | `CLAUDE.md`, `claude.md`, `.claude.md`, `AGENTS.md`, `agents.md`, `.agents.md`, `.git` |

## Layout

BlockSmith uses a 3-pane layout:

```
 NavPanel (left)  |  MainContent (center)  |  RightPane (right)
 Project tree     |  Editor or Preview     |  Blocks / Prompts
```

- **Left pane** — project tree with expand/collapse all, block usage highlighting, file management
- **Center pane** — markdown editor with formatting toolbar, line numbers, gutter markers, or rendered preview
- **Right pane** — tabbed panel for Blocks and Prompts

## Markdown Toolbar

The formatting toolbar sits above the editor and provides quick-access markdown formatting:

| Group | Buttons | Action |
|-------|---------|--------|
| Headers | H1 H2 H3 | Insert `#`, `##`, `###` at line start |
| Inline | **B** *I* ~~S~~ | Wrap selection with `**`, `*`, `~~` |
| Code | `` ` `` `{ }` | Inline code or fenced code block |
| Lists | bullet, numbered, checkbox | Insert `- `, `1. `, `- [ ] ` at line start |
| Insert | rule, quote, link, image, table | Insert markdown elements |

- Toggle toolbar visibility with the hamburger icon in the header bar
- Toolbar visibility persists across restarts
- All toolbar actions preserve undo history

## Editor Features

- **Auto-continue lists** — pressing Enter after a list item (`- `, `* `, `1. `, `- [ ] `) continues the list; pressing Enter on an empty list item removes it
- **Auto-close brackets** — typing `(`, `[`, `{`, or `` ` `` auto-inserts the closing character; if text is selected, wraps the selection
- **Tab indent / Shift+Tab outdent** — inserts or removes 4 spaces; works on multi-line selections
- **Current-line highlight** — subtle background highlight on the line where the cursor is
- **Dynamic gutter** — line number column width adjusts based on total line count
- **Duplicate line** — Ctrl+D duplicates the current line
- **Block status markers** — colored strips in the gutter show block sync status (green=synced, orange=diverged, blue=local)
- **Find & Replace** — undo-safe operations, scroll-to-match, case sensitivity toggle

## File Management

Right-click items in the project tree to access file operations:

| Menu Item | Available On | Action |
|-----------|-------------|--------|
| Open | Files | Open file in editor |
| New File... | Folders, Projects | Create a new .md file (auto-appends `.md`, writes `# Header`) |
| New Folder... | Folders, Projects | Create a new subdirectory |
| Rename... | Files, Folders | Rename with pre-filled current name |
| Duplicate | Files | Copy file with " copy" suffix |
| Cut | Files, Folders | Mark for move |
| Paste | Folders, Projects | Move cut item into this directory |
| Delete... | Files, Folders | Delete with confirmation dialog |
| Reveal in Explorer | All | Open containing folder in OS file manager |
| Copy Path | All | Copy full path to clipboard |
| Copy Name | All | Copy filename to clipboard |

Project roots cannot be renamed, cut, or deleted.

## Working with Blocks

1. **Create a block** — select text in the editor, right-click, choose "Add as Block"
2. **Edit a block** — click a block card in the right pane to open the editor popup
3. **Push** — update all files containing the block with the latest registry content
4. **Pull** — update the registry with content from a file (when the file version diverges)
5. **Diff** — view side-by-side differences when a block has diverged between registry and file
6. **Insert** — click the insert button on a block card to insert it at the cursor position
7. **Filter** — use the search bar or tag filter in the block panel
8. **Delete** — click Delete in the editor popup, then confirm (two-stage confirmation)

## Working with Prompts

1. **Create a prompt** — select text in the editor, right-click, choose "Create Prompt", or use the add button in the prompt panel
2. **Copy** — click the copy button on a prompt card to copy to clipboard
3. **Edit** — click a prompt card to open the editor popup
4. **Categories** — organize prompts by category, filter by category in the panel
5. **Delete** — click Delete in the editor popup, then confirm (two-stage confirmation)

## Context Menus

### Editor (right-click)
- Cut, Copy, Paste, Select All
- Add as Block
- Create Prompt

### Project Tree (right-click)
- Open
- New File..., New Folder...
- Rename..., Duplicate, Cut, Paste
- Delete...
- Reveal in Explorer
- Copy Path, Copy Name
