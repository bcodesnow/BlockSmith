# Storage and Data

## Config Location

All app data is stored in `QStandardPaths::AppConfigLocation`.

Typical locations:

- Windows: `%LOCALAPPDATA%\BlockSmith`
- Linux: `~/.local/share/BlockSmith`
- macOS: `~/Library/Application Support/BlockSmith`

## Stored Files

| File | Purpose |
|------|---------|
| `config.json` | User preferences and UI state |
| `blocks.db.json` | Reusable block registry |
| `prompts.db.json` | Prompt library |
| `session.json` | Open tabs and active-tab restore state |

## Block Markup in Markdown

```markdown
<!-- block: block-name [id:abcdef] -->
Block content
<!-- /block:abcdef -->
```

## Session Data

Session persistence includes open tab paths, active tab index, and per-tab UI state (view mode, cursor position, scroll position, pinned state).

## Search and Indexing Scope

- Scanner indexes: `.md`, `.markdown`, `.json`, `.yaml`, `.yml`, `.jsonl`, `.txt`, `.pdf`, `.docx`
- Block indexing is markdown-only (`.md`, `.markdown`)
