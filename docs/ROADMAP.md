# BlockSmith Roadmap

**Date:** 2026-02-23
**Baseline:** All 6 phases complete + JSONL viewer, scroll sync, zoom, robustness audit

---

## Phase 7 — Housekeeping & Quick Wins ✓

Small fixes that improve polish without new features. **Completed 2026-02-21.**

### 7.1 Locale Fix
- Force English UI locale for `Dialog.Cancel` / `Dialog.Save` button text
- Add `QLocale::setDefault(QLocale::English)` before QGuiApplication in main.cpp
- Alternatively: set `LC_ALL=C` or use custom button text in QML dialogs
- **Files:** src/main.cpp (1 line)

### 7.2 Splitter Size Persistence
- Save SplitView preferred widths to ConfigManager on window close
- Restore on startup
- **Properties:** `splitLeftWidth`, `splitRightWidth` (ints, pixels)
- **Files:** src/configmanager.h/.cpp (2 properties + load/save), qml/Main.qml (bind SplitView.preferredWidth, save onClosing)

### 7.3 data-source-line Injection (Scroll Sync Phase 4)
- Post-process md4c HTML output to inject `data-source-line="N"` on block-level elements
- Add `renderWithLineMap()` to Md4cRenderer — regex-based tag annotation with forward line matching
- Switch MdPreviewWeb.pushContent() to use it
- JS `scrollToLine()` already exists and handles the attributes
- **Result:** Accurate cursor-to-preview sync instead of percentage fallback
- **Files:** src/md4crenderer.h/.cpp, qml/components/MdPreviewWeb.qml
- **Design:** Implemented — bidirectional scroll sync with data-source-line mapping

---

## Phase 8 — File Safety ✓

Features that prevent data loss and keep content fresh. **Completed 2026-02-21.**

### 8.1 File Watcher
- Add QFileSystemWatcher to MdDocument — watch the currently open file
- On external change: emit `fileChangedExternally()` signal
- QML shows a non-modal banner: "File changed on disk. [Reload] [Ignore]"
- If document is unmodified: auto-reload silently
- If document has unsaved changes: show the banner, let user decide
- Watch/unwatch on file open/close
- **Files:** src/mddocument.h/.cpp (QFileSystemWatcher member, signals), qml/components/MainContent.qml (banner UI)

### 8.2 Auto-Save
- ConfigManager: `autoSaveEnabled` (bool, default false), `autoSaveInterval` (int, default 30 seconds)
- Timer in MdDocument: if enabled + document modified, call save()
- Save on window focus loss (QGuiApplication::applicationStateChanged → Inactive)
- Status bar: subtle "Auto-saved" flash via existing toast or inline label
- Settings dialog: checkbox + interval spinner
- **Files:** src/configmanager.h/.cpp (2 properties), src/mddocument.h/.cpp (QTimer, focus slot), qml/components/SettingsDialog.qml (UI), qml/components/MainContent.qml (status indicator)

---

## Phase 8.5 — Reliability Hardening ✓

Critical correctness and startup-flow fixes discovered in the 2026-02-21 full review. **Completed 2026-02-21.**

### 8.5.1 Save-Safe File Switching
- Prevent navigation when save fails in the unsaved-changes flow
- Only call file switch after a confirmed successful save
- **Files:** qml/Main.qml, src/mddocument.h/.cpp

### 8.5.2 Dirty-Buffer Protection During Rename/Move
- If currently opened file is modified, block rename/move or require Save/Discard/Cancel
- Avoid silent reload that discards unsaved in-memory edits
- **Files:** src/filemanager.cpp, qml/components/FileOperationDialog.qml, qml/Main.qml

### 8.5.3 Async Scan + Index Pipeline
- Move project scan and index rebuild off the UI thread
- Keep splash/progress responsive and cancellable
- Emit stage progress: scanning, indexing, complete
- **Files:** src/projectscanner.h/.cpp, src/appcontroller.h/.cpp, qml/Main.qml, qml/components/SplashOverlay.qml

### 8.5.4 JSONL Worker Isolation
- Add cancellation token / generation id per load
- Drop stale `chunkReady` / `finished` signals from previous worker runs
- **Files:** src/jsonlstore.h/.cpp

### 8.5.5 Truthful Auto-Save State
- Emit auto-save success only when `save()` actually commits
- Keep status indicator aligned with real save outcome
- **Files:** src/mddocument.h/.cpp, src/appcontroller.cpp, qml/components/MainContent.qml

### 8.5.6 Deleted-File Banner Action
- Make "Close" actually close/clear the current document when file is missing
- **Files:** qml/components/MainContent.qml

### 8.5.7 Drop URL Path Decoding
- Decode dropped file URL paths before copy (spaces/unicode-safe)
- **Files:** qml/components/MdEditor.qml

