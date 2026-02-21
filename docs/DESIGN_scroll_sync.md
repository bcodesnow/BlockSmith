# Design: Improved Scroll Sync Between Editor and Preview

**Date:** 2026-02-18
**Status:** Implemented (Phases 1-3, 5) — Phase 4 (data-source-line) pending
**Scope:** Split view mode in MainContent.qml

---

## 1. Current Implementation Analysis

### What exists today

**Editor to Preview sync** (MainContent.qml, lines 384-395):
```qml
Connections {
    target: mdEditor.scrollFlickable
    enabled: mainContent.viewMode === MainContent.ViewMode.Split
    function onContentYChanged() {
        let ef = mdEditor.scrollFlickable
        if (!ef) return
        let maxY = Math.max(1, ef.contentHeight - ef.height)
        let pct = ef.contentY / maxY
        mdPreview.scrollToPercent(pct)
    }
}
```

This uses a simple **percentage-based mapping**: editor scroll position as a fraction of total scrollable area is sent to the preview's `scrollToPercent()` JavaScript function.

**JavaScript side** (index.html, line 103-106):
```js
function scrollToPercent(pct) {
    var maxY = document.documentElement.scrollHeight - window.innerHeight;
    window.scrollTo(0, Math.max(0, pct * maxY));
}
```

**MdPreviewWeb.qml** (line 64-66):
```qml
function scrollToPercent(pct) {
    runJavaScript("scrollToPercent(" + pct + ")")
}
```

### What works
- Basic editor-to-preview scroll in Split mode via percentage mapping
- Simple and low-overhead approach using `runJavaScript()`

### What doesn't work / is missing
1. **Preview to Editor sync** -- scrolling the preview does not update the editor
2. **Sync on cursor move** -- moving the cursor (via click or arrow keys) does not scroll the preview to the corresponding region
3. **Click-to-scroll** -- clicking a heading in preview does not jump to that heading in the editor
4. **No anti-feedback-loop mechanism** -- adding bidirectional sync without guards will cause infinite scroll loops
5. **No debouncing** -- rapid scrolling fires `onContentYChanged` on every pixel, calling `runJavaScript()` at 60+ Hz
6. **Percentage-based accuracy** -- percentage mapping diverges when editor and preview have very different content height distributions (e.g., a large code block is compact in the editor but tall in the preview, or vice versa)

### Infrastructure available
- **WebChannel** is already in `CMakeLists.txt` (`find_package ... WebChannel`, `Qt6::WebChannel`) but is **not wired up** in QML or JavaScript
- **md4c** does not emit source line numbers in its HTML output (the `md_html()` convenience function has no line annotation support)
- The md4c **low-level parser API** (`md_parse()`) provides `enter_block` / `leave_block` callbacks with detail structs but **no source offset** -- source positions are only exposed through the `text()` callback's text pointer offset from the input buffer

---

## 2. Improved Editor to Preview Sync

### Current approach: percentage-based
Pros: Simple, zero C++ changes. Cons: Inaccurate for documents with asymmetric content distribution.

### Proposed approach: hybrid line-number mapping

The idea is to build a mapping table between source line numbers and rendered DOM elements, then use it for scroll interpolation.

#### Phase 1: Post-process HTML to inject `data-source-line` attributes

Instead of modifying md4c itself (which would be fragile and hard to maintain), we post-process the rendered HTML in C++ before sending it to the preview. The post-processor scans the markdown source and the generated HTML in parallel to inject `data-source-line` attributes on block-level elements.

**Implementation in `Md4cRenderer`:**

Add a new method `renderWithLineMap()` that:
1. Splits the markdown source into lines
2. Calls `md_html()` as before
3. Post-processes the output: for each block-level opening tag (`<h1>`..`<h6>`, `<p>`, `<pre>`, `<blockquote>`, `<ul>`, `<ol>`, `<table>`, `<hr>`), injects a `data-source-line="N"` attribute by matching content back to source lines

