# User Manual

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Ctrl+S | Save current document |
| Ctrl+R | Reload current document |
| Ctrl+E | Cycle view mode: Edit → Split → Preview |
| Ctrl+V | Paste image from clipboard (when clipboard has image) |
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
| Ctrl+P | Quick Switcher: fuzzy file finder |
| Ctrl+Shift+E | Export document (PDF / HTML / DOCX) |
| Ctrl+W | Close current file |
| Ctrl+Q | Quit application |
| Ctrl+= / Ctrl++ | Zoom in (max 200%) |
| Ctrl+- | Zoom out (min 50%) |
| Ctrl+0 | Reset zoom to 100% |
| Ctrl+MouseWheel | Zoom in/out |
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
| Image subfolder | `images` |
| Status bar: word count | Enabled |
| Status bar: char count | Enabled |
| Status bar: line count | Enabled |
| Status bar: reading time | Enabled |
| Include Claude Code folder | Disabled |
| Ignore patterns | `node_modules`, `.git`, `dist`, `build`, `__pycache__`, `.venv`, `venv`, `target`, `.build` |
| Trigger files | `CLAUDE.md`, `claude.md`, `.claude.md`, `AGENTS.md`, `agents.md`, `.agents.md`, `.git` |

## Startup

On launch, BlockSmith shows a splash overlay with the app logo, a spinner, and status text while scanning projects. The splash fades out smoothly once scanning completes (with a minimum 600ms display to avoid flashing). If no search paths are configured, the splash dismisses immediately after loading.

## Layout

BlockSmith uses a 3-pane layout:

```
 NavPanel (left)  |  MainContent (center)  |  RightPane (right)
 Project tree     |  Editor / Split / Preview  |  Blocks / Prompts / Outline
```

- **Left pane** — project tree with expand/collapse all, block usage highlighting, file management
- **Center pane** — three view modes:
  - **Edit** — markdown editor with formatting toolbar, line numbers, gutter markers
  - **Split** — editor left + WebEngine preview right (side-by-side, scroll synced)
  - **Preview** — full WebEngine preview with mermaid diagram rendering
- **Right pane** — tabbed panel for Blocks, Prompts, and Outline

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
- **External change detection** — a file watcher monitors the open file for changes made by other editors or tools:
  - If the document has no unsaved edits, it reloads silently
  - If the document has unsaved edits, a banner appears: *"File changed on disk."* with **Reload** (discard local edits) and **Ignore** (keep editing) buttons
  - If the file is deleted from disk, a banner appears: *"File was deleted from disk."* with a **Close** button

## Image Handling

- **Paste from clipboard** — Ctrl+V when clipboard has an image saves it to the configured subfolder (default: `images/`) relative to the document and inserts a markdown image link
- **Drag & drop** — drop image files from the file explorer onto the editor to copy and insert
- **Visual feedback** — translucent overlay appears when dragging images over the editor
- **Configurable subfolder** — set the image save directory in Settings (relative to document)
- **Auto-create directories** — the image subfolder is created automatically if it doesn't exist
- **Preview support** — relative image paths are resolved to absolute `file://` URLs in the WebEngine preview
- **Supported formats** — PNG, JPG, JPEG, GIF, SVG, WebP, BMP

## Status Bar

The status bar at the bottom of the editor shows:

- **Save-state dot** — green when saved, gold when unsaved (flashes on save)
- **Cursor position** — `Ln X, Col Y` (edit/split mode) or `Preview mode`
- **Encoding** — detected file encoding (UTF-8, UTF-8 BOM, UTF-16 LE/BE)
- **Document stats** — configurable: word count, character count, line count, reading time

All status bar stats can be toggled individually in Settings.

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

Block cards in the right pane show an **orange left border** when the block content in any file has diverged from the registry. This provides at-a-glance visibility of blocks that need attention (push or pull).

## Working with Prompts

1. **Create a prompt** — select text in the editor, right-click, choose "Create Prompt", or use the add button in the prompt panel
2. **Copy** — click the copy button on a prompt card to copy to clipboard
3. **Edit** — click a prompt card to open the editor popup
4. **Categories** — organize prompts by category, filter by category in the panel
5. **Delete** — click Delete in the editor popup, then confirm (two-stage confirmation)

## Quick Switcher (Ctrl+P)

