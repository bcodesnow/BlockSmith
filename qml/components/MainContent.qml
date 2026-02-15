import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import BlockSmith

Rectangle {
    id: mainContent
    color: Theme.bg

    enum ViewMode { Edit, Preview, Split }
    property int viewMode: MainContent.ViewMode.Edit
    property int editorCursorPosition: mdEditor.cursorPosition

    // Convenience: editor is visible in Edit or Split mode
    readonly property bool editorVisible: viewMode !== MainContent.ViewMode.Preview

    signal createPromptRequested(string content)

    function openFind() {
        if (mainContent.editorVisible && AppController.currentDocument.filePath !== "") {
            findReplaceBar.openFind()
        }
    }

    function openReplace() {
        if (mainContent.editorVisible && AppController.currentDocument.filePath !== "") {
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
        // Scroll to match
        let rect = mdEditor.textArea.positionToRectangle(match.start)
        mdEditor.ensureVisible(rect.y)
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
        mdEditor.textArea.remove(match.start, match.end)
        mdEditor.textArea.insert(match.start, replaceText)
        // Re-search
        performFind(findText, caseSensitive, "next")
    }

    function replaceAll(findText, replaceText, caseSensitive) {
        if (findText.length === 0) return
        if (findMatches.length === 0) return
        // Replace in reverse order to preserve positions
        for (let i = findMatches.length - 1; i >= 0; i--) {
            let match = findMatches[i]
            mdEditor.textArea.remove(match.start, match.end)
            mdEditor.textArea.insert(match.start, replaceText)
        }
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
            Layout.preferredHeight: Theme.headerHeight
            color: Theme.bgHeader

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
                    font.pixelSize: Theme.fontSizeM
                    color: Theme.textSecondary
                    elide: Text.ElideMiddle
                    Layout.fillWidth: true
                }

                // Modified indicator
                Label {
                    visible: AppController.currentDocument.modified
                    text: "\u25CF"
                    font.pixelSize: Theme.fontSizeS
                    color: Theme.accentGold
                    ToolTip.text: "Unsaved changes"
                    ToolTip.visible: modifiedMa.containsMouse
                    MouseArea {
                        id: modifiedMa
                        anchors.fill: parent
                        hoverEnabled: true
                    }
                }

                // Edit / Split / Preview toggle
                Rectangle {
                    Layout.preferredWidth: modeRow.implicitWidth + 4
                    Layout.preferredHeight: 24
                    color: Theme.bgPanel
                    radius: Theme.radius

                    RowLayout {
                        id: modeRow
                        anchors.fill: parent
                        spacing: 0

                        component ModeBtn: Button {
                            required property int mode
                            flat: true
                            font.pixelSize: Theme.fontSizeXS
                            Layout.preferredHeight: 24
                            palette.buttonText: mainContent.viewMode === mode ? Theme.textWhite : Theme.textSecondary
                            background: Rectangle {
                                color: mainContent.viewMode === mode ? Theme.bgActive : "transparent"
                                radius: Theme.radius
                            }
                            onClicked: mainContent.viewMode = mode
                        }

                        ModeBtn { text: "Edit"; mode: MainContent.ViewMode.Edit }
                        ModeBtn { text: "Split"; mode: MainContent.ViewMode.Split }
                        ModeBtn { text: "Preview"; mode: MainContent.ViewMode.Preview }
                    }
                }

                // Toolbar toggle
                Rectangle {
                    width: 26; height: 24; radius: Theme.radius
                    color: toolbarToggleMa.containsMouse ? Theme.bgButtonHov : "transparent"
                    visible: mainContent.editorVisible
                    ToolTip.text: AppController.configManager.markdownToolbarVisible ? "Hide toolbar" : "Show toolbar"
                    ToolTip.visible: toolbarToggleMa.containsMouse
                    ToolTip.delay: 400

                    Label {
                        anchors.centerIn: parent
                        text: "\u2261"
                        font.pixelSize: 16
                        color: AppController.configManager.markdownToolbarVisible ? Theme.textPrimary : Theme.textMuted
                    }
                    MouseArea {
                        id: toolbarToggleMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            AppController.configManager.markdownToolbarVisible = !AppController.configManager.markdownToolbarVisible
                        }
                    }
                }

                // Save button
                Button {
                    text: "Save"
                    flat: true
                    font.pixelSize: Theme.fontSizeXS
                    enabled: AppController.currentDocument.modified
                    Layout.preferredHeight: 24
                    palette.buttonText: enabled ? Theme.textPrimary : Theme.textMuted
                    background: Rectangle {
                        color: parent.hovered && parent.enabled ? Theme.bgButtonHov : Theme.bgButton
                        radius: Theme.radius
                        border.color: Theme.borderHover
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
            color: Theme.border
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
                color: Theme.textMuted
            }

            SplitView {
                id: editorSplitView
                anchors.fill: parent
                orientation: Qt.Horizontal
                visible: AppController.currentDocument.filePath !== ""

                handle: Rectangle {
                    implicitWidth: 3
                    implicitHeight: 3
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
                    text: AppController.currentDocument.rawContent
                    readOnly: false
                    toolbarVisible: mainContent.editorVisible && AppController.configManager.markdownToolbarVisible
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

                MdPreviewWeb {
                    id: mdPreview
                    visible: mainContent.viewMode !== MainContent.ViewMode.Edit
                    SplitView.fillWidth: true
                    SplitView.minimumWidth: 200
                    markdown: AppController.currentDocument.rawContent
                }
            }

            // Scroll sync: editor → preview (split mode only)
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
        }

        // Status bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 22
            color: Theme.bgFooter
            visible: AppController.currentDocument.filePath !== ""

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 16

                Label {
                    text: {
                        if (mainContent.viewMode === MainContent.ViewMode.Preview) return "Preview mode"
                        let pos = mdEditor.cursorPosition
                        let content = AppController.currentDocument.rawContent
                        let line = content.substring(0, pos).split("\n").length
                        let lastNl = content.lastIndexOf("\n", pos - 1)
                        let col = pos - (lastNl >= 0 ? lastNl : 0)
                        return "Ln " + line + ", Col " + col
                    }
                    font.pixelSize: Theme.fontSizeS
                    color: Theme.textMuted
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
                    font.pixelSize: Theme.fontSizeS
                    color: Theme.textMuted
                }
            }
        }
    }
}
