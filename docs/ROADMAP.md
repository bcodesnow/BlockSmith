# BlockSmith Roadmap

**Baseline:** Phases 1-12 complete. Fully functional markdown/JSON/YAML/JSONL editor with block sync, prompt library, export, navigation, file management, dark/light themes, font selection, word wrap toggle, and undo/redo toolbar.

---

## Current Format Support

| Format | Support | Edit | Preview | Toolbar | Blocks | Sync |
|--------|---------|------|---------|---------|--------|------|
| Markdown | Full | Yes | Yes | Yes | Yes | Yes |
| JSON | Full | Yes | — | Yes | — | — |
| YAML | Full | Yes | — | Yes | — | — |
| JSONL | Special | Viewer | — | — | — | — |
| PlainText (.txt) | Full | Yes | — | — | — | — |
| PDF (.pdf) | Read-only | — | WebEngine | — | — | — |

---

## Planned Formats

### ~~TXT (Text Files)~~ — Implemented

`.txt` files are discovered during project scans, editable in PlainText mode, and included in global search (toggleable in Settings > Projects).

### ~~PDF (Read-Only Viewer)~~ — Implemented

`.pdf` files are discovered during project scans and displayed read-only via Chromium's built-in PDFium renderer (WebEngineView). Zoom, page navigation, search, and thumbnails provided by the browser engine. Search toggle in Settings > Projects (default off — PDFs are binary).

### DOCX (Read-Only) — MEDIUM priority, ~2-3h

Render Word documents as formatted preview via pandoc.

**C++ (Document):**
- Add `FileType::Docx` enum, `.docx` extension check
- Add `PreviewKind::PreviewDocx`
- Use **pandoc** CLI (already optional dependency for export): `pandoc input.docx -t html`
- Binary file — set `m_rawContent` to placeholder message

**QML:**
- New `MdPreviewDocx.qml` (~30 LOC) reusing WebEngine preview pattern
- MainContent.qml: +5 LOC routing

**Dependencies:** pandoc (already optional), QProcess (already used)

**Path to full DOCX editing (future):** Use docx C++ library → parse content.xml + styles.xml → map to markdown → rezip on save. Effort: 2-3 weeks.

---

## Phase 13 — Multi-Tab Editor

Open multiple files simultaneously in a tab bar.

**Effort:** 1-2 weeks, ~250 LOC

### 13.1 Tab Bar
- TabBar above the editor area with closable tabs
- Each tab holds its own Document instance + editor state (cursor, scroll, undo)
- Middle-click or X button to close tab
- Ctrl+Tab / Ctrl+Shift+Tab to cycle tabs
- Drag-to-reorder tabs

### 13.2 State Management
- Refactor Document to support multiple instances
- Each tab tracks: file path, dirty state, cursor position, scroll offset, undo stack
- Tab tooltip shows full file path
- Dirty indicator (dot) on tab label

### 13.3 Integration
- Quick Switcher (Ctrl+P) switches to existing tab if file is already open
- Nav tree click switches to existing tab or opens new one
- Close tab shows Save/Discard/Cancel if dirty
- Ctrl+W closes current tab

### Technical Breakdown

**C++ (Document):**
- Currently singleton-like via `AppController.currentDocument`
- Change: support multiple Document instances
- Add Document factory or pool in AppController

**C++ (AppController/NavigationManager):**
- Track open tabs: `QMap<QString, Document*> m_openTabs`
- New `TabManager` class: owns tabs, handles switching, closing, dirty state
- Emit `currentTabChanged(QString filePath)` signal

**QML:**
- New `TabBar.qml` (~100 LOC): filename + dirty dot + close button
- Editor.qml: reparent TextArea to current tab's state, preserve per-tab state

**New files:** `src/tabmanager.h/.cpp` (~150 LOC), `qml/components/TabBar.qml` (~100 LOC)

---

## Phase 14 — Editor Enhancements

Quality-of-life improvements for daily editing.

### 14.1 Markdown Table Editor — ~1 week, ~140 LOC
- Detect cursor inside markdown table
- Tab to next cell, Shift+Tab to previous
- Toolbar buttons: add row, add column, delete row, delete column
- Auto-align pipe characters on edit