```cpp
// md4crenderer.h
Q_INVOKABLE QString renderWithLineMap(const QString &markdown) const;

// md4crenderer.cpp
QString Md4cRenderer::renderWithLineMap(const QString &markdown) const
{
    // Step 1: Render HTML normally
    QString html = render(markdown);
    if (html.isEmpty()) return html;

    // Step 2: Build line offset table from source
    QStringList sourceLines = markdown.split('\n');

    // Step 3: Build a regex-based content-to-line lookup
    // For each block-level tag, find its text content in the source
    // and annotate with the source line number.
    //
    // Strategy: scan for opening block tags and inject data-source-line
    // by matching the text that follows the tag against source lines.

    QString result;
    result.reserve(html.size() + sourceLines.size() * 30);

    // Track which source line we're at (incremental matching)
    int sourceLine = 0;
    static QRegularExpression blockTagRx(
        R"(<(h[1-6]|p|pre|blockquote|ul|ol|table|hr|li)(\s[^>]*)?>)",
        QRegularExpression::CaseInsensitiveOption);

    auto it = blockTagRx.globalMatch(html);
    int lastPos = 0;

    while (it.hasNext()) {
        auto match = it.next();
        int tagStart = match.capturedStart();
        int tagEnd = match.capturedEnd();
        QString tagName = match.captured(1).toLower();

        // Copy everything before this tag
        result.append(html.mid(lastPos, tagStart - lastPos));

        // For <hr> (self-closing-ish), just inject the attribute
        // For others, extract text after the tag until the closing tag
        // and find it in source lines

        // Find text content after the tag (first 80 chars, strip HTML)
        int searchEnd = qMin(tagEnd + 200, html.size());
        QString snippet = html.mid(tagEnd, searchEnd - tagEnd);
        // Strip HTML tags from snippet for matching
        snippet.remove(QRegularExpression("<[^>]*>"));
        snippet = snippet.left(60).trimmed();

        // Search forward in source lines for a match
        int foundLine = -1;
        if (!snippet.isEmpty()) {
            for (int i = sourceLine; i < sourceLines.size(); i++) {
                if (sourceLines[i].contains(snippet.left(20))) {
                    foundLine = i + 1; // 1-based
                    sourceLine = i;
                    break;
                }
            }
        }

        // Inject data-source-line into the tag
        if (foundLine > 0) {
            // Insert before the closing >
            QString tag = match.captured(0);
            tag.insert(tag.size() - 1,
                       QString(" data-source-line=\"%1\"").arg(foundLine));
            result.append(tag);
        } else {
            result.append(match.captured(0));
        }

        lastPos = tagEnd;
    }
    result.append(html.mid(lastPos));
    return result;
}
```

**Simpler alternative (recommended for Phase 1):** Instead of post-processing HTML, inject line markers as a separate step in JavaScript after `updateContent()`. The JS side can walk the DOM children of `#content` and assign approximate line numbers based on counting newlines in the original markdown. This avoids C++ changes entirely.

**Simplest practical approach for Phase 1:** Keep percentage-based sync but add debouncing. This gives immediate improvement without C++ changes. Then layer line-number mapping in Phase 2.

#### JavaScript: line-based scrollToLine()

```js
// In index.html
function scrollToLine(lineNum) {
    var el = document.querySelector('[data-source-line="' + lineNum + '"]');
    if (!el) {
        // Fallback: find nearest element with data-source-line <= lineNum
        var all = document.querySelectorAll('[data-source-line]');
        var best = null;
        for (var i = 0; i < all.length; i++) {
            var ln = parseInt(all[i].getAttribute('data-source-line'));
            if (ln <= lineNum) best = all[i];
            else break;
        }
        el = best;
    }
    if (el) {
        el.scrollIntoView({ behavior: 'auto', block: 'start' });
    }
}
```

#### QML: send line number instead of percentage

```qml
// In MainContent.qml, replace the Connections block
Connections {
    target: mdEditor.scrollFlickable
    enabled: mainContent.viewMode === MainContent.ViewMode.Split
                && !scrollSyncGuard.syncing
    function onContentYChanged() {
        scrollSyncGuard.syncFromEditor()
    }
}
```

---

## 3. Preview to Editor Sync (via WebChannel)

This is the biggest missing feature. The preview (WebEngineView) has no way to notify QML when the user scrolls it. We need a **WebChannel bridge**.

### 3a. Create a ScrollBridge QObject

