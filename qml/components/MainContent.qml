import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import BlockSmith

Rectangle {
    id: mainContent
    color: "#1e1e1e"

    property bool editMode: true
    property int editorCursorPosition: mdEditor.cursorPosition

    signal createPromptRequested(string content)

    function openFind() {
        if (mainContent.editMode && AppController.currentDocument.filePath !== "") {
            findReplaceBar.openFind()
        }
    }

    function openReplace() {
        if (mainContent.editMode && AppController.currentDocument.filePath !== "") {
            findReplaceBar.openReplace()
        }
    }

    // Find/replace logic
    property var findMatches: []
    property int findMatchIndex: -1

    function performFind(text, caseSensitive, direction) {
        if (text.length === 0) {
            findMatches = []
            findMatchIndex = -1
            findReplaceBar.matchCount = 0
            findReplaceBar.currentMatch = 0
            return
        }

        let content = mdEditor.textArea.text
        let matches = []
        let searchFrom = 0
        let flags = caseSensitive ? "" : "gi"
        let escaped = text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
        let rx = new RegExp(escaped, caseSensitive ? "g" : "gi")
        let m

        while ((m = rx.exec(content)) !== null) {
            matches.push({ start: m.index, end: m.index + m[0].length })
        }

        findMatches = matches
        findReplaceBar.matchCount = matches.length

        if (matches.length === 0) {
            findMatchIndex = -1
            findReplaceBar.currentMatch = 0
            return
        }

        // Find the match closest to current cursor
        let cursorPos = mdEditor.textArea.cursorPosition
        let bestIdx = 0

        if (direction === "next") {
            for (let i = 0; i < matches.length; i++) {
                if (matches[i].start >= cursorPos) {
                    bestIdx = i
                    break
                }
                if (i === matches.length - 1) bestIdx = 0 // wrap
            }
        } else {
            bestIdx = matches.length - 1
            for (let i = matches.length - 1; i >= 0; i--) {
                if (matches[i].start < cursorPos - 1) {
                    bestIdx = i
                    break
                }
                if (i === 0) bestIdx = matches.length - 1 // wrap
            }
        }

        findMatchIndex = bestIdx
        findReplaceBar.currentMatch = bestIdx + 1
        selectMatch(bestIdx)
    }

    function selectMatch(idx) {
        if (idx < 0 || idx >= findMatches.length) return
        let match = findMatches[idx]
        mdEditor.textArea.select(match.start, match.end)
        mdEditor.textArea.forceActiveFocus()
    }

    function findNext(text, caseSensitive) {
        if (findMatches.length > 0 && findMatchIndex >= 0) {
            findMatchIndex = (findMatchIndex + 1) % findMatches.length
            findReplaceBar.currentMatch = findMatchIndex + 1
            selectMatch(findMatchIndex)
        } else {
            performFind(text, caseSensitive, "next")
        }
    }

    function findPrev(text, caseSensitive) {
        if (findMatches.length > 0 && findMatchIndex >= 0) {
            findMatchIndex = (findMatchIndex - 1 + findMatches.length) % findMatches.length
            findReplaceBar.currentMatch = findMatchIndex + 1
            selectMatch(findMatchIndex)
        } else {
            performFind(text, caseSensitive, "prev")
        }
    }

    function replaceOne(findText, replaceText, caseSensitive) {
        if (findMatchIndex < 0 || findMatchIndex >= findMatches.length) return
        let match = findMatches[findMatchIndex]
        let content = mdEditor.textArea.text
        let before = content.substring(0, match.start)
        let after = content.substring(match.end)
        mdEditor.textArea.text = before + replaceText + after
        // Re-search
        performFind(findText, caseSensitive, "next")
    }

    function replaceAll(findText, replaceText, caseSensitive) {
        if (findText.length === 0) return
        let escaped = findText.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
        let rx = new RegExp(escaped, caseSensitive ? "g" : "gi")
        mdEditor.textArea.text = mdEditor.textArea.text.replace(rx, replaceText)
        performFind(findText, caseSensitive, "next")
    }

    AddBlockDialog {
        id: addBlockDialog
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Toolbar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            color: "#333333"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 4

                // File path
                Label {
                    text: AppController.currentDocument.filePath
                          ? AppController.currentDocument.filePath
                          : "No file open"
                    font.pixelSize: 12
                    color: "#999"
                    elide: Text.ElideMiddle
                    Layout.fillWidth: true
                }

                // Modified indicator
                Label {
                    visible: AppController.currentDocument.modified
                    text: "\u25CF"
                    font.pixelSize: 10
                    color: "#e0c060"
                    ToolTip.text: "Unsaved changes"
                    ToolTip.visible: modifiedMa.containsMouse
                    MouseArea {
                        id: modifiedMa
                        anchors.fill: parent
                        hoverEnabled: true
                    }
                }

                // Edit / Preview toggle
                Rectangle {
                    Layout.preferredWidth: editBtn.implicitWidth + previewBtn.implicitWidth + 2
                    Layout.preferredHeight: 24
                    color: "#2b2b2b"
                    radius: 3

                    RowLayout {
                        anchors.fill: parent
                        spacing: 0

                        Button {
                            id: editBtn
                            text: "Edit"
                            flat: true
                            font.pixelSize: 11
                            Layout.preferredHeight: 24
                            palette.buttonText: mainContent.editMode ? "#fff" : "#999"
                            background: Rectangle {
                                color: mainContent.editMode ? "#3d6a99" : "transparent"
                                radius: 3
                            }
                            onClicked: mainContent.editMode = true
                        }

                        Button {
                            id: previewBtn
                            text: "Preview"
                            flat: true
                            font.pixelSize: 11
                            Layout.preferredHeight: 24
                            palette.buttonText: !mainContent.editMode ? "#fff" : "#999"
                            background: Rectangle {
                                color: !mainContent.editMode ? "#3d6a99" : "transparent"
                                radius: 3
                            }
                            onClicked: mainContent.editMode = false
                        }
                    }
                }

                // Save button
                Button {
                    text: "Save"
                    flat: true
                    font.pixelSize: 11
                    enabled: AppController.currentDocument.modified
                    Layout.preferredHeight: 24
                    palette.buttonText: enabled ? "#ccc" : "#666"
                    background: Rectangle {
                        color: parent.hovered && parent.enabled ? "#555" : "#3a3a3a"
                        radius: 3
                        border.color: "#555"
                        border.width: 1
                    }
                    onClicked: AppController.currentDocument.save()
                }
            }
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: "#444"
        }

        // Find/Replace bar
        FindReplaceBar {
            id: findReplaceBar
            Layout.fillWidth: true

            onFindNext: function(text, caseSensitive) {
                mainContent.performFind(text, caseSensitive, "next")
            }
            onFindPrev: function(text, caseSensitive) {
                if (mainContent.findMatches.length > 0 && mainContent.findMatchIndex >= 0) {
                    mainContent.findMatchIndex = (mainContent.findMatchIndex - 1 + mainContent.findMatches.length) % mainContent.findMatches.length
                    findReplaceBar.currentMatch = mainContent.findMatchIndex + 1
                    mainContent.selectMatch(mainContent.findMatchIndex)
                } else {
                    mainContent.performFind(text, caseSensitive, "prev")
                }
            }
            onReplaceOne: function(findText, replaceText, caseSensitive) {
                mainContent.replaceOne(findText, replaceText, caseSensitive)
            }
            onReplaceAll: function(findText, replaceText, caseSensitive) {
                mainContent.replaceAll(findText, replaceText, caseSensitive)
            }
            onClosed: {
                mainContent.findMatches = []
                mainContent.findMatchIndex = -1
            }
        }

        // Content area
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Empty state
            Label {
                anchors.centerIn: parent
                visible: AppController.currentDocument.filePath === ""
                text: "Select a file from the project tree"
                font.pixelSize: 14
                color: "#666"
            }

            MdEditor {
                id: mdEditor
                anchors.fill: parent
                visible: mainContent.editMode && AppController.currentDocument.filePath !== ""
                text: AppController.currentDocument.rawContent
                readOnly: false
                textArea.onTextChanged: {
                    if (textArea.text !== AppController.currentDocument.rawContent) {
                        AppController.currentDocument.rawContent = textArea.text
                    }
                }
                onAddBlockRequested: function(selectedText, selStart, selEnd) {
                    addBlockDialog.selectedText = selectedText
                    addBlockDialog.selectionStart = selStart
                    addBlockDialog.selectionEnd = selEnd
                    addBlockDialog.open()
                }
                onCreatePromptRequested: function(selectedText) {
                    mainContent.createPromptRequested(selectedText)
                }
            }

            MdPreview {
                anchors.fill: parent
                visible: !mainContent.editMode && AppController.currentDocument.filePath !== ""
                markdown: AppController.currentDocument.rawContent
            }
        }

        // Status bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 22
            color: "#252525"
            visible: AppController.currentDocument.filePath !== ""

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 16

                Label {
                    text: {
                        if (!mainContent.editMode) return "Preview mode"
                        let pos = mdEditor.cursorPosition
                        let content = AppController.currentDocument.rawContent
                        let line = content.substring(0, pos).split("\n").length
                        let lastNl = content.lastIndexOf("\n", pos - 1)
                        let col = pos - (lastNl >= 0 ? lastNl : 0)
                        return "Ln " + line + ", Col " + col
                    }
                    font.pixelSize: 10
                    color: "#888"
                }

                Item { Layout.fillWidth: true }

                Label {
                    text: {
                        let c = AppController.currentDocument.rawContent
                        if (!c || c.length === 0) return ""
                        let chars = c.length
                        let words = c.trim().length === 0 ? 0 : c.trim().split(/\s+/).length
                        let lines = c.split("\n").length
                        return words + " words, " + chars + " chars, " + lines + " lines"
                    }
                    font.pixelSize: 10
                    color: "#777"
                }
            }
        }
    }
}