**C++:** `Document::isInTable(cursorPos)`, `getTableBounds()`, table rebuild methods (+80 LOC)
**QML:** Editor.qml table key handler + toolbar buttons (+60 LOC)

### 14.2 Spell Checking — ~2 weeks, ~280 LOC
- Integrate Hunspell or Windows spell check API
- Red squiggly underlines on misspelled words
- Right-click suggestions
- ConfigManager: `spellCheckEnabled`, `spellCheckLanguage`

**New files:** `src/spellchecker.h/.cpp` (~200 LOC), `qml/components/SpellCheckMenu.qml` (~50 LOC), Editor.qml +30 LOC

### 14.3 Minimap — ~3-4 days, ~140 LOC
- VS Code-style minimap scrollbar (scaled-down document view)
- Click/drag to navigate
- Toggle on/off in Settings

**New file:** `qml/components/Minimap.qml` (~120 LOC), Editor.qml +20 LOC

---

## Phase 15 — Block System Enhancements

Make blocks more powerful and visible.

### 15.1 Block Versioning
- Track block content history (last N versions with timestamps)
- Revert to previous version from block editor popup
- Store in blocks.db.json as `history` array

### 15.2 Block Templates
- Parameterized blocks with `{{variable}}` placeholders
- Prompt for variable values on insert
- Template variables defined in block metadata

### 15.3 Cross-Project Block Sync
- Push/pull blocks across different project directories
- Block registry acts as single source of truth
- Sync status visible per-project in block cards

### 15.4 Block Dependency Graph
- Visualize which files use which blocks
- Clickable graph (files to blocks relationships)
- Could use mermaid rendering (already bundled)

---

## Phase 16 — Git Integration

Source control awareness within the app.

### 16.1 Tree Status Indicators — ~1 week, ~150 LOC
- Show git status icons in project tree (modified, untracked, staged)
- Run `git status --porcelain` on scan and refresh
- Color-coded: green=added, orange=modified, red=deleted, grey=untracked

**New file:** `src/projecttreegit.h/.cpp` (~100 LOC)
**Changes:** ProjectTreeModel +30 LOC, NavPanel.qml +20 LOC

### 16.2 Diff View — ~2 weeks, ~320 LOC
- Side-by-side or inline diff for modified files
- Gutter diff markers (green/red strips for added/removed lines)
- Compare with HEAD or staged version

**New files:** `src/diffengine.h/.cpp` (~120 LOC), `qml/components/DiffView.qml` (~200 LOC)

### 16.3 Basic Git Operations — ~1 week, ~230 LOC
- Commit from within the app (message input + file selection)
- Stage/unstage files from context menu
- Branch display in status bar

**New files:** `src/gitmanager.h/.cpp` (~150 LOC), `qml/components/CommitDialog.qml` (~80 LOC)

---

## Phase 17 — Advanced Features

Bigger features for power users.

### 17.1 YAML Front Matter
- Parse YAML front matter (`---` delimited) in markdown files
- Display metadata in a collapsible header or sidebar section
- Exclude from preview body, include in export

### 17.2 Multiple Cursors
- Ctrl+Click to add cursors
- Ctrl+D to select next occurrence (like VS Code)
- All cursors type/delete simultaneously

### 17.3 Drag-and-Drop Reorder
- Drag headings in the Outline panel to reorder document sections
- Drag blocks in the right pane to reorder
- Visual drop indicators

### 17.4 Math / KaTeX Support
- Render `$...$` inline and `$$...$$` block math in preview
- Bundle KaTeX.min.js alongside mermaid.min.js
- Syntax highlighting for math blocks in editor

---

## Phase 18 — Distribution & Platform

Ship it.

### 18.1 Windows Installer
- NSIS or WiX installer with Start Menu shortcut, uninstaller
- Or: portable .zip distribution
- File association for .md files (optional, opt-in)

### 18.2 Cross-Platform Builds
- CI pipeline (GitHub Actions) for Windows, Linux, macOS
- Platform-specific packaging (AppImage, DMG)
- Test matrix across platforms

