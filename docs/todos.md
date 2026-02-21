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

## Reliability Hotfix Backlog (2026-02-21 review)
- [ ] Save-safe file switching: do not switch files if save fails
- [ ] Protect dirty buffer on rename/move of currently open file
- [ ] Move scan + sync index rebuild off UI thread, with progress/cancel
- [ ] JSONL load generation token: ignore stale worker chunks/signals
- [ ] Emit auto-save success only on confirmed save commit
- [ ] Deleted-file banner "Close" should clear/close document
- [ ] Decode dropped image URLs before copy (`%20`, unicode paths)

---

## Roadmap — Polished Markdown Editor

### Tier 1 — Core Polish (Table Stakes)

### GUI
Locale consistency for dialog buttons fixed (English UI locale forced).

Every serious markdown editor has these. Without them, users will bounce.
#### Export System
- [ ] **PDF Export** — Pandoc-based, customizable page margins/fonts, TOC option, code block styling
- [ ] **HTML Export** — Standalone HTML with embedded CSS, self-contained (no external deps)
- [ ] **DOCX Export** — Word-compatible via Pandoc, preserves headings/tables/code blocks
- [ ] **Export dialog** — Format picker, output path, preview before export
- [ ] **Export with custom CSS** — Apply theme/stylesheet to exported output
- [ ] **"Export & Overwrite Previous"** — Remember last export path, one-click re-export

#### Focus & Writing Modes
- [ ] **Focus Mode** — Dims/fades all paragraphs except the one under cursor (toggle via Ctrl+Shift+F11 or menu)
- [ ] **Typewriter Mode** — Keeps the cursor line vertically centered as you type (toggle via menu)
- [ ] **Zen Mode** — Fullscreen, hide all sidebars/toolbar/status bar, just the editor (F11 or Ctrl+Shift+Enter)
- [ ] **Combine modes** — Focus + Typewriter + Zen should compose together

#### Scroll Sync
- [x] **Editor ↔ Preview scroll sync** — Bidirectional via WebChannel ScrollBridge, debounced, anti-feedback-loop guard
- [x] **Sync on cursor move** — Preview scrolls to matching source line in editor (data-source-line mapping)
- [x] **Click-to-scroll** — Click a heading in preview, editor jumps to source (text-match fallback)

#### Outline / Document Map
- [ ] **Outline panel** — Hierarchical heading tree (H1-H6) in left sidebar or as a tab in RightPane
- [ ] **Click to jump** — Click any heading to scroll editor + preview to that section
- [ ] **Current heading highlight** — Outline tracks cursor position and highlights active section
- [ ] **`[TOC]` support** — Render auto-generated table of contents in preview

#### Image Handling
- [x] **Paste image from clipboard** — Ctrl+V an image, auto-save to configurable subfolder, insert markdown link
- [x] **Drag & drop image** — Drop image file onto editor, copy to project, insert link
- [ ] **Image preview in editor** — Show inline image thumbnails (optional)
- [x] **Image path config** — Settings for where pasted/dropped images are saved (relative path)

#### Theme System
- [ ] **Light theme** — Clean light color scheme (currently dark-only)
- [ ] **5-8 built-in themes** — Solarized Dark/Light, Nord, Dracula, GitHub, One Dark, Gruvbox, Tokyo Night
- [ ] **Theme switcher** — Settings dropdown or Ctrl+K Ctrl+T to switch themes
- [ ] **Custom preview CSS** — User can provide custom CSS for the preview pane
- [ ] **Editor font selection** — Choose editor font family and size from settings
- [ ] **Theme applies to everything** — Editor, preview, sidebar, toolbar, dialogs all follow theme

#### Status Bar Enhancements
- [x] **Reading time** — Estimated reading time (words / 225 wpm) displayed in status bar
- [x] **Auto-save indicator** — Visual dot/icon showing save state (saved / unsaved / saving)
- [x] **Encoding display** — Show file encoding (UTF-8, UTF-8 BOM, UTF-16 LE/BE)

#### Auto-Save
- [x] **Timed auto-save** — Configurable interval (default 30s), saves if document has changes
- [x] **Auto-save on focus loss** — Save when switching away from BlockSmith
- [x] **Auto-save toggle** — Enable/disable in settings
- [x] **Visual feedback** — Subtle "Auto-saved" indicator in status bar