```cpp
// src/scrollbridge.h
#pragma once
#include <QObject>
#include <QtQml/qqmlregistration.h>

class ScrollBridge : public QObject
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit ScrollBridge(QObject *parent = nullptr);

    // Called from JavaScript via WebChannel
    Q_INVOKABLE void onPreviewScroll(double scrollPercent);
    Q_INVOKABLE void onHeadingClicked(int sourceLine, const QString &text);

signals:
    void previewScrolled(double percent);
    void headingClicked(int sourceLine, QString text);
};
```

```cpp
// src/scrollbridge.cpp
#include "scrollbridge.h"

ScrollBridge::ScrollBridge(QObject *parent) : QObject(parent) {}

void ScrollBridge::onPreviewScroll(double scrollPercent)
{
    emit previewScrolled(scrollPercent);
}

void ScrollBridge::onHeadingClicked(int sourceLine, const QString &text)
{
    emit headingClicked(sourceLine, text);
}
```

### 3b. Wire WebChannel in MdPreviewWeb.qml

```qml
import QtWebChannel

WebEngineView {
    id: previewWeb

    property string markdown: ""
    property ScrollBridge scrollBridge: ScrollBridge {}

    webChannel: WebChannel {
        id: previewChannel
        registeredObjects: [previewWeb.scrollBridge]
    }

    // ... rest unchanged ...
}
```

### 3c. JavaScript: connect to WebChannel and send scroll events

Add to `index.html`:

```html
<script src="qrc:///qtwebchannel/qwebchannel.js"></script>
<script>
  var bridge = null;

  // Initialize WebChannel connection
  new QWebChannel(qt.webChannelTransport, function(channel) {
      bridge = channel.objects.scrollBridge;
  });

  // Debounced scroll event listener
  var scrollTimeout = null;
  var isSyncing = false;

  window.addEventListener('scroll', function() {
      if (isSyncing) return;
      if (scrollTimeout) clearTimeout(scrollTimeout);
      scrollTimeout = setTimeout(function() {
          if (!bridge) return;
          var maxY = document.documentElement.scrollHeight - window.innerHeight;
          var pct = maxY > 0 ? (window.scrollY / maxY) : 0;
          bridge.onPreviewScroll(pct);
      }, 50);
  });

  function scrollToPercent(pct) {
      isSyncing = true;
      var maxY = document.documentElement.scrollHeight - window.innerHeight;
      window.scrollTo(0, Math.max(0, pct * maxY));
      // Release sync guard after scroll settles
      setTimeout(function() { isSyncing = false; }, 100);
  }
</script>
```

### 3d. QML: handle preview scroll in MainContent.qml

```qml
Connections {
    target: mdPreview.scrollBridge
    enabled: mainContent.viewMode === MainContent.ViewMode.Split
    function onPreviewScrolled(percent) {
        if (scrollSyncGuard.syncing) return
        scrollSyncGuard.syncing = true
        let ef = mdEditor.scrollFlickable
        let maxY = Math.max(1, ef.contentHeight - ef.height)
        ef.contentY = percent * maxY
        scrollSyncTimer.restart()
    }
}
```

---

## 4. Sync on Cursor Move

When the user clicks or navigates to a new position in the editor, the preview should scroll to show the corresponding content.

### Implementation

Add a new Connections block in MainContent.qml:

```qml
Connections {
    target: mdEditor.textArea
    enabled: mainContent.viewMode === MainContent.ViewMode.Split
    function onCursorPositionChanged() {
        if (scrollSyncGuard.syncing) return
        cursorSyncTimer.restart()
    }
}

Timer {
    id: cursorSyncTimer
    interval: 150  // debounce cursor changes
    onTriggered: {
        if (scrollSyncGuard.syncing) return

        // Calculate which line the cursor is on
        let pos = mdEditor.textArea.cursorPosition
        let content = mdEditor.textArea.text
        let lineNum = content.substring(0, pos).split("\n").length

        // Use line-based scroll if available, otherwise fall back to percentage
        mdPreview.scrollToLine(lineNum)
    }
}
```

Add `scrollToLine` to MdPreviewWeb.qml:

```qml
function scrollToLine(lineNum) {
    if (!_pageReady) return
    runJavaScript("scrollToLine(" + lineNum + ")")
}
```

---

## 5. Click-to-Scroll: Heading Click in Preview Jumps to Editor

### JavaScript: make headings clickable

