# Phase 10 — Export System (PDF, HTML, DOCX)

**Date:** 2026-02-21

## Context

Export the currently open markdown document to PDF, HTML, and DOCX. PDF and HTML use Qt WebEngine (already available), DOCX uses pandoc via QProcess. No new Qt modules needed. Tree scanning of these file types is deferred.

## Architecture

**New files:**
- `src/exportmanager.h` / `src/exportmanager.cpp` — C++ backend, `QML_ELEMENT` + `QML_UNCREATABLE`
- `qml/components/ExportDialog.qml` — format picker + file save + progress

**Modified files:**
- `src/appcontroller.h` / `.cpp` — add ExportManager property
- `CMakeLists.txt` — add source files + QML file
- `qml/Main.qml` — add ExportDialog instance + Ctrl+Shift+E shortcut

## ExportManager (C++)

Owned by AppController, exposed as `Q_PROPERTY(ExportManager* exportManager ...)`.

### Methods
```
Q_INVOKABLE void exportHtml(const QString &markdown, const QString &outputPath, const QString &docDir)
Q_INVOKABLE void exportPdf(const QString &markdown, const QString &outputPath, const QString &docDir)
Q_INVOKABLE void exportDocx(const QString &mdFilePath, const QString &outputPath)
Q_INVOKABLE bool isPandocAvailable() const
Q_INVOKABLE QString defaultExportPath(const QString &mdFilePath, const QString &extension) const
```

### Signals
```
void exportComplete(const QString &outputPath)
void exportError(const QString &message)
```

### HTML Export
1. Render markdown via `Md4cRenderer::render()` (passed as pointer from AppController)
2. Wrap in standalone HTML template — extract CSS from `index.html` (hardcoded constant, same dark theme)
3. Resolve relative image paths to absolute `file:///` URLs using `docDir`
4. Write to file via `QSaveFile`

### PDF Export — QWebEnginePage::printToPdf()
1. Create a temporary `QWebEnginePage` (offscreen, no visible view needed)
2. Load the same standalone HTML (from HTML export step) into the page via `setHtml()`
3. Wait for `loadFinished` signal
4. Call `page->printToPdf(outputPath)` — Chromium renders pixel-perfect PDF
5. Wait for `pdfPrintingFinished(filePath, success)` signal
6. Emit `exportComplete` or `exportError`
7. Delete the temp page

Key: `QWebEnginePage` works standalone from C++ — no QML WebEngineView needed. Requires `#include <QWebEnginePage>`. Already linked to `Qt6::WebEngineQuick`.

### DOCX Export — Pandoc via QProcess
1. Check `isPandocAvailable()` — try `QProcess::execute("pandoc", {"--version"})` or search PATH
2. If not available, emit error with install instructions
3. Run: `pandoc inputMdFile -o outputPath --from=markdown --to=docx`
4. Async via `QProcess::start()` + `finished` signal
5. On success, emit `exportComplete`
6. On failure, emit `exportError` with stderr

## ExportDialog (QML)

Standard dialog following project patterns (parent: Overlay.overlay, anchors.centerIn: parent).

```
┌─ Export Document ──────────────────────┐
│                                        │
│ Format:  ○ PDF  ○ HTML  ○ DOCX        │
│                                        │
│ Output:  [/path/to/file.pdf    ] [..] │
│                                        │
│ ℹ DOCX requires pandoc (not found)    │  ← conditional warning
│                                        │
│              [Cancel]  [Export]         │
│                                        │
│ ████████████████░░░░ Exporting...      │  ← progress, visible during export
└────────────────────────────────────────┘
```

- Format radio buttons: PDF (default), HTML, DOCX
- Output path: TextField pre-filled with `defaultExportPath()`, browse button opens FileDialog
- DOCX option: disabled with warning if pandoc not found
- Export button: calls appropriate `exportXxx()` method
- On `exportComplete`: close dialog, show toast
- On `exportError`: show error label
- Shortcut: **Ctrl+Shift+E** in Main.qml

## Implementation Order

1. `src/exportmanager.h/.cpp` — create class with all three exports
2. Wire into `appcontroller.h/.cpp` and `CMakeLists.txt`
3. Build + verify compiles
4. `qml/components/ExportDialog.qml` — UI
5. `qml/Main.qml` — instantiate dialog + shortcut
6. Build + test all three formats
