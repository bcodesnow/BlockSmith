# BlockSmith TODO

## Completed
- [x] Auto-scan on startup (optional in settings)
- [x] Markdown syntax highlighting (optional in settings, C++ QSyntaxHighlighter)
- [x] Find & Replace in editor (Ctrl+F / Ctrl+H)
- [x] Fix BlockCard hover flicker
- [x] Right-click context menu in editor (Cut/Copy/Paste/Select All + Add as Block + Create Prompt)
- [x] Right-click context menu on tree (Open, Reveal in Explorer, Copy Path, Copy Name)
- [x] Word/char/line count in status bar
- [x] Block usage stats (file count on each block card)
- [x] Line numbering fix (wrap-aware gutter heights)

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

### Team / Cloud Sync
- [ ] Shared block registry via Git repo
- [ ] Optional cloud backend for team sync
- [ ] Role-based block management (lead updates, team receives)
