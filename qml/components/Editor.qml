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

    // --- Editing helpers ---

    function lineStartOf(pos) {
        let t = textArea.text
        let i = pos - 1
        while (i >= 0 && t[i] !== '\n') i--
        return i + 1
    }

    function lineEndOf(pos) {
        let t = textArea.text
        let i = pos
        while (i < t.length && t[i] !== '\n') i++
        return i
    }

    function handleTab(shift) {
        let selStart = textArea.selectionStart
        let selEnd = textArea.selectionEnd
        let hasSelection = selStart !== selEnd

        if (!hasSelection && !shift) {
            textArea.insert(textArea.cursorPosition, "    ")
            return
        }

        let lineStart = lineStartOf(selStart)
        let lineEnd = lineEndOf(selEnd > selStart ? selEnd - 1 : selEnd)
        let block = textArea.text.substring(lineStart, lineEnd)
        let lines = block.split("\n")
        let newLines = []

        if (shift) {
            for (let i = 0; i < lines.length; i++) {
                let line = lines[i]
                let remove = 0
                while (remove < 4 && remove < line.length && line[remove] === ' ') remove++
                newLines.push(line.substring(remove))
            }
        } else {
            for (let i = 0; i < lines.length; i++) {
                newLines.push("    " + lines[i])
            }
        }

        let result = newLines.join("\n")
        textArea.remove(lineStart, lineEnd)
        textArea.insert(lineStart, result)
        textArea.select(lineStart, lineStart + result.length)
    }

    function handleEnter() {
        let pos = textArea.cursorPosition
        let lineStart = lineStartOf(pos)
        let lineText = textArea.text.substring(lineStart, pos)

        let listMatch = lineText.match(/^(\s*)([-*+])\s(\[[ x]\]\s)?/)
        let orderedMatch = lineText.match(/^(\s*)(\d+)\.\s/)

        if (listMatch) {
            let indent = listMatch[1]
            let bullet = listMatch[2]
            let checkbox = listMatch[3] || ""
            let content = lineText.substring(listMatch[0].length)

            if (content.trim().length === 0) {
                textArea.remove(lineStart, pos)
                return
            }

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
                textArea.remove(lineStart, pos)
                return
            }

            let prefix = indent + (num + 1) + ". "
            textArea.insert(pos, "\n" + prefix)
            textArea.cursorPosition = pos + 1 + prefix.length
            return
        }

        textArea.insert(pos, "\n")
        textArea.cursorPosition = pos + 1
    }

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

    // Unified syntax highlighter
    SyntaxHighlighter {
        id: highlighter
        document: textArea.textDocument
        enabled: AppController.configManager.syntaxHighlightEnabled
        isDarkTheme: AppController.configManager.themeMode === "dark"
        mode: {
            switch (AppController.currentDocument.syntaxMode) {
            case Document.SyntaxMarkdown: return SyntaxHighlighter.Markdown
            case Document.SyntaxJson:     return SyntaxHighlighter.Json
            case Document.SyntaxYaml:     return SyntaxHighlighter.Yaml
            default:                  return SyntaxHighlighter.PlainText
            }
        }
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

    // Block store revision tracking
    property int blockStoreRevision: 0
    Connections {
        target: AppController.blockStore
        function onBlockUpdated() { editorRoot.blockStoreRevision++ }
        function onCountChanged() { editorRoot.blockStoreRevision++ }
    }

    property var blockRanges: []

    Timer {
        id: blockRangesTimer
        interval: 100
        onTriggered: editorRoot.blockRanges = AppController.currentDocument.computeBlockRanges()
    }

    onBlockStoreRevisionChanged: blockRangesTimer.restart()

    Connections {
        id: blockRangesConn
        target: textArea
        function onTextChanged() { blockRangesTimer.restart() }
    }

    // Toolbar loader
    Loader {
        id: toolbarLoader
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        active: editorRoot.toolbarVisible
        sourceComponent: {
            switch (AppController.currentDocument.toolbarKind) {
            case Document.ToolbarMarkdown: return mdToolbarComponent
            case Document.ToolbarJson:     return jsonToolbarComponent
            case Document.ToolbarYaml:     return yamlToolbarComponent
            default:                  return null
            }
        }
    }

    Component {
        id: mdToolbarComponent
        MdToolbar { targetArea: textArea }
    }

    Component {
        id: jsonToolbarComponent
        JsonToolbar { }
    }

    Component {
        id: yamlToolbarComponent
        YamlToolbar { }
    }

    property Item activeToolbar: toolbarLoader.item

    // Line number gutter
    LineNumberGutter {
        id: gutter
        anchors.left: parent.left
        anchors.top: toolbarLoader.active && toolbarLoader.item ? toolbarLoader.bottom : parent.top
        anchors.bottom: parent.bottom
        textArea: textArea
        lineHeights: editorRoot.lineHeights
        blockRanges: editorRoot.blockRanges
        fontMetrics: fm
        scrollY: scrollView.contentItem.contentY
        textTopPadding: textArea.topPadding
    }

    ScrollView {
        id: scrollView
        anchors.left: gutter.right
        anchors.right: parent.right
        anchors.top: toolbarLoader.active && toolbarLoader.item ? toolbarLoader.bottom : parent.top
        anchors.bottom: parent.bottom

        // Current line highlight
        Rectangle {
            id: currentLineHighlight
            width: scrollView.width
            height: {
                let lineIdx = gutter.currentLine - 1
                return editorRoot.lineHeights[lineIdx] || fm.lineSpacing
            }
            y: {
                void(scrollView.contentItem.contentY)
                let rect = textArea.positionToRectangle(textArea.cursorPosition)
                return textArea.mapToItem(scrollView, 0, rect.y).y
            }
            color: Theme.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.06)
            z: -1
        }

        TextArea {
            id: textArea
            font.family: Theme.fontMono
            font.pixelSize: Theme.fontSizeLZoomed
            wrapMode: AppController.configManager.wordWrap ? TextArea.Wrap : TextArea.NoWrap
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
                    id: cursorBlink
                    running: textArea.activeFocus
                    loops: Animation.Infinite
                    NumberAnimation { to: 1.0; duration: 0 }
                    PauseAnimation { duration: 530 }
                    NumberAnimation { to: 0.0; duration: 120 }
                    PauseAnimation { duration: 350 }
                }

                Connections {
                    target: textArea
                    function onActiveFocusChanged() {
                        if (textArea.activeFocus) {
                            cursorBlink.restart()
                        }
                    }
                }
            }

            Keys.onPressed: function(event) {
                let isMd = AppController.currentDocument.syntaxMode === Document.SyntaxMarkdown

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
                    if (isMd && !(event.modifiers & Qt.ShiftModifier)
                        && !(event.modifiers & Qt.ControlModifier)) {
                        editorRoot.handleEnter()
                        event.accepted = true
                    }
                } else if (isMd && event.key === Qt.Key_B && (event.modifiers & Qt.ControlModifier)) {
                    if (toolbarLoader.item && toolbarLoader.item.wrapSelection)
                        toolbarLoader.item.wrapSelection("**", "**")
                    event.accepted = true
                } else if (isMd && event.key === Qt.Key_I && (event.modifiers & Qt.ControlModifier)) {
                    if (toolbarLoader.item && toolbarLoader.item.wrapSelection)
                        toolbarLoader.item.wrapSelection("*", "*")
                    event.accepted = true
                } else if (isMd && event.key === Qt.Key_K && (event.modifiers & Qt.ControlModifier)
                           && (event.modifiers & Qt.ShiftModifier)) {
                    if (toolbarLoader.item && toolbarLoader.item.wrapSelection)
                        toolbarLoader.item.wrapSelection("`", "`")
                    event.accepted = true
                } else if (event.key === Qt.Key_D && (event.modifiers & Qt.ControlModifier)) {
                    editorRoot.duplicateLine()
                    event.accepted = true
                } else if (!(event.modifiers & Qt.ControlModifier)) {
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

            EditorContextMenu {
                id: contextMenu
                textArea: textArea
                onAddBlockRequested: function(selectedText, selStart, selEnd) {
                    editorRoot.addBlockRequested(selectedText, selStart, selEnd)
                }
                onCreatePromptRequested: function(selectedText) {
                    editorRoot.createPromptRequested(selectedText)
                }
            }
        }
    }

    ImageDropZone {
        anchors.fill: parent
        onImageDropped: function(fileUrl) { editorRoot.dropImage(fileUrl) }
    }
}