In `index.html`, add to the `updateContent()` function:

```js
function updateContent(html) {
    document.getElementById('content').innerHTML = html;
    renderMermaidBlocks();
    attachHeadingClickHandlers();
}

function attachHeadingClickHandlers() {
    var headings = document.querySelectorAll('h1, h2, h3, h4, h5, h6');
    headings.forEach(function(h) {
        h.style.cursor = 'pointer';
        h.addEventListener('click', function(e) {
            if (!bridge) return;
            var lineNum = parseInt(h.getAttribute('data-source-line')) || 0;
            var text = h.textContent.trim();
            bridge.onHeadingClicked(lineNum, text);
            e.preventDefault();
        });
    });
}
```

### QML: handle heading click

In MainContent.qml:

```qml
Connections {
    target: mdPreview.scrollBridge
    enabled: true
    function onHeadingClicked(sourceLine, text) {
        // If we have data-source-line, use it directly
        if (sourceLine > 0) {
            scrollEditorToLine(sourceLine)
            return
        }

        // Fallback: text-search for the heading in the editor
        let content = mdEditor.textArea.text
        let lines = content.split("\n")
        for (let i = 0; i < lines.length; i++) {
            // Match markdown heading lines: # text, ## text, etc.
            let stripped = lines[i].replace(/^#+\s*/, "").trim()
            if (stripped === text) {
                scrollEditorToLine(i + 1)
                return
            }
        }
    }
}

function scrollEditorToLine(lineNum) {
    let content = mdEditor.textArea.text
    let lines = content.split("\n")
    if (lineNum < 1 || lineNum > lines.length) return

    // Calculate character offset of the target line start
    let offset = 0
    for (let i = 0; i < lineNum - 1; i++) {
        offset += lines[i].length + 1 // +1 for \n
    }

    // Move cursor to that line
    mdEditor.textArea.cursorPosition = offset

    // Scroll the editor to make that line visible
    let rect = mdEditor.textArea.positionToRectangle(offset)
    mdEditor.ensureVisible(rect.y)
}
```

---

## 6. Anti-Feedback-Loop Mechanism

Bidirectional sync creates a feedback loop: editor scrolls -> preview scrolls -> triggers preview scroll event -> editor scrolls -> repeat.

### Solution: `scrollSyncGuard` with timer-based release

```qml
// In MainContent.qml, add at the top of the content area or as a child of the SplitView
QtObject {
    id: scrollSyncGuard
    property bool syncing: false
}

Timer {
    id: scrollSyncTimer
    interval: 120  // ms to wait after a sync before allowing the other direction
    onTriggered: scrollSyncGuard.syncing = false
}
```

### Usage pattern

Whenever either side initiates a scroll sync:
1. Set `scrollSyncGuard.syncing = true`
2. Perform the scroll
3. Restart `scrollSyncTimer` -- it will set `syncing = false` after 120ms

Both the editor-to-preview and preview-to-editor Connections check `scrollSyncGuard.syncing` before acting.

The JavaScript side has its own `isSyncing` flag (see section 3c) that prevents the scroll event listener from firing during a programmatic `scrollToPercent()` call.

### Guard placement summary

| Direction | Guard check | Guard set |
|-----------|-------------|-----------|
| Editor scroll -> Preview | Check `scrollSyncGuard.syncing` in Connections `enabled` or `onContentYChanged` | Set `syncing = true`, restart timer |
| Preview scroll -> Editor | Check `scrollSyncGuard.syncing` in `onPreviewScrolled` handler | Set `syncing = true`, restart timer |
| Cursor move -> Preview | Check `scrollSyncGuard.syncing` in `onCursorPositionChanged` | Set `syncing = true`, restart timer |
| Heading click -> Editor | No guard needed (user-initiated, one-shot) | Optionally set guard to prevent the resulting cursor change from syncing back |

---

## 7. Debouncing Strategy

### Editor scroll debounce

Currently, `onContentYChanged` fires on every pixel of scroll. Add a Timer:

