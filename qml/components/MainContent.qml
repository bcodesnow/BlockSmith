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

    // Is a JSONL file currently loaded?
    readonly property bool isJsonlActive: AppController.jsonlStore.filePath !== ""

    // Convenience: editor is visible in Edit or Split mode (and not JSONL)
    readonly property bool editorVisible: viewMode !== MainContent.ViewMode.Preview && !isJsonlActive

    // Current editor line (1-based), used by outline panel
    readonly property int currentLine: {
        if (viewMode === MainContent.ViewMode.Preview) return 0
        let pos = mdEditor.cursorPosition
        let content = AppController.currentDocument.rawContent
        if (!content || content.length === 0) return 0
        return content.substring(0, pos).split("\n").length
    }

    signal createPromptRequested(string content)

    function scrollToLine(lineNum) {
        if (viewMode === MainContent.ViewMode.Preview)
            viewMode = MainContent.ViewMode.Edit
        contentArea.scrollEditorToLine(lineNum)
    }

    function openFind() {
        if (AppController.currentDocument.filePath === "") return
        if (viewMode === MainContent.ViewMode.Preview)
            viewMode = MainContent.ViewMode.Edit
        findReplaceBar.openFind()
    }

    function openReplace() {
        if (AppController.currentDocument.filePath === "") return
        if (viewMode === MainContent.ViewMode.Preview)
            viewMode = MainContent.ViewMode.Edit
        findReplaceBar.openReplace()
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

    // Ctrl+MouseWheel zoom (on root so it doesn't interfere with ScrollView)
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
                    text: {
                        if (mainContent.isJsonlActive)
                            return AppController.jsonlStore.filePath
                        return AppController.currentDocument.filePath
                               ? AppController.currentDocument.filePath
                               : "No file open"
                    }
                    font.pixelSize: Theme.fontSizeM
                    color: Theme.textSecondary
                    elide: Text.ElideMiddle
                    Layout.fillWidth: true
                }

                // Modified indicator
                Label {
                    visible: AppController.currentDocument.modified && !mainContent.isJsonlActive
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
                    visible: !mainContent.isJsonlActive
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
                    visible: !mainContent.isJsonlActive
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
            Layout.preferredHeight: visible ? implicitHeight : 0

            onFindRequested: function(text, caseSensitive) {
                mainContent.performFind(text, caseSensitive, "next")
            }
            onFindNext: function(text, caseSensitive) {
                mainContent.findNext(text, caseSensitive)
            }
            onFindPrev: function(text, caseSensitive) {
                mainContent.findPrev(text, caseSensitive)
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

        // File changed externally banner
        Rectangle {
            id: fileChangedBanner
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? 32 : 0
            visible: false
            color: "#3d3520"
            property bool isDeleted: false

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                Label {
                    text: fileChangedBanner.isDeleted
                          ? "File was deleted from disk."
                          : "File changed on disk."
                    font.pixelSize: Theme.fontSizeS
                    color: Theme.accentGold
                    Layout.fillWidth: true
                }

                Button {
                    text: fileChangedBanner.isDeleted ? "Close" : "Reload"
                    flat: true
                    font.pixelSize: Theme.fontSizeXS
                    Layout.preferredHeight: 22
                    palette.buttonText: Theme.textPrimary
                    background: Rectangle {
                        color: parent.hovered ? Theme.bgButtonHov : Theme.bgButton
                        radius: Theme.radius
                        border.color: Theme.borderHover
                        border.width: 1
                    }
                    onClicked: {
                        if (fileChangedBanner.isDeleted)
                            AppController.currentDocument.clear()
                        else
                            AppController.currentDocument.reload()
                        fileChangedBanner.visible = false
                    }
                }

                Button {
                    visible: !fileChangedBanner.isDeleted
                    text: "Ignore"
                    flat: true
                    font.pixelSize: Theme.fontSizeXS
                    Layout.preferredHeight: 22
                    palette.buttonText: Theme.textSecondary
                    background: Rectangle {
                        color: parent.hovered ? Theme.bgButtonHov : "transparent"
                        radius: Theme.radius
                    }
                    onClicked: fileChangedBanner.visible = false
                }
            }
        }

        Connections {
            target: AppController.currentDocument
            function onFileChangedExternally() {
                fileChangedBanner.isDeleted = false
                fileChangedBanner.visible = true
            }
            function onFileDeletedExternally() {
                fileChangedBanner.isDeleted = true
                fileChangedBanner.visible = true
            }
            function onFilePathChanged() {
                fileChangedBanner.visible = false
            }
        }

        // Content area
        Item {
            id: contentArea
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Empty state
            Label {
                anchors.centerIn: parent
                visible: AppController.currentDocument.filePath === "" && !mainContent.isJsonlActive
                text: "Select a file from the project tree"
                font.pixelSize: 14
                color: Theme.textMuted
            }

            // JSONL viewer (replaces editor when .jsonl is open)
            JsonlViewer {
                anchors.fill: parent
                visible: mainContent.isJsonlActive
            }

            SplitView {
                id: editorSplitView
                anchors.fill: parent
                orientation: Qt.Horizontal
                visible: AppController.currentDocument.filePath !== "" && !mainContent.isJsonlActive

                handle: Rectangle {
                    implicitWidth: 6
                    implicitHeight: 6
                    color: "transparent"

                    Rectangle {
                        anchors.centerIn: parent
                        width: 2
                        height: parent.height
                        color: SplitHandle.pressed ? Theme.accent
                             : SplitHandle.hovered ? Theme.borderHover
                             : Theme.border
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

            // --- Scroll sync infrastructure ---

            // Anti-feedback-loop guard: prevents infinite scroll loops
            // between editor and preview in bidirectional sync
            QtObject {
                id: scrollSyncGuard
                property bool syncing: false
            }

            // Releases the sync guard after scroll animation settles
            Timer {
                id: scrollSyncTimer
                interval: 120
                onTriggered: scrollSyncGuard.syncing = false
            }

            // Debounced editor-to-preview scroll sync (line-based)
            Timer {
                id: editorScrollSyncTimer
                interval: 150
                onTriggered: {
                    if (scrollSyncGuard.syncing) return
                    scrollSyncGuard.syncing = true

                    // Calculate which source line is at the top of the visible area
                    let pos = mdEditor.textArea.positionAt(0, mdEditor.scrollFlickable.contentY)
                    let content = mdEditor.textArea.text
                    let lineNum = content.substring(0, pos).split("\n").length
                    mdPreview.scrollToLine(lineNum)

                    scrollSyncTimer.restart()
                }
            }

            // Editor scroll -> preview (debounced)
            Connections {
                target: mdEditor.scrollFlickable
                enabled: mainContent.viewMode === MainContent.ViewMode.Split
                function onContentYChanged() {
                    editorScrollSyncTimer.restart()
                }
            }

            // Preview scroll -> editor (via WebChannel bridge)
            Connections {
                target: mdPreview.scrollBridge
                enabled: mainContent.viewMode === MainContent.ViewMode.Split
                function onPreviewScrolled(percent) {
                    if (scrollSyncGuard.syncing) return
                    scrollSyncGuard.syncing = true
                    let ef = mdEditor.scrollFlickable
                    if (!ef) return
                    let maxY = Math.max(1, ef.contentHeight - ef.height)
                    ef.contentY = Math.max(0, Math.min(percent * maxY, maxY))
                    scrollSyncTimer.restart()
                }
            }

            // Heading click in preview -> scroll editor to heading
            Connections {
                target: mdPreview.scrollBridge
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

                // Temporarily set guard to prevent cursor change from syncing back
                scrollSyncGuard.syncing = true

                // Move cursor to that line
                mdEditor.textArea.cursorPosition = offset

                // Scroll the editor to make that line visible
                let rect = mdEditor.textArea.positionToRectangle(offset)
                mdEditor.ensureVisible(rect.y)

                scrollSyncTimer.restart()
            }
        }

        // Status bar (markdown files only)
        EditorStatusBar {
            visible: AppController.currentDocument.filePath !== "" && !mainContent.isJsonlActive
            viewMode: mainContent.viewMode
            editorCursorPosition: mdEditor.cursorPosition
        }
    }
}
