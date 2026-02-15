# Plan: Split View + WebEngine Preview + Mermaid Support

**Date:** 2026-02-15

## Context

The editor currently toggles between Edit and Preview modes (mutually exclusive). We want:
1. **Split view** — editor left, preview right, side-by-side
2. **Mermaid diagram support** — render ` ```mermaid ` blocks as diagrams
3. **Better HTML rendering** — current TextEdit.RichText has limited CSS/HTML support

Mermaid requires a browser engine. Qt WebEngine is blocked on MinGW but the CI already uses MSVC (`win64_msvc2022_64`). We'll migrate local dev to MSVC and adopt WebEngine for the preview pane.

---

## Phase A: MSVC + WebEngine Setup (prerequisite)

### A1. Local Dev Environment

**Install (one-time):**
1. Visual Studio Build Tools 2022 — "Desktop development with C++" workload
2. Qt Maintenance Tool — install `Qt 6.10.1 > MSVC 2022 64-bit` kit
3. Qt Maintenance Tool — install `Extensions > Qt WebEngine` (also installs Qt Positioning, Qt WebChannel)

**Verify:** `C:/Qt/6.10.1/msvc2022_64/bin/QtWebEngineProcess.exe` exists.

**New local build commands:**
```bash
# From Developer Command Prompt for VS 2022 (or run vcvarsall.bat x64 first)
export PATH="/c/Qt/Tools/CMake_64/bin:/c/Qt/Tools/Ninja:/c/Qt/6.10.1/msvc2022_64/bin:$PATH"

cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Debug -DCMAKE_PREFIX_PATH="C:/Qt/6.10.1/msvc2022_64" -DCMAKE_C_COMPILER=cl -DCMAKE_CXX_COMPILER=cl -Wno-dev
cmake --build build
```

### A2. CMakeLists.txt Changes

```cmake
# Change find_package:
find_package(Qt6 6.10 REQUIRED COMPONENTS Quick QuickControls2 Core WebEngineQuick WebChannel)

# Change target_link_libraries:
target_link_libraries(BlockSmith PRIVATE
    Qt6::Quick Qt6::QuickControls2 Qt6::Core
    Qt6::WebEngineQuick Qt6::WebChannel
    md4c
)

# Conditional compiler flags:
if(MSVC)
    target_compile_options(BlockSmith PRIVATE /W4)
else()
    target_compile_options(BlockSmith PRIVATE -Wall -Wextra -Wpedantic)
endif()
```

### A3. main.cpp — WebEngine Init

```cpp
#include <QtWebEngineQuick/qtwebenginequickglobal.h>

int main(int argc, char *argv[]) {
    QtWebEngineQuick::initialize();  // MUST be before QGuiApplication
    QGuiApplication app(argc, argv);
    // ... rest unchanged
}
```

### A4. CI Workflow (`.github/workflows/build.yml`)

Add WebEngine modules to the Qt install step:
```yaml
- name: Install Qt
  uses: jurplel/install-qt-action@v4
  with:
    version: '6.10.1'
    arch: 'win64_msvc2022_64'
    modules: 'qtwebengine qtpositioning qtwebchannel'  # ADD
    cache: true
```

### Files Modified (Phase A)
| File | Change |
|------|--------|
| `CMakeLists.txt` | WebEngine deps, conditional compiler flags |
| `src/main.cpp` | Add `QtWebEngineQuick::initialize()` |
| `.github/workflows/build.yml` | Add WebEngine modules |
| `CLAUDE.md` | Update build environment docs |

---

## Phase B: Split View Mode

### B1. ViewMode Enum (MainContent.qml)

Replace `property bool editMode: true` with:
```qml
enum ViewMode { Edit, Preview, Split }
property int viewMode: MainContent.ViewMode.Edit
```

### B2. Content Area — Nested SplitView

Replace the current overlapping `Item` (lines 308-350) with a horizontal `SplitView`:

```qml
SplitView {
    id: editorSplitView
    Layout.fillWidth: true
    Layout.fillHeight: true
    orientation: Qt.Horizontal
    visible: AppController.currentDocument.filePath !== ""

    handle: Rectangle {
        implicitWidth: 3
        color: SplitHandle.pressed ? Theme.accent
             : SplitHandle.hovered ? Theme.borderHover
             : Theme.border
        containmentMask: Item {
            x: (parent.width - width) / 2
            width: 12
            height: parent.height
        }
    }

    MdEditor {
        id: mdEditor
        visible: mainContent.viewMode !== MainContent.ViewMode.Preview
        SplitView.fillWidth: mainContent.viewMode === MainContent.ViewMode.Edit
        SplitView.preferredWidth: editorSplitView.width / 2
        SplitView.minimumWidth: 200
        // ... existing bindings unchanged
    }

    MdPreviewWeb {   // new WebEngine-based preview (Phase C)
        id: mdPreview
        visible: mainContent.viewMode !== MainContent.ViewMode.Edit
        SplitView.fillWidth: true
        SplitView.minimumWidth: 200
        markdown: AppController.currentDocument.rawContent
    }
}
```

**Visibility logic:**
- Edit mode: MdEditor visible + fillWidth, MdPreview hidden
- Preview mode: MdEditor hidden, MdPreview visible + fillWidth
- Split mode: Both visible, each gets ~50%

### B3. Header Bar Toggle — 3 Buttons

Replace the 2-button Edit/Preview toggle with 3 buttons: **Edit | Split | Preview**

Each button checks `mainContent.viewMode === MainContent.ViewMode.X` for active styling.

### B4. Ctrl+E Shortcut Cycling (Main.qml)

```qml
Shortcut {
    sequence: "Ctrl+E"
    onActivated: {
        if (AppController.currentDocument.filePath !== "") {
            // Cycle: Edit → Split → Preview → Edit
            mainContentArea.viewMode = (mainContentArea.viewMode + 1) % 3
        }
    }
}
```

### B5. Scroll Sync (Split Mode Only)

**MdEditor.qml** — expose the ScrollView flickable:
```qml
property alias scrollFlickable: scrollView.contentItem
```

**MdPreviewWeb** — read/set scroll via `runJavaScript`:
```javascript
// Read: webView.scrollPosition.y (built-in property)
// Set: webView.runJavaScript("window.scrollTo(0, " + targetY + ")")
```

**Sync logic in MainContent.qml** — percentage-based with guard flag:
```qml
property bool _syncingScroll: false