```qml
Timer {
    id: editorScrollSyncTimer
    interval: 30  // 30ms ~ 33fps, smooth enough
    onTriggered: {
        if (scrollSyncGuard.syncing) return
        scrollSyncGuard.syncing = true

        let ef = mdEditor.scrollFlickable
        if (!ef) return
        let maxY = Math.max(1, ef.contentHeight - ef.height)
        let pct = ef.contentY / maxY
        mdPreview.scrollToPercent(pct)

        scrollSyncTimer.restart()
    }
}

Connections {
    target: mdEditor.scrollFlickable
    enabled: mainContent.viewMode === MainContent.ViewMode.Split
    function onContentYChanged() {
        editorScrollSyncTimer.restart()
    }
}
```

### Preview scroll debounce

Handled in JavaScript (section 3c) with `setTimeout` at 50ms.

### Cursor sync debounce

Handled by `cursorSyncTimer` at 150ms (section 4).

### Debounce interval summary

| Event | Interval | Rationale |
|-------|----------|-----------|
| Editor scroll | 30ms | Frequent event, needs to feel responsive |
| Preview scroll (JS) | 50ms | WebChannel has latency, avoid flooding |
| Cursor move | 150ms | Fires on every arrow key press; let user settle |
| Sync guard release | 120ms | Enough for scroll animation to settle |

---

## 8. JavaScript Bridge Additions (index.html)

Complete updated `index.html` `<script>` section:

```html
<script src="qrc:///qtwebchannel/qwebchannel.js"></script>
<script src="mermaid.min.js"></script>
<script>
  mermaid.initialize({ startOnLoad: false, theme: 'dark' });
  var renderCounter = 0;
  var bridge = null;
  var isSyncing = false;
  var scrollTimeout = null;

  // --- WebChannel setup ---
  new QWebChannel(qt.webChannelTransport, function(channel) {
      bridge = channel.objects.scrollBridge;
  });

  // --- Scroll event: preview -> editor ---
  window.addEventListener('scroll', function() {
      if (isSyncing) return;
      if (scrollTimeout) clearTimeout(scrollTimeout);
      scrollTimeout = setTimeout(function() {
          if (!bridge) return;
          var maxY = document.documentElement.scrollHeight - window.innerHeight;
          var pct = maxY > 0 ? (window.scrollY / maxY) : 0;
          bridge.onPreviewScroll(pct);
      }, 50);
  });

  // --- Called from QML: editor -> preview ---
  function scrollToPercent(pct) {
      isSyncing = true;
      var maxY = document.documentElement.scrollHeight - window.innerHeight;
      window.scrollTo(0, Math.max(0, pct * maxY));
      setTimeout(function() { isSyncing = false; }, 100);
  }

  // --- Line-based scroll (for cursor sync) ---
  function scrollToLine(lineNum) {
      isSyncing = true;
      var el = document.querySelector('[data-source-line="' + lineNum + '"]');
      if (!el) {
          // Find nearest element with data-source-line <= lineNum
          var all = document.querySelectorAll('[data-source-line]');
          var best = null;
          for (var i = 0; i < all.length; i++) {
              var ln = parseInt(all[i].getAttribute('data-source-line'));
              if (ln <= lineNum) best = all[i];
              else break;
          }
          el = best;
      }
      if (el) {
          el.scrollIntoView({ behavior: 'auto', block: 'start' });
      } else {
          // Fallback to percent-based
          // Can't easily do this without knowing total lines, so just skip
      }
      setTimeout(function() { isSyncing = false; }, 100);
  }

  // --- Content update ---
  function updateContent(html) {
      document.getElementById('content').innerHTML = html;
      renderMermaidBlocks();
      attachHeadingClickHandlers();
  }

  function renderMermaidBlocks() {
      var blocks = document.querySelectorAll('pre code.language-mermaid');
      blocks.forEach(function(block) {
          var pre = block.parentElement;
          var source = block.textContent;
          renderCounter++;
          try {
              mermaid.render('mermaid-' + renderCounter, source).then(function(result) {
                  var div = document.createElement('div');
                  div.className = 'mermaid-container';
                  div.innerHTML = result.svg;
                  // Preserve data-source-line from the pre tag
                  if (pre.getAttribute('data-source-line')) {
                      div.setAttribute('data-source-line', pre.getAttribute('data-source-line'));
                  }
                  pre.replaceWith(div);
              }).catch(function(e) {
                  var div = document.createElement('div');
                  div.className = 'mermaid-error';
                  div.textContent = 'Mermaid error: ' + e.message;
                  pre.replaceWith(div);
              });
          } catch (e) {
              var div = document.createElement('div');
              div.className = 'mermaid-error';
              div.textContent = 'Mermaid error: ' + e.message;
              pre.replaceWith(div);
          }
      });
  }

  // --- Heading click handlers ---
  function attachHeadingClickHandlers() {
      var headings = document.querySelectorAll('h1, h2, h3, h4, h5, h6');
      headings.forEach(function(h) {
          h.style.cursor = 'pointer';
          h.addEventListener('click', function(e) {
              if (!bridge) return;
              var lineNum = parseInt(h.getAttribute('data-source-line')) || 0;
              var text = h.textContent.trim();
              bridge.onHeadingClicked(lineNum, text);
              e.preventDefault();
          });
      });
  }
</script>
```

