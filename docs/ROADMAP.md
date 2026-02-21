# BlockSmith Roadmap

**Date:** 2026-02-21
**Baseline:** All 6 phases complete + JSONL viewer, scroll sync, zoom, robustness audit

---

## Phase 7 — Housekeeping & Quick Wins

Small fixes that improve polish without new features.

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
- **Design:** See [DESIGN_scroll_sync.md](DESIGN_scroll_sync.md) Phase 4

---

## Phase 8 — File Safety

Features that prevent data loss and keep content fresh.

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

## Phase 9 — Navigation & Productivity

Features that speed up daily workflows.

### 9.1 Quick Switcher (Ctrl+P)
- Popup dialog with fuzzy-match text field
- Source: all files from SyncEngine::allMdFiles() + JSONL files from tree
- Fuzzy matching: score by substring position + consecutive chars (no external lib needed)
- ListView of results, keyboard navigable (Up/Down/Enter/Esc)
- Opens file on Enter, closes on Esc
- Recent files bonus: track last 10 opened files in ConfigManager, show at top when query is empty
- **Files:** qml/components/QuickSwitcher.qml (new), qml/Main.qml (Shortcut + instantiation), src/configmanager.h/.cpp (recentFiles list)

### 9.2 Outline Panel
- New tab in RightPane: "Outline" (alongside Blocks / Prompts)
- Parses headings from current document (regex: `^#{1,6}\s+(.*)`)
- Hierarchical tree model showing H1-H6 nesting
- Click to scroll editor + preview to that heading
- Current heading highlighted based on cursor position
- **Files:** qml/components/OutlinePanel.qml (new), qml/components/RightPane.qml (add tab), qml/components/MainContent.qml (heading parse + scroll-to)

---

## Phase 10 — Export System

Generate standalone output files from markdown documents.

### 10.1 HTML Export
- Standalone .html with embedded CSS (reuse preview theme CSS)
- Wrap md4c output in full HTML5 document template with inline styles
- Include images as relative paths or optionally base64-embedded
- File save dialog with .html filter
- **Implementation:** Pure C++ — Md4cRenderer already produces HTML, just wrap in `<html><head><style>...</style></head><body>` template
- **Files:** src/exportmanager.h/.cpp (new class), qml/components/ExportDialog.qml (new)

### 10.2 PDF Export
- Use QPrinter + QTextDocument::setHtml() for native Qt PDF rendering
- Page size (A4/Letter), margins, header/footer options
- Code block styling preserved, page breaks at headings
- Alternative: QWebEnginePage::printToPdf() — uses the WebEngine renderer for pixel-perfect output matching the preview
- **Recommended:** QWebEnginePage::printToPdf() — zero layout differences from preview, supports mermaid diagrams
- **Files:** src/exportmanager.h/.cpp, qml/components/ExportDialog.qml

### 10.3 DOCX Export (Optional — Pandoc)
- Shell out to Pandoc if available on system (`QProcess`)
- Pass markdown source + reference docx template for styling
- Gracefully degrade: if Pandoc not found, show message with install link
- No bundling Pandoc — it's a 100MB+ dependency
- **Files:** src/exportmanager.h/.cpp (pandoc path detection, QProcess invocation)

### 10.4 Export Dialog
- Format picker: HTML / PDF / DOCX
- Output path with file browser
- Format-specific options (PDF: page size, margins; HTML: embed images toggle)
- "Export & Overwrite Previous" — remember last export path per document, one-click re-export
- Keyboard shortcut: Ctrl+Shift+E
- **Files:** qml/components/ExportDialog.qml (new), qml/Main.qml (Shortcut)

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
| **7** | Housekeeping | Locale, splitter persist, scroll sync accuracy | Small | None |
| **8** | File Safety | File watcher, auto-save | Medium | None |
| **9** | Navigation | Quick switcher, outline panel | Medium | None |
| **10** | Export | HTML, PDF, DOCX, dialog | Medium-Large | None |
| **11** | Themes | Light theme, switcher, font selection | Medium | None |

Phases 7-9 are independent and can be done in any order.
Phase 10 is self-contained.
Phase 11 touches many files (Theme.qml ripple) — do last.

---

## Out of Scope (Tier 2+ / Future)

These are documented in [todos.md](todos.md) but not planned for near-term:
- Multi-tab editor
- Table editor
- Math/KaTeX
- Presentation mode
- Spell check
- WikiLinks / graph view
- Git integration
- AI features
- Auto-updater (see [PLAN_UPDATE_FROM_GITHUB_RELEASE.md](PLAN_UPDATE_FROM_GITHUB_RELEASE.md))
