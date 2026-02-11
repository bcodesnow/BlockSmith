import QtQuick
import QtQuick.Controls
import BlockSmith

Item {
    id: editorRoot

    property alias text: textArea.text
    property alias readOnly: textArea.readOnly
    property alias textArea: textArea
    property alias cursorPosition: textArea.cursorPosition

    signal addBlockRequested(string selectedText, int selStart, int selEnd)
    signal createPromptRequested(string selectedText)

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

    // Block line ranges computed by scanning the text directly (no position conversion)
    property var blockRanges: {
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

    // Line number gutter
    Rectangle {
        id: gutter
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 48
        color: "#1a1a1a"
        clip: true
        z: 2

        // Right border
        Rectangle {
            anchors.right: parent.right
            width: 1
            height: parent.height
            color: "#333"
        }

        Column {
            id: lineNumberCol
            y: -scrollView.contentItem.contentY + textArea.topPadding

            Repeater {
                model: Math.max(1, (textArea.text || "").split("\n").length)

                delegate: Item {
                    width: gutter.width - 4
                    height: fm.lineSpacing

                    // Block region indicator strip (left edge)
                    Rectangle {
                        id: blockStrip
                        width: 4
                        height: parent.height
                        anchors.left: parent.left

                        property var blockInfo: editorRoot.blockAtLine(index + 1)

                        color: {
                            if (!blockInfo) return "transparent"
                            if (blockInfo.status === "synced") return "#4caf50"
                            if (blockInfo.status === "diverged") return "#ff9800"
                            return "#6c9bd2" // local
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
                        color: (index + 1) === gutter.currentLine ? "#eee" : "#aaa"
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
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        TextArea {
            id: textArea
            font.family: "Consolas"
            font.pixelSize: 13
            wrapMode: TextArea.Wrap
            tabStopDistance: 28
            selectByMouse: true
            placeholderText: "Select a file to begin editing."

            background: Rectangle {
                color: "#1e1e1e"
            }

            color: "#d4d4d4"
            selectionColor: "#264f78"
            selectedTextColor: "#ffffff"
            placeholderTextColor: "#666"

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
}