---

## 9. WebChannel Setup

### Already available
- `Qt6::WebChannel` is in `CMakeLists.txt` (`find_package` and `target_link_libraries`)
- `qrc:///qtwebchannel/qwebchannel.js` is provided by the Qt WebChannel module automatically

### What needs to happen
1. **Create `ScrollBridge` C++ class** (section 3a) -- register as `QML_ELEMENT`
2. **Add to `qt_add_qml_module` sources** in `CMakeLists.txt` -- `scrollbridge.h`, `scrollbridge.cpp`
3. **Import `QtWebChannel` in MdPreviewWeb.qml** and set the `webChannel` property on the WebEngineView
4. **Include `qwebchannel.js`** via `<script src="qrc:///qtwebchannel/qwebchannel.js">` in index.html
5. **Initialize the channel** in JavaScript with `new QWebChannel(qt.webChannelTransport, ...)`
6. **Register the bridge object** so JavaScript can call methods on it

### WebChannel object registration
The `ScrollBridge` instance is created in QML (inside MdPreviewWeb.qml) and registered via the WebChannel's `registeredObjects` list. The JavaScript side accesses it as `channel.objects.scrollBridge` -- the property name matches the QML `objectName` or the position in the registered list.

To ensure the name is correct, set `objectName` explicitly:

```qml
property ScrollBridge scrollBridge: ScrollBridge {
    id: scrollBridgeObj
    objectName: "scrollBridge"
}

webChannel: WebChannel {
    id: previewChannel
    registeredObjects: [scrollBridgeObj]
}
```

The `registeredObjects` uses the `objectName` as the key in `channel.objects`.

---

## 10. Files to Modify

### New files

| File | Purpose |
|------|---------|
| `src/scrollbridge.h` | ScrollBridge QObject header (~20 lines) |
| `src/scrollbridge.cpp` | ScrollBridge QObject implementation (~15 lines) |

### Modified files

| File | Change | Details |
|------|--------|---------|
| `CMakeLists.txt` | Add sources | Add `scrollbridge.h` and `scrollbridge.cpp` to `qt_add_qml_module` SOURCES |
| `resources/preview/index.html` | Add WebChannel, scroll listener, heading handlers | Add `qwebchannel.js` script, `QWebChannel` init, `window.scroll` listener, `scrollToLine()`, `attachHeadingClickHandlers()`, `isSyncing` guard |
| `qml/components/MdPreviewWeb.qml` | Add WebChannel, ScrollBridge | Import QtWebChannel, add `scrollBridge` property, set `webChannel`, expose `scrollToLine()` |
| `qml/components/MainContent.qml` | Add bidirectional sync, debouncing, cursor sync, heading click | Replace raw Connections with debounced Timer, add preview-to-editor Connections, add cursorSyncTimer, add scrollSyncGuard, add scrollEditorToLine function |

### Optionally modified

| File | Change | Details |
|------|--------|---------|
| `src/md4crenderer.h` | Add `renderWithLineMap()` | New Q_INVOKABLE method |
| `src/md4crenderer.cpp` | Implement `renderWithLineMap()` | Post-process HTML to inject `data-source-line` attributes |
| `qml/components/MdPreviewWeb.qml` | Call `renderWithLineMap()` instead of `render()` | In `pushContent()`, use the line-annotated HTML |

The optional changes (line-map rendering) can be deferred. Heading click can work without `data-source-line` by using text-based fallback matching.

---