#### Quick Switcher
- [ ] **Ctrl+P quick open** — Fuzzy search across all project files, instant navigation
- [ ] **Recent files list** — Show recently opened files at top of switcher
- [ ] **File preview on hover** — Show first few lines of file in switcher popup

#### JSONL Viewer
- [x] **Read-only JSONL viewer** — Opens when clicking .jsonl in tree, replaces editor area with dedicated viewer
- [x] **Async loading** — Background thread with chunked parsing, progress indicator
- [x] **Role-based filtering** — Pill toggles for user/assistant/system/tool roles (Claude transcript aware)
- [x] **Text search + tool_use filter** — Search across JSON content, toggle to show only tool-use entries
- [x] **Expandable entries** — Collapsed cards with preview, click to expand full pretty-printed JSON
- [x] **Copy entry** — Per-entry clipboard button with toast notification

---

### Tier 2 — Differentiating Features

These separate a good editor from a great one. Users switch editors for these.

#### Table Editor
- [ ] **Visual table editing** — Click into cells, type to edit, Tab to move between cells
- [ ] **Add/remove rows & columns** — Context menu or toolbar buttons
- [ ] **Column alignment** — Left/center/right via click
- [ ] **Table creation wizard** — Specify rows x columns, generates markdown table
- [ ] **CSV/TSV paste** — Paste tabular data, auto-convert to markdown table
- [ ] **Sort columns** — Click header to sort

#### Math / LaTeX
- [ ] **KaTeX rendering** — `$inline$` and `$$block$$` math rendering in preview
- [ ] **Math toolbar** — Common symbols, fractions, matrices via toolbar buttons
- [ ] **Syntax highlighting for math** — Distinct coloring for LaTeX blocks in editor

#### Multiple Tabs
- [ ] **Tab bar** — Open multiple documents in tabs above the editor
- [ ] **Tab management** — Close, close others, close all, reorder by drag
- [ ] **Unsaved indicator** — Dot on tab for unsaved changes
- [ ] **Ctrl+Tab switching** — Cycle through open tabs
- [ ] **Tab persistence** — Remember open tabs across sessions

#### Split Editor
- [ ] **Side-by-side editing** — Open two documents in horizontal/vertical split
- [ ] **Block reference editing** — Edit block source and usage file side by side
- [ ] **Diff view** — Compare two files with inline diff highlighting

#### Presentation Mode
- [ ] **Slide rendering** — `---` separators create slides, render as presentation
- [ ] **Fullscreen slideshow** — Arrow keys to navigate, Escape to exit
- [ ] **Slide themes** — Dark/light/custom slide styles
- [ ] **Speaker notes** — `<!-- notes: ... -->` rendered in presenter view

#### Print Support
- [ ] **Print dialog** — Native OS print with proper formatting
- [ ] **Print preview** — See how the document will look before printing
- [ ] **Page break control** — `<!-- pagebreak -->` inserts page break

#### EPUB Export
- [ ] **E-book export** — Generate EPUB from markdown via Pandoc
- [ ] **Cover image** — Optional cover for EPUB
- [ ] **Metadata** — Author, title, description for EPUB/PDF

#### Spell Check
- [ ] **Inline spell check** — Red squiggly underlines for misspelled words
- [ ] **Dictionary support** — Multiple languages, custom dictionary for technical terms
- [ ] **Suggestions popup** — Right-click for spelling suggestions
- [ ] **Ignore/add to dictionary** — Per-word actions

---

### Tier 3 — Power User Features

These build loyalty. Power users become advocates.

#### Bidirectional Links
- [ ] **`[[WikiLinks]]`** — Type `[[` to link to another file in the project
- [ ] **Auto-complete** — File name suggestions as you type inside `[[`
- [ ] **Backlinks panel** — Show all files that link to the current document
- [ ] **Hover preview** — Hover over a `[[link]]` to see target file preview

#### Graph View
- [ ] **Note graph** — Visual network of linked notes (nodes + edges)
- [ ] **Interactive** — Click nodes to navigate, zoom/pan, filter by folder
- [ ] **Local graph** — Show connections for current file only

#### Git Integration
- [ ] **Git status in tree** — Modified/added/deleted indicators on files in NavPanel
- [ ] **Basic git operations** — Commit, push, pull from within BlockSmith
- [ ] **Diff view** — Show uncommitted changes inline
- [ ] **Branch indicator** — Current branch name in status bar

