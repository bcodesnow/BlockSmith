# Plan: Image Handling

**Date:** 2026-02-16

## Overview

Add image paste, drag-drop, and preview support to the markdown editor. Images are saved to a configurable subfolder relative to the document, and standard markdown image links are inserted.

---

## Phase 1: Image Path Config

### 1.1 ConfigManager — new property

Add `imageSubfolder` (default: `"images"`) to ConfigManager:

```cpp
// configmanager.h
Q_PROPERTY(QString imageSubfolder READ imageSubfolder WRITE setImageSubfolder NOTIFY imageSubfolderChanged)

// configmanager.cpp — load/save
root["imageSubfolder"] = m_imageSubfolder;
m_imageSubfolder = root.value("imageSubfolder").toString("images");
```

### 1.2 SettingsDialog — UI

Add a text field under existing settings:
```
Image subfolder: [images    ]
(Relative path from document — created automatically)
```

### Files Modified (Phase 1)
| File | Change |
|------|--------|
| `src/configmanager.h` | Add `imageSubfolder` property, getter, setter, signal |
| `src/configmanager.cpp` | Implement getter/setter, add to load/save JSON |
| `qml/components/SettingsDialog.qml` | Add image subfolder text field |

---

## Phase 2: Paste Image from Clipboard

### 2.1 C++ Helper — ImageHandler

New class `ImageHandler` (registered as `QML_ELEMENT`):

```cpp
// imagehandler.h
class ImageHandler : public QObject {
    Q_OBJECT
    QML_ELEMENT
public:
    // Check if clipboard has an image
    Q_INVOKABLE bool clipboardHasImage() const;

    // Save clipboard image to disk, return the saved file path (empty on failure)
    // destDir: absolute directory path, fileName: without extension
    Q_INVOKABLE QString saveClipboardImage(const QString &destDir, const QString &fileName);

    // Save a dropped file (copy to destDir), return saved path
    Q_INVOKABLE QString copyImageFile(const QString &sourcePath, const QString &destDir);

    // Generate a unique filename based on timestamp
    Q_INVOKABLE QString generateImageName() const;

signals:
    void imageSaved(const QString &path);
    void imageError(const QString &error);
};
```

**Implementation details:**
- `clipboardHasImage()`: `QGuiApplication::clipboard()->mimeData()->hasImage()`
- `saveClipboardImage()`: Get `QImage` from clipboard, `mkdir -p` destDir, save as PNG
- `copyImageFile()`: `QFile::copy()` source to destDir
- `generateImageName()`: `"img-" + QDateTime::currentDateTime().toString("yyyyMMdd-HHmmss")` + optional counter for uniqueness
- Supported formats: PNG (clipboard), plus JPG/PNG/GIF/SVG/WEBP for drag-drop

### 2.2 AppController — expose ImageHandler

```cpp
// appcontroller.h
Q_PROPERTY(ImageHandler* imageHandler READ imageHandler CONSTANT)
```

### 2.3 MdEditor.qml — Ctrl+V interception

In `Keys.onPressed`, add before the default handling:

```qml
// Intercept Ctrl+V when clipboard has image
if (event.key === Qt.Key_V && (event.modifiers & Qt.ControlModifier)) {
    if (AppController.imageHandler.clipboardHasImage()) {
        editorRoot.pasteImage()
        event.accepted = true
        return
    }
    // else: fall through to default text paste
}
```

**`pasteImage()` function in MdEditor.qml:**
```qml
function pasteImage() {
    let docPath = AppController.currentDocument.filePath
    if (!docPath) return

    let docDir = AppController.imageHandler.getDocumentDir(docPath)
    let subfolder = AppController.configManager.imageSubfolder
    let destDir = docDir + "/" + subfolder
    let fileName = AppController.imageHandler.generateImageName()

    let savedPath = AppController.imageHandler.saveClipboardImage(destDir, fileName)
    if (savedPath) {
        let relativePath = subfolder + "/" + fileName + ".png"
        let mdLink = "![image](" + relativePath + ")"
        textArea.insert(textArea.cursorPosition, mdLink)
    }
}
```

### Files Modified/Created (Phase 2)
| File | Change |
|------|--------|
| `src/imagehandler.h` | NEW — clipboard/file image operations |
| `src/imagehandler.cpp` | NEW — implementation |
| `src/appcontroller.h` | Add imageHandler property |
| `src/appcontroller.cpp` | Create and expose ImageHandler |
| `CMakeLists.txt` | Add imagehandler.h/.cpp to SOURCES |
| `qml/components/MdEditor.qml` | Add Ctrl+V image interception, `pasteImage()` function |

---

## Phase 3: Drag & Drop Image

### 3.1 MdEditor.qml — DropArea

Add a `DropArea` overlaying the TextArea:

```qml
DropArea {
    anchors.fill: parent
    keys: ["text/uri-list"]

    onEntered: function(drag) {
        // Visual feedback — highlight border or overlay
        if (hasImageFile(drag)) drag.accepted = true
        else drag.accepted = false
    }

    onDropped: function(drop) {
        let urls = drop.urls
        for (let i = 0; i < urls.length; i++) {
            let url = urls[i].toString()
            if (isImageUrl(url)) {
                editorRoot.dropImage(url)
            }
        }
    }
}
```