## 11. Implementation Order

### Phase 1: Debounced editor-to-preview sync (low effort, immediate improvement)
**Files:** MainContent.qml
1. Add `scrollSyncGuard` QtObject
2. Add `scrollSyncTimer` Timer
3. Add `editorScrollSyncTimer` Timer (30ms debounce)
4. Replace the existing `Connections` block with the debounced version
5. Test: scroll editor in Split mode, verify preview syncs smoothly without jank

### Phase 2: WebChannel bridge + Preview-to-Editor sync (medium effort)
**Files:** scrollbridge.h, scrollbridge.cpp, CMakeLists.txt, MdPreviewWeb.qml, index.html, MainContent.qml
1. Create `ScrollBridge` class
2. Add to CMakeLists.txt
3. Wire WebChannel in MdPreviewWeb.qml
4. Add `qwebchannel.js` and scroll listener to index.html
5. Add `onPreviewScrolled` handler in MainContent.qml
6. Add `isSyncing` guard in JavaScript
7. Test: scroll preview in Split mode, verify editor follows
8. Test: scroll editor, verify no infinite loop

### Phase 3: Cursor-move sync (low effort, depends on Phase 1)
**Files:** MainContent.qml, MdPreviewWeb.qml, index.html
1. Add `cursorSyncTimer` (150ms)
2. Add `onCursorPositionChanged` Connections
3. For now, use percentage-based sync as fallback (calculate cursor line position as percentage of total lines, send that to `scrollToPercent`)
4. Test: click in editor, verify preview scrolls to approximate region

### Phase 4: Line-number annotation (medium effort, optional enhancement)
**Files:** md4crenderer.h, md4crenderer.cpp, MdPreviewWeb.qml, index.html
1. Implement `renderWithLineMap()` in C++
2. Switch MdPreviewWeb.pushContent() to use it
3. Add `scrollToLine()` JavaScript function
4. Update cursor sync to use `scrollToLine()` instead of `scrollToPercent()`
5. Test: cursor movement now lands on the exact corresponding block in preview

### Phase 5: Click-to-scroll headings (low effort, depends on Phase 2; enhanced by Phase 4)
**Files:** index.html, MainContent.qml
1. Add `attachHeadingClickHandlers()` to JavaScript
2. Call it from `updateContent()`
3. Add `onHeadingClicked` handler in MainContent.qml with `scrollEditorToLine()`
4. Implement text-based fallback for heading matching (works without data-source-line)
5. Test: click heading in preview, verify editor jumps to the heading line

### Effort estimates

| Phase | Effort | Risk | Files changed |
|-------|--------|------|---------------|
| 1 | Small (30 min) | Low | 1 QML file |
| 2 | Medium (2-3 hrs) | Medium (WebChannel setup) | 2 new + 3 modified |
| 3 | Small (30 min) | Low | 2 QML files |
| 4 | Medium (1-2 hrs) | Medium (HTML post-processing edge cases) | 2 C++ files + 2 QML/HTML |
| 5 | Small (30 min) | Low | 2 files |

---

## Appendix: Alternative Approaches Considered

### A. Using `runJavaScript` with callback for preview scroll position
Instead of WebChannel, poll the preview scroll position with `runJavaScript("window.scrollY", function(val) { ... })`. Rejected: polling is wasteful and adds latency compared to event-driven WebChannel.

### B. Modifying md4c source to emit line numbers
Could fork md4c to add source offset tracking in the HTML renderer. Rejected: maintenance burden, fragile, and the same result can be achieved with post-processing.

### C. Using the low-level `md_parse()` API instead of `md_html()`
Could write a custom HTML renderer using md4c's SAX-like parser callbacks and track source positions via text pointer offsets. This would give exact line numbers. Considered for a future Phase 4+ if post-processing proves insufficient. The text callback receives pointers into the original buffer, so `offset = text_ptr - input_start` gives the byte offset, from which line numbers can be computed.

### D. Using MdPreview.qml (TextEdit-based) instead of MdPreviewWeb
The older TextEdit-based preview has a `scrollFlickable` property, making bidirectional sync trivial (both sides are Flickables). However, it lacks WebEngine features (Mermaid, proper CSS, scrollbar styling). Not viable as a replacement, but could inform the Flickable-based approach.
