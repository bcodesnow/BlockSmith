# BlockSmith Roadmap

**Updated:** 2026-02-26
**Baseline:** Phases 1-12 complete. Fully functional markdown/JSON/YAML/JSONL editor with block sync, prompt library, export, navigation, file management, dark/light themes, font selection, word wrap toggle, and undo/redo toolbar.

---

## Phase 12 — Code Quality

Address remaining findings from code audit (see [code-audit.md](code-audit.md)).

### 12.1 QML Refactoring — Complete
- Extracted `EditorPopupBase.qml` shared component (BlockEditorPopup + PromptEditorPopup)
- Split SettingsDialog.qml into SettingsProjectsTab, SettingsEditorTab, SettingsIntegrationsTab
- Split MainContent.qml — extracted EditorHeader, FileChangedBanner
- Split Editor.qml — extracted EditorContextMenu, ImageDropZone
- Split Main.qml — extracted UnsavedChangesDialog

### 12.2 Move Logic to C++ — Complete
- Fuzzy matching already in C++ (`AppController::fuzzyFilterFiles`) — no work needed
- Block range parsing already in C++ (`Document::computeBlockRanges`) — no work needed
- Find/replace properly split: FindReplaceController.qml + Document::findMatches in C++. Replace ops stay in QML to preserve TextArea undo stack.

### 12.3 Architecture — Complete
- Extracted NavigationManager (browser-style nav history + file opening) from AppController
- Extracted SearchManager (async file search + fuzzy filtering) from AppController
- AppController reduced to thin facade with forwarding calls (~260 LOC, down from ~515)
- `Result<T>` pattern deferred — low priority, current error handling adequate

---

## Phase 13 — Multi-Tab Editor

Open multiple files simultaneously in a tab bar.

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
- Ctrl+W closes current tab (already exists for single file)

---

## Phase 14 — Editor Enhancements

Quality-of-life improvements for daily editing.

### 14.1 Markdown Table Editor
- Detect cursor inside markdown table
- Tab to next cell, Shift+Tab to previous
- Toolbar buttons: add row, add column, delete row, delete column
- Auto-align pipe characters on edit

### 14.2 Spell Checking
- Integrate Hunspell or Windows spell check API
- Red squiggly underlines on misspelled words
- Right-click suggestions
- ConfigManager: `spellCheckEnabled`, `spellCheckLanguage`

### 14.3 Minimap
- VS Code-style minimap scrollbar (scaled-down document view)
- Click/drag to navigate
- Toggle on/off in Settings

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
- Clickable graph (files → blocks relationships)
- Could use mermaid rendering (already bundled)

---

## Phase 16 — Git Integration

Source control awareness within the app.

### 16.1 Tree Status Indicators
- Show git status icons in project tree (modified, untracked, staged)
- Run `git status --porcelain` on scan and refresh
- Color-coded: green=added, orange=modified, red=deleted, grey=untracked

### 16.2 Diff View
- Side-by-side or inline diff for modified files
- Gutter diff markers (green/red strips for added/removed lines)
- Compare with HEAD or staged version

### 16.3 Basic Git Operations
- Commit from within the app (message input + file selection)
- Stage/unstage files from context menu
- Branch display in status bar

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

## Summary

| Phase | Name | Effort | Priority |
|-------|------|--------|----------|
| **12** | Code Quality | Medium | High — technical debt |
| **13** | Multi-Tab Editor | Large | High — major UX upgrade |
| **14** | Editor Enhancements | Medium | Medium |
| **15** | Block System Enhancements | Medium | Medium |
| **16** | Git Integration | Medium-Large | Medium |
| **17** | Advanced Features | Large | Low-Medium |
| **18** | Distribution & Platform | Medium | Low (when ready to ship) |
| **19** | Extensibility | Large | Future |

Phases 12-13 are the natural next steps. The rest can be tackled in any order based on interest.