### 18.3 Auto-Updater
- Check for new versions on startup (configurable)
- Download + install flow or link to release page
- Version display in Settings / About

---

## Phase 19 — Extensibility

### 19.1 Plugin System
- User-defined toolbar actions or block processors
- Script-based (JS or Python) plugin loading
- Plugin settings in config

### 19.2 Custom Themes
- User-created theme files (JSON color definitions)
- Theme import/export
- Community theme sharing

---

## AI Features (Future)

### Local LLM Integration — ~2 weeks, ~300 LOC

**C++ (new LlmManager):**
- Connect to Ollama (localhost:11434) or llama.cpp local server
- Methods: `rephrase(text)`, `rewrite(text, style)`, `generateFromComments(code)`
- Use `QNetworkAccessManager` + JSON for API calls

**QML:**
- New button group in editor toolbar: Rephrase, Rewrite, Generate
- Loading spinner during LLM inference, replace selection with result or show diff

**New files:** `src/llmmanager.h/.cpp` (~200 LOC), `qml/components/LlmDialog.qml` (~100 LOC)

**Dependencies:** Ollama or llama.cpp running locally (user must install)

### Semantic Search
- Search blocks by meaning, not just text
- Requires embedding model (local or API)

### Code Generation
- Generate boilerplate from comments
- Template-aware generation

---

## Wishlist (Unscheduled Ideas)

Items not yet assigned to a phase:

- **Excel/CSV viewer** — table viewer with filtering
- **Extended thinking display** — collapse/expand Claude thinking blocks
- **Fuzzy outline** — search headings by name in real-time
- **Breadcrumb navigation** — show current heading path
- **Jump to definition** — click block name to open in registry
- **Persistent search history** — remember past searches
- **Project favorites** — pin frequently-used projects
- **Session restore** — remember open files between restarts
- **Command palette** (Ctrl+Shift+P) — quick actions
- **Incremental block indexing** — faster scans on large projects
- **Incremental search** — results appear as-you-type
- **Memory-mapped files** — handle 100MB+ files efficiently

---

## Adding New Formats

Architecture principles for extending format support:

1. **Extend Document.h enums:** Add to `FileType`, `SyntaxMode` (if editable), `ToolbarKind` (if toolbar needed), `PreviewKind` (if preview needed)
2. **Extend Document.cpp detection:** Add extension check in `fileType()`, add cases in `syntaxMode()`, `toolbarKind()`, `previewKind()`. Handle non-text formats (PDF, DOCX) — don't parse as text.
3. **Extend SyntaxHighlighter (if editable):** Add `Mode` enum value, add rules in `highlightBlock()`
4. **Create QML preview component (if previewable):** Follow existing pattern from `MdPreviewWeb.qml`
5. **Route in MainContent.qml:** Add case in preview Loader

No format exceeds 1256 LOC (the max file size) because responsibilities are split: format detection (Document), syntax highlighting (SyntaxHighlighter), preview (separate QML), toolbars (separate QML).

---

## Effort Summary

| Feature | Phase | Effort | LOC |
|---------|-------|--------|-----|
| ~~TXT Support~~ | — | Done | — |
| ~~PDF Viewer~~ | — | Done | — |
| DOCX Read-Only | — | 2-3h | 80 |
| Multi-Tab Editor | 13 | 1-2w | 250 |
| Table Editor | 14.1 | 1w | 140 |
| Spell Checking | 14.2 | 2w | 280 |
| Minimap | 14.3 | 3-4d | 140 |
| Git Tree Status | 16.1 | 1w | 150 |
| Diff View | 16.2 | 2w | 320 |
| Git Ops | 16.3 | 1w | 230 |
| Local LLM | Future | 2w | 300 |

---

## Recommended Next Steps

1. **Immediate:** Add TXT support (10 min)
2. **Soon:** PDF viewer (3-4h), start Phase 13
3. **Medium-term:** DOCX read-only, table editor, spell check
4. **Long-term:** Git integration, local LLM, block versioning
