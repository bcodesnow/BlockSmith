# Design: Editor/Preview Zoom

**Date:** 2026-02-18
**Status:** Implemented

## 1. Scope

Zoom applies to the **editor center pane** only — the area users read and write content in:

| Component | Affected | How |
|-----------|----------|-----|
| MdEditor TextArea | Yes | `font.pixelSize` scaled by zoom factor |
| Line number gutter | Yes | Gutter labels use `textArea.font`, so they follow automatically |
| Gutter width | Yes | Digit width calculation already uses font metrics — auto-adjusts |
| MdPreviewWeb | Yes | `WebEngineView.zoomFactor` property (built-in) |
| NavPanel (left pane) | No | Fixed UI chrome |
| RightPane (blocks/prompts) | No | Fixed UI chrome |
| Toolbar, status bar, dialogs | No | Fixed UI chrome |

## 2. ConfigManager Changes

Add a single persisted `int` property: `zoomLevel` (percentage, default 100).

### configmanager.h

```cpp
// Add to Q_PROPERTY block:
Q_PROPERTY(int zoomLevel READ zoomLevel WRITE setZoomLevel NOTIFY zoomLevelChanged)

// Add to public:
int zoomLevel() const;
void setZoomLevel(int level);

// Add to signals:
void zoomLevelChanged();

// Add to private:
int m_zoomLevel = 100;
```

### configmanager.cpp

```cpp
int ConfigManager::zoomLevel() const { return m_zoomLevel; }

void ConfigManager::setZoomLevel(int level)
{
    level = qBound(50, level, 200);
    if (m_zoomLevel != level) {
        m_zoomLevel = level;
        emit zoomLevelChanged();
    }
}
```

Add to `load()`:
```cpp
if (root.contains("zoomLevel"))
    m_zoomLevel = qBound(50, root["zoomLevel"].toInt(100), 200);
```

Add to `save()`:
```cpp
root["zoomLevel"] = m_zoomLevel;
```

## 3. Theme Changes

Add computed zoom-scaled font size properties. The `readonly` base sizes stay as-is; new `real` properties provide scaled values.

### Theme.qml

```qml
// Zoom factor derived from ConfigManager (1.0 at 100%)
readonly property real zoomFactor: AppController.configManager.zoomLevel / 100.0

// Zoomed font sizes for editor/preview content
readonly property real fontSizeLZoomed:  Math.round(fontSizeL  * zoomFactor)
readonly property real fontSizeMZoomed:  Math.round(fontSizeM  * zoomFactor)
```

Only `fontSizeLZoomed` is needed for the editor TextArea and `fontSizeMZoomed` is not strictly required but may be useful for the gutter or future use. The key point: only the editor content fonts use zoomed values; all UI chrome keeps the original `readonly int` sizes.

## 4. MdEditor Changes

### TextArea font binding

In `MdEditor.qml`, change the TextArea's font size from the fixed value to the zoomed value:

```qml
// Before:
font.pixelSize: Theme.fontSizeL

// After:
font.pixelSize: Theme.fontSizeLZoomed
```

That is the only change needed. Everything else follows automatically:

- **Line number labels** already use `font: textArea.font` — they inherit the zoomed size.
- **FontMetrics `fm`** already binds to `textArea.font` — line height calculations update.
- **Gutter width** already computes from digit count + fixed padding — the labels resize but the gutter column itself is based on character count, not font metrics. We should improve this:

```qml
// Before (MdEditor.qml, gutter width):
width: {
    let lineCount = Math.max(1, (textArea.text || "").split("\n").length)
    let digits = Math.max(3, lineCount.toString().length)
    return digits * 9 + 20
}

// After — use actual font metrics:
width: {
    let lineCount = Math.max(1, (textArea.text || "").split("\n").length)
    let digits = Math.max(3, lineCount.toString().length)
    return digits * fm.averageCharacterWidth + 20
}
```

This makes the gutter scale properly at all zoom levels instead of assuming 9px per digit.

## 5. MdPreviewWeb Changes

`WebEngineView` has a built-in `zoomFactor` property (1.0 = 100%). Bind it directly:

```qml
// Add to MdPreviewWeb.qml:
zoomFactor: AppController.configManager.zoomLevel / 100.0
```

No CSS changes needed — `zoomFactor` scales the entire rendered page uniformly.

## 6. Keyboard Shortcuts

Add three shortcuts to `Main.qml`:

```qml
Shortcut {
    sequences: ["Ctrl+=", "Ctrl++"]
    onActivated: {
        AppController.configManager.zoomLevel = Math.min(200,
            AppController.configManager.zoomLevel + 10)
    }
}
Shortcut {
    sequence: "Ctrl+-"
    onActivated: {
        AppController.configManager.zoomLevel = Math.max(50,
            AppController.configManager.zoomLevel - 10)
    }
}
Shortcut {
    sequence: "Ctrl+0"
    onActivated: AppController.configManager.zoomLevel = 100
}
```