Press **Ctrl+P** to open the Quick Switcher — a fuzzy file finder for rapidly navigating between project files.

- **Fuzzy search** — type a few characters to filter all project files by name (substring and character-order matching)
- **Recent files** — when the query is empty, the last 10 opened files are shown
- **Keyboard navigation** — Up/Down arrows to select, Enter to open, Esc to close
- **Mouse** — hover to highlight, click to open
- **Path display** — each result shows the filename (bold) and directory path (muted)

## Outline Panel

The **Outline** tab in the right pane shows the heading structure of the current document.

- **Heading hierarchy** — H1 through H6 headings parsed from the document, indented by level
- **Click to navigate** — click any heading to scroll the editor to that line
- **Active heading** — the heading corresponding to the current cursor position is highlighted with an accent bar
- **Live updates** — the outline refreshes as you type (300ms debounce)
- **Code block aware** — headings inside fenced code blocks are excluded

## JSON Editor

BlockSmith supports editing `.json` files directly. Click any `.json` file in the project tree to open it.

- **Syntax highlighting** — keys (blue), string values (green), numbers (orange), booleans/null (purple), brackets (muted)
- **Format JSON** — click the toolbar button to prettify minified or compact JSON (uses Qt's QJsonDocument for valid JSON formatting)
- **Edit-only mode** — Split and Preview modes are disabled for JSON files; the Edit/Split/Preview toggle is hidden
- **Save** — Ctrl+S works as normal; encoding and file watcher behave the same as for markdown files

If the JSON is invalid, the Format button shows a toast: "Invalid JSON — cannot format".

## JSONL Transcript Viewer

BlockSmith includes a built-in viewer for `.jsonl` transcript files — the format used by Claude Code to log conversations. Click any `.jsonl` file in the project tree to open it.

### Features

- **Role badges** — color-coded by message role: user (blue), assistant (green), system (gold), tool (purple), progress (muted), error (red)
- **Content previews** — each entry shows a 2-line preview extracted from the message content, with emoji indicators for block types:
  - Text content shown directly
  - `tool_use` — tool name + first argument
  - `tool_result` — result content (errors marked with red indicator)
  - `thinking` — extended thinking preview
  - `redacted_thinking` — marked as redacted
  - `image`, `document` — media type / title
  - `server_tool_use`, `web_search_tool_result` — server tools and search queries
- **Filters** — role dropdown, text search, tool-use-only toggle
- **Expand** — click any entry to expand and view the full formatted JSON
- **Copy** — hover to reveal a copy button for the raw JSON of any entry
- **Stats** — total and filtered entry counts displayed in the header

### Claude Code Integration

Enable **Settings > Integrations > Include Claude Code folder** to add your `~/.claude` directory to the project tree. This gives you direct access to Claude Code's conversation transcripts, project configs, and other internal files.

The viewer's content block parsing follows the [Claude Messages API spec](https://docs.anthropic.com/en/api/messages). If Anthropic adds new content block types in the future, the parser in `src/jsonlstore.cpp` can be updated accordingly.

## Exporting Documents

Export the current markdown document to PDF, HTML, or DOCX via **Ctrl+Shift+E**.

### Formats

| Format | Engine | Notes |
|--------|--------|-------|
| **PDF** | QWebEnginePage::printToPdf() | Pixel-perfect output matching the preview. A4 page, 15mm margins. |
| **HTML** | md4c + standalone template | Dark theme CSS embedded. Relative images resolved to absolute paths. |
| **DOCX** | Pandoc (external) | Requires [pandoc](https://pandoc.org/installing.html) installed on the system. Disabled with warning if not found. |

### Workflow

1. Open a markdown file
2. Press **Ctrl+Shift+E** (or use the menu)
3. Select format: PDF (default), HTML, or DOCX
4. Choose font size: Small, Medium (default), or Large
5. Review the output path (defaults to same directory as source, with matching extension)
6. Optionally browse to a different output location
7. Toggle "Open file after export" (enabled by default)
8. Click **Export**
9. A spinner shows during export; toast notification on completion
10. If "Open file after export" is checked, the file opens in your system's default app

### Notes

- Exports use the current editor content (including unsaved changes), not the on-disk version
- PDF export renders through Chromium (same engine as the preview), so the output matches what you see
- DOCX export passes the source `.md` file to pandoc, so unsaved changes are **not** included — save first

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