#### Snippets / Text Expansion
- [ ] **User snippets** — Define reusable text templates with tab stops
- [ ] **Trigger prefix** — Type prefix + Tab to expand snippet
- [ ] **Variables** — `{{date}}`, `{{filename}}`, `{{cursor}}` placeholders
- [ ] **Snippet manager** — UI to create/edit/delete snippets

#### Tags System
- [ ] **`#tag` detection** — Index all tags across project files
- [ ] **Tag panel** — Browse all tags, click to filter/search
- [ ] **Tag auto-complete** — Suggest existing tags as you type `#`

#### Citation Manager
- [ ] **BibTeX support** — Load .bib files, insert citations with `[@key]`
- [ ] **Citation auto-complete** — Suggest citations as you type
- [ ] **Bibliography generation** — Auto-generate reference list in preview

#### File Watcher
- [ ] **QFileSystemWatcher** — Detect external file changes
- [ ] **Reload prompt** — Ask user to reload when file changed externally
- [ ] **Auto-reload option** — Configurable auto-reload for external changes

---

### Tier 4 — Modern / AI-Era Features

The next generation of editors will have these. Early adoption = differentiation.

#### AI Writing Assistant
- [ ] **AI summarize** — Select text, summarize via LLM
- [ ] **AI expand** — Expand bullet points into paragraphs
- [ ] **AI rewrite** — Rewrite selection in different tone/style
- [ ] **AI grammar check** — Grammar and style suggestions
- [ ] **Configurable provider** — OpenAI, Anthropic, local models (Ollama)
- [ ] **API key management** — Secure key storage in settings

#### AI Block Suggestions
- [ ] **Smart block insert** — AI suggests relevant blocks from library based on current document context
- [ ] **Block search by intent** — Describe what you need, AI finds matching blocks

#### Smart Formatting
- [ ] **Paste as markdown** — Paste rich text (from web, Word), auto-convert to markdown
- [ ] **Table from text** — Select text, AI generates markdown table
- [ ] **List cleanup** — AI normalizes inconsistent list formatting

---

## Existing Pending Items

Carried over from previous roadmap:

- [x] File watcher (QFileSystemWatcher) — shipped in Phase 8
- [ ] Prompt template variables ({{project}}, {{date}}) — see Tier 3 Snippets
- [ ] Export/Import blocks DB
- [x] Splitter size persistence — shipped in Phase 7
- [ ] Block auto-discovery
- [ ] Git-aware status indicators — see Tier 3 Git
- [x] Split view mode (edit left, preview right) — shipped with WebEngine preview + mermaid
- [ ] Multi-tab editor — see Tier 2

---

## Ideas — Future Vision

### Multi-Agent Format Support
- [ ] Support .cursorrules, .github/copilot-instructions.md, .windsurfrules, .clinerules, AGENTS.md
- [ ] Same block deployed to Claude, Cursor, Copilot, Windsurf simultaneously
- [ ] Format-aware export (adapt block content per agent format)

### Well-Known Tool Locations
- [ ] "Known Tools" section in Settings with toggleable entries (Claude Code, Cursor, Windsurf, etc.)
- [ ] Each resolves its data folder path automatically
- [ ] Extensible — new tools can be added without code changes

### Auto-Detect Tool Folders
- [ ] On first launch or scan, detect known tool folders (~/.claude, ~/.cursor, etc.)
- [ ] Show one-time dialog: "BlockSmith detected Claude Code data. Include it?"
- [ ] Store decision, don't re-prompt
- [ ] Nice onboarding experience for new users

### Claude Skills Integration
- [ ] Export prompts as Claude Code custom slash commands
- [ ] Prompts → skills pipeline (manage in BlockSmith, use via `/` in Claude Code)
- [ ] Sync skill definitions
- [ ] Import existing Claude skills as prompts

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

### Auto-Updater
- [ ] Check GitHub Releases API on startup for new version
- [ ] Show toast notification when update available
- [ ] Download zip in background with progress indicator
- [ ] Extract and replace exe, prompt user to restart
- [ ] Version comparison logic (semver)

### Team / Cloud Sync
- [ ] Shared block registry via Git repo
- [ ] Optional cloud backend for team sync
- [ ] Role-based block management (lead updates, team receives)

### Plugin / Extension System
- [ ] Plugin API — define hooks for editor events (save, open, render, export)
- [ ] Plugin manager UI — install/enable/disable/update plugins
- [ ] Community plugin repository
- [ ] Example plugins: word frequency, reading level, custom exporters