Notes:
- `Ctrl+=` covers both `Ctrl+=` (unshifted) and numpad `+` on most keyboards. The `sequences` array with both `"Ctrl+="` and `"Ctrl++"` covers Shift+= too.
- Step size of 10% matches VS Code / browser conventions.
- The `qBound(50, level, 200)` in the setter is the safety net; QML-side clamping just avoids unnecessary property writes.

## 7. Optional: Ctrl+MouseWheel Zoom

Add a `WheelHandler` to `MainContent.qml` (the center pane parent) that captures Ctrl+Wheel:

```qml
// Add inside MainContent.qml, at the top level of the Rectangle:
WheelHandler {
    acceptedModifiers: Qt.ControlModifier
    onWheel: function(event) {
        let delta = event.angleDelta.y
        if (delta > 0)
            AppController.configManager.zoomLevel = Math.min(200,
                AppController.configManager.zoomLevel + 10)
        else if (delta < 0)
            AppController.configManager.zoomLevel = Math.max(50,
                AppController.configManager.zoomLevel - 10)
    }
}
```

Note: `WheelHandler` with `acceptedModifiers` requires QtQuick 2.15+ (we have 6.10). This intercepts only when Ctrl is held, so normal scrolling is unaffected.

## 8. Status Bar Zoom Indicator

Show the current zoom level in the status bar (in `MainContent.qml`) so users have feedback. Add a clickable label next to the encoding label:

```qml
// In the status bar RowLayout, after the encoding label:
Label {
    text: AppController.configManager.zoomLevel + "%"
    font.pixelSize: Theme.fontSizeS
    color: Theme.textMuted
    visible: AppController.configManager.zoomLevel !== 100

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: AppController.configManager.zoomLevel = 100
    }

    ToolTip.text: "Click to reset zoom"
    ToolTip.visible: zoomMa.containsMouse
    ToolTip.delay: 400
}
```

Only shows when zoom is not 100%. Clicking resets to 100%.

## 9. Edge Cases

| Case | Behavior |
|------|----------|
| Min zoom (50%) | Font goes from 13px to ~7px. Still legible on high-DPI. |
| Max zoom (200%) | Font goes to 26px. TextArea wraps; gutter scales with `fm`. |
| Pane reflow | SplitView minimums are pixel-based (200px). At 200% zoom, fewer chars fit but layout stays valid. |
| Persistence | `zoomLevel` saved to `config.json` on window close (existing `onClosing` calls `save()`). Also saved immediately via shortcuts is optional — the setter doesn't call save, but `onClosing` does. |
| Preview sync | `zoomFactor` is a simple property bind — instant, no reload needed. |
| Block editor popups | `BlockEditorPopup` and `PromptEditorPopup` use `Theme.fontSizeL` for their TextAreas. Decision: do NOT zoom these — they are modal dialogs, not the main editor. Keeps scope narrow. |
| Line height recompute | Changing zoom triggers `textArea.font` change, which triggers `contentHeightChanged`, which triggers `lineHeightTimer` — gutter recomputes automatically. |

## 10. Files to Modify

| File | Change |
|------|--------|
| `src/configmanager.h` | Add `zoomLevel` Q_PROPERTY, getter, setter, signal, member |
| `src/configmanager.cpp` | Implement getter/setter, add to `load()`/`save()` |
| `qml/components/Theme.qml` | Add `zoomFactor` and `fontSizeLZoomed` properties |
| `qml/components/MdEditor.qml` | Change TextArea `font.pixelSize` to `Theme.fontSizeLZoomed`; fix gutter width to use `fm.averageCharacterWidth` |
| `qml/components/MdPreviewWeb.qml` | Add `zoomFactor` binding |
| `qml/Main.qml` | Add 3 Shortcut items (Ctrl++, Ctrl+-, Ctrl+0) |
| `qml/components/MainContent.qml` | Add WheelHandler for Ctrl+Wheel; add zoom indicator in status bar |

## 11. Implementation Order

1. **ConfigManager** — add `zoomLevel` property + persistence (C++ build must pass)
2. **Theme.qml** — add `zoomFactor` and `fontSizeLZoomed`
3. **MdEditor.qml** — bind to zoomed font size, fix gutter width
4. **MdPreviewWeb.qml** — bind `zoomFactor`
5. **Main.qml** — add keyboard shortcuts
6. **MainContent.qml** — add Ctrl+Wheel handler + status bar indicator
7. **Test** — verify Ctrl++/Ctrl+-/Ctrl+0, mouse wheel, persistence across restart

Total: ~50 lines of C++, ~30 lines of QML. No new files.
