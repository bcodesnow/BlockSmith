# BlockSmith TODO

## Completed
- [x] Auto-scan on startup (optional in settings)
- [x] Markdown syntax highlighting (optional in settings, C++ QSyntaxHighlighter)
- [x] Find & Replace in editor (Ctrl+F / Ctrl+H), undo-safe, scroll-to-match
- [x] Fix BlockCard hover flicker
- [x] Right-click context menu in editor (Cut/Copy/Paste/Select All + Add as Block + Create Prompt)
- [x] Right-click context menu on tree (Open, New File, New Folder, Rename, Duplicate, Cut, Paste, Delete, Reveal in Explorer, Copy Path, Copy Name)
- [x] Word/char/line count in status bar
- [x] Block usage stats (file count on each block card)
- [x] Line numbering fix (wrap-aware gutter heights)
- [x] Theme singleton (shared design tokens across all 21 QML files)
- [x] MdDocument error signals (loadFailed, saveFailed) + toast notifications
- [x] Unsaved changes check (Save/Discard/Cancel dialog on file switch)
- [x] Delete confirmation for blocks/prompts (two-stage button)
- [x] Cursor:pointer sweep (all clickable MouseAreas)
- [x] Shared preview CSS (Theme.previewCss — tables, hr, images, code blocks, lists)
- [x] Compiler warnings (-Wall -Wextra -Wpedantic, zero warnings)
- [x] Debounce editor computations (lineHeights, blockRanges — 100ms timers)
- [x] Quick fixes batch (dead code removal, auto-focus, Enter-to-submit, hover states, tooltips, Shift+Enter find-previous)
- [x] File management (create, rename, delete, duplicate, cut/paste via FileManager C++ class + NavPanel context menu)
- [x] Markdown formatting toolbar (H1-H3, Bold, Italic, Strikethrough, Code, Code Block, Bullet/Numbered/Task Lists, Link, Image, Table, HR, Blockquote)
- [x] Toolbar toggle + persistence (ConfigManager.markdownToolbarVisible)
- [x] Editor keyboard shortcuts (Ctrl+B bold, Ctrl+I italic, Ctrl+Shift+K code, Ctrl+D duplicate line)
- [x] Tab/Shift+Tab indent/outdent (4 spaces, multi-line selection support)
- [x] Auto-continue lists on Enter (bullet, numbered, checkbox — removes empty items)
- [x] Auto-close brackets/backticks ((), [], {}, `` — wraps selection)
- [x] Current-line background highlight
- [x] Dynamic gutter width (adjusts to line count)
- [x] New project dialog (folder picker + trigger file selection)
- [x] Global search (Ctrl+Shift+F, searches across all project files)

## Pending
- [ ] Multi-tab editor
- [ ] File watcher (QFileSystemWatcher)
- [ ] Prompt template variables ({{project}}, {{date}})
- [ ] Export/Import blocks DB
- [ ] Recently opened files list
- [ ] Splitter size persistence
- [ ] Auto-save timer
- [ ] Block auto-discovery
- [ ] Git-aware status indicators

## Ideas — Future Vision

### Multi-Agent Format Support
- [ ] Support .cursorrules, .github/copilot-instructions.md, .windsurfrules, .clinerules, AGENTS.md
- [ ] Same block deployed to Claude, Cursor, Copilot, Windsurf simultaneously
- [ ] Format-aware export (adapt block content per agent format)

### Claude Skills Integration
- [ ] Export blocks as Claude Code custom slash commands
- [ ] Blocks → skills pipeline (manage in BlockSmith, use via `/` in Claude Code)
- [ ] Sync skill definitions with block updates
- [ ] Import existing Claude skills as blocks

### Block Marketplace / Community Sharing
- [ ] Export/import block collections as portable .blocksmith.json packs
- [ ] Community block pack repository (GitHub-based or dedicated)
- [ ] "Download the Clean Code pack", "Team CLAUDE.md starter kit"
- [ ] Rating/popularity system for shared packs

### Project Templates
- [ ] `blocksmith init` — scaffold a new project with chosen block preset
- [ ] Template presets (e.g. "Python project", "Rust project", "Full-stack")
- [ ] Custom template creation from existing projects

### CLI Companion
- [ ] Headless `blocksmith sync` / `blocksmith push` / `blocksmith lint`
- [ ] Pre-commit hook support (warn about diverged blocks)
- [ ] CI integration (check all blocks in sync)

### IDE Extension
- [ ] VS Code sidebar showing block status for current file
- [ ] Inline block markers in editor gutter
- [ ] Quick insert block from command palette

### Block Versioning
- [ ] Track block revision history
- [ ] Diff between block versions
- [ ] Rollback to previous version

### Auto-Updater (Medium)
- [ ] Check GitHub Releases API on startup for new version
- [ ] Show toast notification when update available
- [ ] Download zip in background with progress indicator
- [ ] Extract and replace exe, prompt user to restart
- [ ] Version comparison logic (semver)

### Team / Cloud Sync
- [ ] Shared block registry via Git repo
- [ ] Optional cloud backend for team sync
- [ ] Role-based block management (lead updates, team receives)