**`dropImage()` function:**
```qml
function dropImage(fileUrl) {
    let sourcePath = fileUrl.replace("file:///", "")
    let docPath = AppController.currentDocument.filePath
    if (!docPath) return

    let docDir = AppController.imageHandler.getDocumentDir(docPath)
    let subfolder = AppController.configManager.imageSubfolder
    let destDir = docDir + "/" + subfolder

    let savedPath = AppController.imageHandler.copyImageFile(sourcePath, destDir)
    if (savedPath) {
        let fileName = AppController.imageHandler.fileNameOf(savedPath)
        let relativePath = subfolder + "/" + fileName
        let mdLink = "![image](" + relativePath + ")\n"
        textArea.insert(textArea.cursorPosition, mdLink)
    }
}
```

**Supported extensions check:**
```qml
function isImageUrl(url) {
    let lower = url.toLowerCase()
    return lower.endsWith(".png") || lower.endsWith(".jpg")
        || lower.endsWith(".jpeg") || lower.endsWith(".gif")
        || lower.endsWith(".svg") || lower.endsWith(".webp")
        || lower.endsWith(".bmp")
}
```

### 3.2 Visual Drop Feedback

Show a translucent overlay with "Drop image here" when dragging over the editor:

```qml
Rectangle {
    id: dropOverlay
    anchors.fill: parent
    visible: false
    color: Qt.rgba(0.42, 0.61, 0.82, 0.15)  // accent tint
    border.color: Theme.accent
    border.width: 2
    radius: 4
    z: 10

    Label {
        anchors.centerIn: parent
        text: "Drop image here"
        color: Theme.accent
        font.pixelSize: 16
    }
}
```

### Files Modified (Phase 3)
| File | Change |
|------|--------|
| `qml/components/MdEditor.qml` | Add DropArea, dropOverlay, `dropImage()`, `isImageUrl()` |

---

## Phase 4: Image Preview

### 4.1 WebEngine Preview — Already Works

The `MdPreviewWeb.qml` already has `settings.localContentCanAccessFileUrls: true`. Standard markdown image syntax with relative paths works if the base URL is set correctly.

**Fix needed:** The preview loads from `qrc:/preview/index.html` — relative image paths in markdown won't resolve. Two options:

**Option A (recommended): Convert to absolute file:// URLs in render**

In `MdPreviewWeb.qml`, before pushing content, resolve relative image paths:

```qml
function pushContent() {
    if (!_pageReady) return
    let html = AppController.md4cRenderer.render(markdown)
    // Resolve relative image paths to absolute file:// URLs
    let docDir = AppController.currentDocument.filePath
    if (docDir) {
        let dir = AppController.imageHandler.getDocumentDir(docDir)
        let fileUrl = "file:///" + dir.replace(/\\/g, "/") + "/"
        html = html.replace(/src="(?!https?:\/\/|file:\/\/|data:)([^"]+)"/g,
                           'src="' + fileUrl + '$1"')
    }
    html = html.replace(/\\/g, '\\\\').replace(/`/g, '\\`').replace(/\$/g, '\\$')
    runJavaScript("updateContent(`" + html + "`)")
}
```

**Option B: Set baseUrl on WebEngineView**

Use `setBaseUrl()` JS call when document changes — this tells the browser where to resolve relative URLs from.

### 4.2 Old MdPreview.qml — Limited Support

The TextEdit-based `MdPreview.qml` (used in popups) has limited `<img>` support. Not worth implementing complex image handling there — popups show block/prompt content which rarely has images.

### Files Modified (Phase 4)
| File | Change |
|------|--------|
| `qml/components/MdPreviewWeb.qml` | Resolve relative image paths in `pushContent()` |
| `src/imagehandler.h/.cpp` | Add `getDocumentDir()` helper if not already there |

---

## Implementation Order

1. **Phase 1** — Config property (quick, foundation for everything else)
2. **Phase 2** — Paste image (most common use case)
3. **Phase 4** — Image preview fix (needed to verify paste works visually)
4. **Phase 3** — Drag & drop (builds on Phase 2 infrastructure)

---

## Edge Cases & Considerations

| Scenario | Handling |
|----------|----------|
| No file open | Show toast "Open a file first" |
| Subfolder doesn't exist | Auto-create with `QDir::mkpath()` |
| Duplicate file name | Append `-1`, `-2` etc. or use timestamp-based names |
| Unsupported image format | Ignore / toast "Unsupported format" |
| Very large image paste | Save full resolution PNG (no resizing — user can resize externally) |
| Image already in subfolder | Don't copy again, just insert relative link |
| Clipboard has both text and image | Image takes priority when Ctrl+V intercepted (can add context menu "Paste as Text" later) |
| Relative path in preview | Resolved to absolute `file://` URL before rendering |

---

## Files Summary

| File | Phase | Action |
|------|-------|--------|
| `src/imagehandler.h` | 2 | NEW |
| `src/imagehandler.cpp` | 2 | NEW |
| `src/configmanager.h` | 1 | Add imageSubfolder property |
| `src/configmanager.cpp` | 1 | Implement + load/save |
| `src/appcontroller.h` | 2 | Expose ImageHandler |
| `src/appcontroller.cpp` | 2 | Create ImageHandler |
| `CMakeLists.txt` | 2 | Add imagehandler sources |
| `qml/components/MdEditor.qml` | 2+3 | Ctrl+V interception, DropArea, paste/drop functions |
| `qml/components/MdPreviewWeb.qml` | 4 | Resolve relative image paths |
| `qml/components/SettingsDialog.qml` | 1 | Image subfolder config field |

---

## Verification

1. **Phase 1**: Settings dialog shows image subfolder field, value persists after restart
2. **Phase 2**: Screenshot tool → Ctrl+V in editor → image saved to `./images/`, markdown link inserted, preview shows image
3. **Phase 3**: Drag PNG from Explorer onto editor → copied to `./images/`, link inserted
4. **Phase 4**: Split view shows images inline, both relative and absolute paths work