---

## Phase 9 — Navigation & Productivity ✓

Features that speed up daily workflows. **Completed 2026-02-23.**

### 9.1 Quick Switcher (Ctrl+P)
- Popup dialog with fuzzy-match text field
- Source: all files from AppController::getAllFiles() (tree walk, .md + .jsonl + .json)
- Fuzzy matching: score by substring position + consecutive chars (JS, no external lib)
- ListView of results, keyboard navigable (Up/Down/Enter/Esc)
- Opens file on Enter, closes on Esc
- Recent files: last 10 opened files in ConfigManager, shown when query is empty
- **Files:** qml/components/QuickSwitcher.qml (new), qml/Main.qml, src/configmanager.h/.cpp, src/appcontroller.h/.cpp

### 9.2 Outline Panel
- New "Outline" tab in RightPane (alongside Blocks / Prompts)
- Parses headings from current document (regex: `^#{1,6}\s+(.*)`, skips fenced code blocks)
- Indented heading list showing H1-H6 nesting
- Click to scroll editor to that heading
- Current heading highlighted based on cursor position (accent left bar)
- **Files:** qml/components/OutlinePanel.qml (new), qml/components/RightPane.qml, qml/components/MainContent.qml

---

## Phase 10 — Export System ✓

Generate standalone output files from markdown documents. **Completed 2026-02-22.**

### 10.1 HTML Export
- Standalone .html with embedded CSS (dark theme, matches preview)
- md4c renders markdown → HTML, wrapped in full HTML5 document template with inline styles
- Relative image paths resolved to absolute `file:///` URLs using document directory
- Atomic write via QSaveFile
- **Files:** src/exportmanager.h/.cpp

### 10.2 PDF Export
- QWebEnginePage::printToPdf() — offscreen Chromium renderer for pixel-perfect output
- A4 page size, 15mm margins (QPageLayout)
- Loads the same standalone HTML as HTML export, renders via WebEngine
- Async: loadFinished → printToPdf → pdfPrintingFinished signal chain
- **Files:** src/exportmanager.h/.cpp

### 10.3 DOCX Export (Pandoc)
- Shells out to pandoc via QProcess (async)
- Gracefully degrades: if pandoc not found, radio button disabled with "(pandoc not found)" label
- **Files:** src/exportmanager.h/.cpp

### 10.4 Export Dialog
- Format picker: PDF (default) / HTML / DOCX radio buttons
- Output path TextField pre-filled with default path, browse button opens FileDialog
- BusyIndicator during export, error label for failures
- Keyboard shortcut: Ctrl+Shift+E
- **Files:** qml/components/ExportDialog.qml (new), qml/Main.qml (Shortcut + instance)

---

## Phase 11 — Theme System

### 11.1 Light Theme
- Create Theme color sets as JS objects (dark, light)
- ConfigManager: `theme` (string, "dark" / "light", default "dark")
- Theme.qml switches color properties based on active theme
- Preview CSS: generate matching light/dark stylesheet
- **Files:** qml/components/Theme.qml (refactor to support sets), src/configmanager.h/.cpp (theme property), resources/preview/index.html (light CSS variant)

### 11.2 Theme Switcher
- Settings dropdown for theme selection
- Ctrl+K Ctrl+T shortcut (chord) to toggle themes
- **Files:** qml/components/SettingsDialog.qml, qml/Main.qml

### 11.3 Editor Font Selection
- ConfigManager: `editorFontFamily` (string, default "Consolas")
- Settings dropdown listing monospace system fonts
- Theme.fontMono binds to config value
- **Files:** src/configmanager.h/.cpp, qml/components/Theme.qml, qml/components/SettingsDialog.qml

---

## Summary

| Phase | Name | Items | Effort | Dependencies |
|-------|------|-------|--------|-------------|
| **7** | Housekeeping | Locale, splitter persist, scroll sync accuracy | Small | ✓ Done |
| **8** | File Safety | File watcher, auto-save | Medium | ✓ Done |
| **8.5** | Reliability Hardening | Data-loss guards, async scan/index, JSONL worker isolation | Medium | ✓ Done |
| **9** | Navigation | Quick switcher, outline panel | Medium | ✓ Done |
| **10** | Export | HTML, PDF, DOCX, dialog | Medium-Large | ✓ Done |
| **11** | Themes | Light theme, switcher, font selection | Medium | None |

Phase 11 (Themes) is the only remaining planned phase.
Phase 11 touches many files (Theme.qml ripple) — plan carefully.

---

## Out of Scope (Tier 2+ / Future)

Not planned for near-term:
- Multi-tab editor
- Table editor
- Math/KaTeX
- Presentation mode
- Spell check
- WikiLinks / graph view
- Git integration
- AI features
- Auto-updater