Connections {
    target: mdEditor.scrollFlickable
    enabled: mainContent.viewMode === MainContent.ViewMode.Split
    function onContentYChanged() {
        if (_syncingScroll) return
        _syncingScroll = true
        let maxY = Math.max(1, mdEditor.scrollFlickable.contentHeight - mdEditor.scrollFlickable.height)
        let pct = mdEditor.scrollFlickable.contentY / maxY
        mdPreview.scrollToPercent(pct)
        _syncingScroll = false
    }
}
```

### B6. Status Bar Update

- Edit mode: `Ln X, Col Y` (unchanged)
- Preview mode: `Preview mode` (unchanged)
- Split mode: `Ln X, Col Y` (show editor stats since editor is active)

### B7. Toolbar Visibility

Toolbar shows when editor is visible (Edit or Split mode):
```qml
visible: mainContent.viewMode !== MainContent.ViewMode.Preview
```

### Files Modified (Phase B)
| File | Change |
|------|--------|
| `qml/components/MainContent.qml` | viewMode enum, SplitView, 3-button toggle, scroll sync, status bar |
| `qml/Main.qml` | Ctrl+E cycling, update `editMode` refs to `viewMode` |
| `qml/components/MdEditor.qml` | Expose `scrollFlickable` alias |

---

## Phase C: WebEngine Preview + Mermaid

### C1. Bundle Mermaid.js

Download `mermaid.min.js` (~2MB UMD bundle) into `resources/preview/mermaid.min.js`.

Add to CMakeLists.txt:
```cmake
qt_add_resources(BlockSmith "preview"
    PREFIX "/preview"
    FILES
        resources/preview/index.html
        resources/preview/mermaid.min.js
)
```

### C2. Preview HTML Template (`resources/preview/index.html`)

Self-contained HTML page that:
- Applies dark theme CSS (matching Theme.qml colors)
- Loads mermaid.min.js
- Exposes a `updateContent(html)` JS function
- Detects `<pre><code class="language-mermaid">` blocks and renders them
- Provides `scrollToPercent(pct)` for scroll sync

```html
<!DOCTYPE html>
<html>
<head>
<style>
  body { background: #1e1e1e; color: #d4d4d4; font-family: Segoe UI, sans-serif;
         font-size: 13px; padding: 16px; margin: 0; }
  /* ... same CSS as current Theme.previewCss ... */
  .mermaid-container svg { max-width: 100%; }
  .mermaid-error { color: #e06060; font-family: Consolas; white-space: pre; }
</style>
<script src="mermaid.min.js"></script>
<script>
  mermaid.initialize({ startOnLoad: false, theme: 'dark' });
  let renderCounter = 0;

  async function updateContent(html) {
    document.getElementById('content').innerHTML = html;
    await renderMermaidBlocks();
  }

  async function renderMermaidBlocks() {
    const blocks = document.querySelectorAll('pre code.language-mermaid');
    for (const block of blocks) {
      const pre = block.parentElement;
      const source = block.textContent;
      try {
        const { svg } = await mermaid.render('mermaid-' + (renderCounter++), source);
        const div = document.createElement('div');
        div.className = 'mermaid-container';
        div.innerHTML = svg;
        pre.replaceWith(div);
      } catch (e) {
        const div = document.createElement('div');
        div.className = 'mermaid-error';
        div.textContent = 'Mermaid error: ' + e.message;
        pre.replaceWith(div);
      }
    }
  }

  function scrollToPercent(pct) {
    const maxY = document.documentElement.scrollHeight - window.innerHeight;
    window.scrollTo(0, Math.max(0, pct * maxY));
  }
</script>
</head>
<body><div id="content"></div></body>
</html>
```

### C3. New QML Component: `MdPreviewWeb.qml`

Replaces `MdPreview.qml` for the WebEngine-based preview:

```qml
import QtQuick
import QtWebEngine
import BlockSmith

WebEngineView {
    id: previewWeb

    property string markdown: ""
    backgroundColor: "#1e1e1e"
    url: "qrc:/preview/index.html"

    // Security
    settings.localContentCanAccessRemoteUrls: false
    settings.localContentCanAccessFileUrls: true
    settings.javascriptEnabled: true
    settings.javascriptCanAccessClipboard: false
    settings.localStorageEnabled: false
    settings.pluginsEnabled: false

    // Intercept link clicks — open in system browser
    onNavigationRequested: function(request) {
        if (request.navigationType === WebEngineNavigationRequest.LinkClickedNavigation) {
            Qt.openUrlExternally(request.url)
            request.reject()
        }
    }

    // Debounced content update
    property bool _pageReady: false
    onLoadingChanged: function(info) {
        if (info.status === WebEngineLoadingInfo.LoadSucceededStatus) {
            _pageReady = true
            pushContent()
        }
    }

    onMarkdownChanged: previewTimer.restart()

    Timer {
        id: previewTimer
        interval: 200
        onTriggered: previewWeb.pushContent()
    }

    function pushContent() {
        if (!_pageReady) return
        let html = AppController.md4cRenderer.render(markdown)
        // Escape backticks and backslashes for JS template literal
        html = html.replace(/\\/g, '\\\\').replace(/`/g, '\\`').replace(/\$/g, '\\$')
        runJavaScript("updateContent(`" + html + "`)")
    }

    function scrollToPercent(pct) {
        runJavaScript("scrollToPercent(" + pct + ")")
    }
}
```

### C4. Keep Old MdPreview.qml

Keep the TextEdit-based `MdPreview.qml` as a fallback (used in BlockEditorPopup, PromptEditorPopup). Rename usage:
- `MainContent.qml` → uses `MdPreviewWeb` (new)
- `BlockEditorPopup.qml` / `PromptEditorPopup.qml` → keep using `MdPreview` (lightweight, no WebEngine needed)

### Files Modified/Created (Phase C)
| File | Change |
|------|--------|
| `resources/preview/index.html` | NEW — preview HTML template with mermaid |
| `resources/preview/mermaid.min.js` | NEW — bundled mermaid library |
| `qml/components/MdPreviewWeb.qml` | NEW — WebEngine-based preview |
| `CMakeLists.txt` | Add qt_add_resources for preview files, add MdPreviewWeb.qml to QML_FILES |

---

## Implementation Order

1. **Phase A** — MSVC + WebEngine setup (must be done first, requires manual Qt/VS install)
2. **Phase B** — Split view mode (can test with old MdPreview initially)
3. **Phase C** — WebEngine preview + mermaid (swap MdPreview → MdPreviewWeb)

Phases B and C are independent after A is done — B can be tested with the old TextEdit preview, then C swaps in WebEngine.

---

## Deployment Impact

| Metric | Before | After |
|--------|--------|-------|
| Binary + DLLs | ~50-70 MB | ~300 MB |
| Zipped | ~20-30 MB | ~100-150 MB |
| New DLLs | — | Qt6WebEngineCore, Qt6WebChannel, QtWebEngineProcess.exe, ICU, V8 |
| New resources | — | mermaid.min.js (~2MB), index.html |

---

## Files Summary

| File | Phase | Action |
|------|-------|--------|
| `CMakeLists.txt` | A+C | WebEngine deps, conditional flags, preview resources |
| `src/main.cpp` | A | WebEngine init |
| `.github/workflows/build.yml` | A | Add WebEngine modules |
| `qml/components/MainContent.qml` | B | viewMode enum, SplitView, 3-button toggle, scroll sync |
| `qml/Main.qml` | B | Ctrl+E cycling |
| `qml/components/MdEditor.qml` | B | Expose scrollFlickable |
| `resources/preview/index.html` | C | NEW |
| `resources/preview/mermaid.min.js` | C | NEW |
| `qml/components/MdPreviewWeb.qml` | C | NEW |
| `CLAUDE.md` | A | Update build env docs |
| `docs/architecture.md` | C | Document WebEngine, MdPreviewWeb |
| `docs/user-manual.md` | B | Document split view mode |

---

## Verification

1. **Phase A**: `cmake --build build` succeeds with MSVC + WebEngine linked
2. **Phase B**: Ctrl+E cycles Edit → Split → Preview → Edit; split shows editor left + preview right; scroll sync works; handle is draggable
3. **Phase C**: Mermaid code blocks render as diagrams; preview updates live with debounce; links open in system browser; dark theme consistent
4. **Full test**: Open a .md file with mermaid blocks, toggle all 3 modes, verify rendering + scroll sync + formatting toolbar + find/replace all work
