import QtQuick
import QtQuick.Controls
import BlockSmith

Item {
    id: editorRoot

    property alias text: textArea.text
    property alias readOnly: textArea.readOnly
    property alias textArea: textArea
    property alias cursorPosition: textArea.cursorPosition
    property bool toolbarVisible: true
    readonly property Flickable scrollFlickable: scrollView.contentItem

    signal addBlockRequested(string selectedText, int selStart, int selEnd)
    signal createPromptRequested(string selectedText)
    signal imageInserted(string name)
    signal imageErrorOccurred(string error)

    // --- Image paste/drop helpers ---

    function pasteImage() {
        let docPath = AppController.currentDocument.filePath
        if (!docPath) { imageErrorOccurred("Open a file first"); return }

        let docDir = AppController.imageHandler.getDocumentDir(docPath)
        let subfolder = AppController.configManager.imageSubfolder
        let destDir = docDir + "/" + subfolder
        let fileName = AppController.imageHandler.generateImageName()

        let savedPath = AppController.imageHandler.saveClipboardImage(destDir, fileName)
        if (savedPath) {
            let savedName = AppController.imageHandler.fileNameOf(savedPath)
            let relativePath = subfolder + "/" + savedName
            let mdLink = "![image](" + relativePath + ")"
            textArea.insert(textArea.cursorPosition, mdLink)
            imageInserted(savedName)
        }
    }

    function dropImage(fileUrl) {
        let sourcePath = decodeURIComponent(fileUrl.toString().replace("file:///", ""))
        let docPath = AppController.currentDocument.filePath
        if (!docPath) { imageErrorOccurred("Open a file first"); return }

        let docDir = AppController.imageHandler.getDocumentDir(docPath)
        let subfolder = AppController.configManager.imageSubfolder
        let destDir = docDir + "/" + subfolder

        let savedPath = AppController.imageHandler.copyImageFile(sourcePath, destDir)
        if (savedPath) {
            let savedName = AppController.imageHandler.fileNameOf(savedPath)
            let relativePath = subfolder + "/" + savedName
            let mdLink = "![image](" + relativePath + ")\n"
            textArea.insert(textArea.cursorPosition, mdLink)
            imageInserted(savedName)
        }
    }

    function isImageUrl(url) {
        let lower = url.toString().toLowerCase()
        return lower.endsWith(".png") || lower.endsWith(".jpg")
            || lower.endsWith(".jpeg") || lower.endsWith(".gif")
            || lower.endsWith(".svg") || lower.endsWith(".webp")
            || lower.endsWith(".bmp")
    }

    // --- Editing helpers ---

    // Get the line start offset for a given cursor position
    function lineStartOf(pos) {
        let t = textArea.text
        let i = pos - 1
        while (i >= 0 && t[i] !== '\n') i--
        return i + 1
    }

    // Get the line end offset for a given cursor position
    function lineEndOf(pos) {
        let t = textArea.text
        let i = pos
        while (i < t.length && t[i] !== '\n') i++
        return i
    }

    // Handle Tab indent / Shift+Tab outdent
    function handleTab(shift) {
        let selStart = textArea.selectionStart
        let selEnd = textArea.selectionEnd
        let hasSelection = selStart !== selEnd

        if (!hasSelection && !shift) {
            // Simple tab: insert 4 spaces
            textArea.insert(textArea.cursorPosition, "    ")
            return
        }

        // Multi-line indent/outdent
        let lineStart = lineStartOf(selStart)
        let lineEnd = lineEndOf(selEnd > selStart ? selEnd - 1 : selEnd)
        let block = textArea.text.substring(lineStart, lineEnd)
        let lines = block.split("\n")
        let newLines = []

        if (shift) {
            // Outdent: remove up to 4 leading spaces
            for (let i = 0; i < lines.length; i++) {
                let line = lines[i]
                let remove = 0
                while (remove < 4 && remove < line.length && line[remove] === ' ') remove++
                newLines.push(line.substring(remove))
            }
        } else {
            // Indent: add 4 spaces
            for (let i = 0; i < lines.length; i++) {
                newLines.push("    " + lines[i])
            }
        }

        let result = newLines.join("\n")
        textArea.remove(lineStart, lineEnd)
        textArea.insert(lineStart, result)
        // Re-select the modified region
        textArea.select(lineStart, lineStart + result.length)
    }

    // Handle Enter: auto-continue lists
    function handleEnter() {
        let pos = textArea.cursorPosition
        let lineStart = lineStartOf(pos)
        let lineText = textArea.text.substring(lineStart, pos)

        // Match list prefixes: "- ", "* ", "+ ", "1. ", "- [ ] ", "- [x] "
        let listMatch = lineText.match(/^(\s*)([-*+])\s(\[[ x]\]\s)?/)
        let orderedMatch = lineText.match(/^(\s*)(\d+)\.\s/)

        if (listMatch) {
            let indent = listMatch[1]
            let bullet = listMatch[2]
            let checkbox = listMatch[3] || ""
            let content = lineText.substring(listMatch[0].length)

            if (content.trim().length === 0) {
                // Empty list item — remove it
                textArea.remove(lineStart, pos)
                return
            }

            // Continue list with same prefix
            let prefix = indent + bullet + " " + (checkbox ? "[ ] " : "")
            textArea.insert(pos, "\n" + prefix)
            textArea.cursorPosition = pos + 1 + prefix.length
            return
        }

        if (orderedMatch) {
            let indent = orderedMatch[1]
            let num = parseInt(orderedMatch[2])
            let content = lineText.substring(orderedMatch[0].length)

            if (content.trim().length === 0) {
                // Empty list item — remove it
                textArea.remove(lineStart, pos)
                return
            }

            let prefix = indent + (num + 1) + ". "
            textArea.insert(pos, "\n" + prefix)
            textArea.cursorPosition = pos + 1 + prefix.length
            return
        }

        // Default: just insert newline
        textArea.insert(pos, "\n")
        textArea.cursorPosition = pos + 1
    }

    // Duplicate current line (Ctrl+D)
    function duplicateLine() {
        let pos = textArea.cursorPosition
        let start = lineStartOf(pos)
        let end = lineEndOf(pos)
        let line = textArea.text.substring(start, end)
        textArea.insert(end, "\n" + line)
        textArea.cursorPosition = pos + line.length + 1
    }

    function ensureVisible(yPos) {
        let flickable = scrollView.contentItem
        let viewH = scrollView.height
        if (yPos < flickable.contentY + 40) {
            flickable.contentY = Math.max(0, yPos - 40)
        } else if (yPos > flickable.contentY + viewH - 40) {
            flickable.contentY = yPos - viewH + 40
        }
    }

    // Syntax highlighter
    MdSyntaxHighlighter {
        id: syntaxHighlighter
        document: textArea.textDocument
        enabled: AppController.configManager.syntaxHighlightEnabled
    }

    FontMetrics {
        id: fm
        font: textArea.font
    }

    // Precompute per-line heights to account for word-wrap (debounced)
    property var lineHeights: [fm.lineSpacing]

    Timer {
        id: lineHeightTimer
        interval: 100
        onTriggered: editorRoot.lineHeights = editorRoot.computeLineHeights()
    }

    Connections {
        target: textArea
        function onTextChanged() { lineHeightTimer.restart() }
        function onContentHeightChanged() { lineHeightTimer.restart() }
        function onWidthChanged() { lineHeightTimer.restart() }
    }

    function computeLineHeights() {
        let t = textArea.text || ""
        if (t.length === 0) return [fm.lineSpacing]
        let offsets = [0]
        for (let i = 0; i < t.length; i++) {
            if (t[i] === '\n') offsets.push(i + 1)
        }
        let heights = []
        for (let i = 0; i < offsets.length; i++) {
            if (i + 1 < offsets.length) {
                let y1 = textArea.positionToRectangle(offsets[i]).y
                let y2 = textArea.positionToRectangle(offsets[i + 1]).y
                heights.push(Math.max(y2 - y1, fm.lineSpacing))
            } else {
                heights.push(fm.lineSpacing)
            }
        }
        return heights
    }

    // Revision counter — bumped when block store changes, forces blockRanges re-eval
    property int blockStoreRevision: 0
    Connections {
        target: AppController.blockStore
        function onBlockUpdated() { editorRoot.blockStoreRevision++ }
        function onCountChanged() { editorRoot.blockStoreRevision++ }
    }

    // Block line ranges computed by scanning the text directly (debounced)
    property var blockRanges: []

    Timer {
        id: blockRangesTimer
        interval: 100
        onTriggered: editorRoot.blockRanges = editorRoot.computeBlockRanges()
    }

    onBlockStoreRevisionChanged: blockRangesTimer.restart()

    Connections {
        id: blockRangesConn
        target: textArea
        function onTextChanged() { blockRangesTimer.restart() }
    }

    function computeBlockRanges() {
        let t = textArea.text || ""
        if (t.length === 0) return []

        let lines = t.split("\n")
        let ranges = []
        let cur = null
        let contentLines = []

        for (let i = 0; i < lines.length; i++) {
            let line = lines[i]

            if (!cur) {
                let m = line.match(/<!--\s*block:\s*(.+?)\s*\[id:([a-f0-9]{6})\]\s*-->/)
                if (m) {
                    cur = { name: m[1], id: m[2], startLine: i + 1 }
                    contentLines = []
                }
            } else {
                let closeRx = new RegExp("<!--\\s*/block:" + cur.id + "\\s*-->")
                if (closeRx.test(line)) {
                    let content = contentLines.join("\n")
                    let storeBlock = AppController.blockStore.getBlock(cur.id)
                    let status = "local"
                    if (storeBlock && storeBlock.id) {
                        status = (storeBlock.content === content) ? "synced" : "diverged"
                    }
                    ranges.push({
                        startLine: cur.startLine,
                        endLine: i + 1,
                        id: cur.id,
                        name: cur.name,
                        status: status
                    })
                    cur = null
                } else {
                    contentLines.push(line)
                }
            }
        }
        return ranges
    }

    // Lookup: given a 1-based line number, return block info or null
    function blockAtLine(lineNum) {
        let r = editorRoot.blockRanges
        for (let i = 0; i < r.length; i++) {
            if (lineNum >= r[i].startLine && lineNum <= r[i].endLine)
                return r[i]
        }
        return null
    }

    // Markdown formatting toolbar
    MdToolbar {
        id: mdToolbar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        visible: editorRoot.toolbarVisible
        targetArea: textArea
    }

    // Line number gutter
    Rectangle {
        id: gutter
        anchors.left: parent.left
        anchors.top: mdToolbar.visible ? mdToolbar.bottom : parent.top
        anchors.bottom: parent.bottom
        width: {
            let lineCount = Math.max(1, (textArea.text || "").split("\n").length)
            let digits = Math.max(3, lineCount.toString().length)
            return digits * fm.averageCharacterWidth + 20 // font-scaled digit width + padding for block strip
        }
        color: Theme.bgGutter
        clip: true
        z: 2

        // Right border
        Rectangle {
            anchors.right: parent.right
            width: 1
            height: parent.height
            color: Theme.bgHeader
        }

        Column {
            id: lineNumberCol
            y: -scrollView.contentItem.contentY + textArea.topPadding

            Repeater {
                model: Math.max(1, (textArea.text || "").split("\n").length)

                delegate: Item {
                    width: gutter.width - 4
                    height: editorRoot.lineHeights[index] || fm.lineSpacing

                    // Block region indicator strip (left edge)
                    Rectangle {
                        id: blockStrip
                        width: 4
                        height: parent.height
                        anchors.left: parent.left

                        property var blockInfo: editorRoot.blockAtLine(index + 1)

                        color: {
                            if (!blockInfo) return "transparent"
                            if (blockInfo.status === "synced") return Theme.accentGreen
                            if (blockInfo.status === "diverged") return Theme.accentOrange
                            return Theme.accent // local
                        }

                        ToolTip.text: blockInfo
                            ? blockInfo.name + " [" + blockInfo.id + "] — " + blockInfo.status
                            : ""
                        ToolTip.visible: blockInfo ? stripMa.containsMouse : false
                        ToolTip.delay: 400

                        MouseArea {
                            id: stripMa
                            anchors.fill: parent
                            hoverEnabled: true
                        }
                    }

                    Label {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: index + 1
                        font: textArea.font
                        color: (index + 1) === gutter.currentLine ? Theme.textBright : Theme.textSecondary
                    }
                }
            }
        }

        // Current line (computed once, not per-delegate)
        property int currentLine: {
            let pos = textArea.cursorPosition
            let t = textArea.text || ""
            return t.substring(0, pos).split("\n").length
        }
    }

    ScrollView {
        id: scrollView
        anchors.left: gutter.right
        anchors.right: parent.right
        anchors.top: mdToolbar.visible ? mdToolbar.bottom : parent.top
        anchors.bottom: parent.bottom

        // Current line highlight
        Rectangle {
            id: currentLineHighlight
            width: scrollView.width
            height: {
                // Use wrap-aware line height when available
                let lineIdx = gutter.currentLine - 1
                return editorRoot.lineHeights[lineIdx] || fm.lineSpacing
            }
            y: {
                void(scrollView.contentItem.contentY)  // re-eval on scroll
                let rect = textArea.positionToRectangle(textArea.cursorPosition)
                return textArea.mapToItem(scrollView, 0, rect.y).y
            }
            color: Qt.rgba(1, 1, 1, 0.08)
            z: -1
        }

        TextArea {
            id: textArea
            font.family: Theme.fontMono
            font.pixelSize: Theme.fontSizeLZoomed
            wrapMode: TextArea.Wrap
            tabStopDistance: 28
            selectByMouse: true
            placeholderText: "Select a file to begin editing."

            background: Rectangle {
                color: Theme.bg
            }

            color: Theme.textEditor
            selectionColor: Theme.bgSelection
            selectedTextColor: Theme.textWhite
            placeholderTextColor: Theme.textPlaceholder

            cursorDelegate: Rectangle {
                visible: textArea.activeFocus
                width: Theme.cursorWidth
                color: Theme.cursorColor

                SequentialAnimation on opacity {
                    running: textArea.activeFocus
                    loops: Animation.Infinite
                    NumberAnimation { to: 1.0; duration: 0 }
                    PauseAnimation { duration: 530 }
                    NumberAnimation { to: 0.0; duration: 120 }
                    PauseAnimation { duration: 350 }
                }
            }

            Keys.onPressed: function(event) {
                // Intercept Ctrl+V when clipboard has an image
                if (event.key === Qt.Key_V && (event.modifiers & Qt.ControlModifier)) {
                    if (AppController.imageHandler.clipboardHasImage()) {
                        editorRoot.pasteImage()
                        event.accepted = true
                        return
                    }
                }
                if (event.key === Qt.Key_Tab) {
                    editorRoot.handleTab(event.modifiers & Qt.ShiftModifier)
                    event.accepted = true
                } else if (event.key === Qt.Key_Backtab) {
                    editorRoot.handleTab(true)
                    event.accepted = true
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    if (!(event.modifiers & Qt.ShiftModifier)
                        && !(event.modifiers & Qt.ControlModifier)) {
                        editorRoot.handleEnter()
                        event.accepted = true
                    }
                } else if (event.key === Qt.Key_B && (event.modifiers & Qt.ControlModifier)) {
                    mdToolbar.wrapSelection("**", "**")
                    event.accepted = true
                } else if (event.key === Qt.Key_I && (event.modifiers & Qt.ControlModifier)) {
                    mdToolbar.wrapSelection("*", "*")
                    event.accepted = true
                } else if (event.key === Qt.Key_K && (event.modifiers & Qt.ControlModifier)
                           && (event.modifiers & Qt.ShiftModifier)) {
                    mdToolbar.wrapSelection("`", "`")
                    event.accepted = true
                } else if (event.key === Qt.Key_D && (event.modifiers & Qt.ControlModifier)) {
                    editorRoot.duplicateLine()
                    event.accepted = true
                } else if (!(event.modifiers & Qt.ControlModifier)) {
                    // Auto-close brackets and backticks
                    let pairs = { '(': ')', '[': ']', '{': '}', '`': '`' }
                    let ch = event.text
                    if (ch in pairs) {
                        let pos = textArea.cursorPosition
                        let sel = textArea.selectedText
                        if (sel.length > 0) {
                            let start = textArea.selectionStart
                            let end = textArea.selectionEnd
                            textArea.remove(start, end)
                            textArea.insert(start, ch + sel + pairs[ch])
                            textArea.select(start + 1, start + 1 + sel.length)
                        } else {
                            textArea.insert(pos, ch + pairs[ch])
                            textArea.cursorPosition = pos + 1
                        }
                        event.accepted = true
                    }
                }
            }

            TapHandler {
                acceptedButtons: Qt.RightButton
                onTapped: contextMenu.popup()
            }

            Menu {
                id: contextMenu

                MenuItem {
                    text: "Cut"
                    enabled: textArea.selectedText.length > 0
                    onTriggered: textArea.cut()
                }
                MenuItem {
                    text: "Copy"
                    enabled: textArea.selectedText.length > 0
                    onTriggered: textArea.copy()
                }
                MenuItem {
                    text: "Paste"
                    onTriggered: textArea.paste()
                }
                MenuItem {
                    text: "Select All"
                    onTriggered: textArea.selectAll()
                }

                MenuSeparator {}

                MenuItem {
                    text: "Add as Block"
                    enabled: textArea.selectedText.length > 0
                    onTriggered: {
                        editorRoot.addBlockRequested(
                            textArea.selectedText,
                            textArea.selectionStart,
                            textArea.selectionEnd)
                    }
                }
                MenuItem {
                    text: "Create Prompt from Selection"
                    enabled: textArea.selectedText.length > 0
                    onTriggered: {
                        editorRoot.createPromptRequested(textArea.selectedText)
                    }
                }
            }
        }
    }

    // Drop overlay + DropArea for image drag-drop
    DropArea {
        anchors.fill: parent
        keys: ["text/uri-list"]

        onEntered: function(drag) {
            let dominated = false
            for (let i = 0; i < drag.urls.length; i++) {
                if (editorRoot.isImageUrl(drag.urls[i])) { dominated = true; break }
            }
            drag.accepted = dominated
            dropOverlay.visible = dominated
        }

        onExited: dropOverlay.visible = false

        onDropped: function(drop) {
            dropOverlay.visible = false
            for (let i = 0; i < drop.urls.length; i++) {
                if (editorRoot.isImageUrl(drop.urls[i]))
                    editorRoot.dropImage(drop.urls[i])
            }
        }
    }

    Rectangle {
        id: dropOverlay
        anchors.fill: parent
        visible: false
        color: Qt.rgba(0.42, 0.61, 0.82, 0.15)
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
}
