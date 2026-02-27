import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import BlockSmith

Rectangle {
    id: mainContent
    color: Theme.bg

    enum ViewMode { Edit, Split, Preview }
    property int viewMode: MainContent.ViewMode.Edit
    property int editorCursorPosition: editor.cursorPosition
    readonly property bool hasPreviewPane: !isJsonlActive && !isPdfActive
        && AppController.currentDocument.previewKind === Document.PreviewMarkdown
    readonly property bool hasEditorToolbar:
        AppController.currentDocument.toolbarKind !== Document.ToolbarNone

    // Is a JSONL file currently loaded?
    readonly property bool isJsonlActive: AppController.jsonlStore.filePath !== ""

    // Is a PDF file currently loaded?
    readonly property bool isPdfActive: AppController.currentDocument.previewKind === Document.PreviewPdf

    // Convenience: editor is visible in Edit or Split mode (and not JSONL/PDF)
    readonly property bool editorVisible: viewMode !== MainContent.ViewMode.Preview
        && !isJsonlActive && !isPdfActive

    // Current editor line (1-based), used by outline panel
    readonly property int currentLine: {
        if (viewMode === MainContent.ViewMode.Preview) return 0
        let pos = editor.cursorPosition
        let content = editor.textArea.text
        if (!content || content.length === 0) return 0
        return content.substring(0, pos).split("\n").length
    }

    signal createPromptRequested(string content)
    signal notifyRequested(string message)

    onHasPreviewPaneChanged: {
        if (!hasPreviewPane && viewMode !== MainContent.ViewMode.Edit)
            viewMode = MainContent.ViewMode.Edit
    }

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

    function cycleViewMode() {
        if (!hasPreviewPane) {
            viewMode = MainContent.ViewMode.Edit
            return
        }
        if (viewMode === MainContent.ViewMode.Edit)
            viewMode = MainContent.ViewMode.Split
        else if (viewMode === MainContent.ViewMode.Split)
            viewMode = MainContent.ViewMode.Preview
        else
            viewMode = MainContent.ViewMode.Edit
    }

    FindReplaceController {
        id: findCtrl
        editor: editor
        bar: findReplaceBar
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

        EditorHeader {
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.headerHeight
            viewMode: mainContent.viewMode
            editorVisible: mainContent.editorVisible
            hasPreviewPane: mainContent.hasPreviewPane
            isJsonlActive: mainContent.isJsonlActive
            editorTextArea: editor.textArea
            onViewModeSelected: function(mode) { mainContent.viewMode = mode }
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
                findCtrl.performFind(text, caseSensitive, "next")
            }
            onFindNext: function(text, caseSensitive) {
                findCtrl.findNext(text, caseSensitive)
            }
            onFindPrev: function(text, caseSensitive) {
                findCtrl.findPrev(text, caseSensitive)
            }
            onReplaceOne: function(findText, replaceText, caseSensitive) {
                findCtrl.replaceOne(findText, replaceText, caseSensitive)
            }
            onReplaceAll: function(findText, replaceText, caseSensitive) {
                findCtrl.replaceAll(findText, replaceText, caseSensitive)
            }
            onClosed: findCtrl.clear()
        }

        FileChangedBanner {
            id: fileChangedBanner
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? 32 : 0
            onFilePathChanged: {
                if (!mainContent.hasPreviewPane)
                    mainContent.viewMode = MainContent.ViewMode.Edit
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

            // PDF viewer (replaces editor when .pdf is open)
            PdfViewer {
                anchors.fill: parent
                visible: mainContent.isPdfActive
            }

            SplitView {
                id: editorSplitView
                anchors.fill: parent
                orientation: Qt.Horizontal
                visible: AppController.currentDocument.filePath !== ""
                    && !mainContent.isJsonlActive && !mainContent.isPdfActive

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

                Editor {
                    id: editor
                    visible: mainContent.viewMode !== MainContent.ViewMode.Preview
                    SplitView.fillWidth: mainContent.viewMode === MainContent.ViewMode.Edit
                    SplitView.preferredWidth: editorSplitView.width / 2
                    SplitView.minimumWidth: 200
                    text: AppController.currentDocument.rawContent
                    readOnly: false
                    toolbarVisible: mainContent.editorVisible && mainContent.hasEditorToolbar
                                    && AppController.configManager.editorToolbarVisible

                    textArea.onTextChanged: {
                        if (textArea.text !== AppController.currentDocument.rawContent)
                            AppController.currentDocument.rawContent = textArea.text
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
                    onNotify: function(message) {
                        mainContent.notifyRequested(message)
                    }
                }

                MdPreviewWeb {
                    id: mdPreview
                    visible: mainContent.viewMode !== MainContent.ViewMode.Edit
                             && mainContent.hasPreviewPane
                    SplitView.fillWidth: true
                    SplitView.minimumWidth: 200
                    markdown: editor.textArea.text
                }
            }

            // --- Scroll sync infrastructure ---

            QtObject {
                id: scrollSyncGuard
                property bool syncing: false
            }

            Timer {
                id: scrollSyncTimer
                interval: 120
                onTriggered: scrollSyncGuard.syncing = false
            }

            Timer {
                id: editorScrollSyncTimer
                interval: 150
                onTriggered: {
                    if (scrollSyncGuard.syncing || !mainContent.hasPreviewPane) return
                    scrollSyncGuard.syncing = true

                    let pos = editor.textArea.positionAt(0, editor.scrollFlickable.contentY)
                    let content = editor.textArea.text
                    let lineNum = content.substring(0, pos).split("\n").length
                    mdPreview.scrollToLine(lineNum)

                    scrollSyncTimer.restart()
                }
            }

            Connections {
                target: editor.scrollFlickable
                enabled: mainContent.viewMode === MainContent.ViewMode.Split
                         && mainContent.hasPreviewPane
                function onContentYChanged() {
                    editorScrollSyncTimer.restart()
                }
            }

            Connections {
                target: mdPreview.scrollBridge
                enabled: mainContent.viewMode === MainContent.ViewMode.Split
                         && mainContent.hasPreviewPane
                function onPreviewScrolled(percent) {
                    if (scrollSyncGuard.syncing) return
                    scrollSyncGuard.syncing = true
                    let ef = editor.scrollFlickable
                    if (!ef) return
                    let maxY = Math.max(1, ef.contentHeight - ef.height)
                    ef.contentY = Math.max(0, Math.min(percent * maxY, maxY))
                    scrollSyncTimer.restart()
                }
            }

            Connections {
                target: mdPreview.scrollBridge
                enabled: mainContent.hasPreviewPane
                function onHeadingClicked(sourceLine, text) {
                    if (sourceLine > 0) {
                        scrollEditorToLine(sourceLine)
                        return
                    }

                    let content = editor.textArea.text
                    let lines = content.split("\n")
                    for (let i = 0; i < lines.length; i++) {
                        let stripped = lines[i].replace(/^#+\s*/, "").trim()
                        if (stripped === text) {
                            scrollEditorToLine(i + 1)
                            return
                        }
                    }
                }
            }

            Connections {
                target: AppController
                function onNavigateToLineRequested(lineNumber) {
                    if (!mainContent.isJsonlActive && lineNumber > 0) {
                        Qt.callLater(function() {
                            mainContent.scrollToLine(lineNumber)
                        })
                    }
                }
            }

            function scrollEditorToLine(lineNum) {
                let content = editor.textArea.text
                let lines = content.split("\n")
                if (lineNum < 1 || lineNum > lines.length) return

                let offset = 0
                for (let i = 0; i < lineNum - 1; i++) {
                    offset += lines[i].length + 1
                }

                scrollSyncGuard.syncing = true
                editor.textArea.cursorPosition = offset
                let rect = editor.textArea.positionToRectangle(offset)
                editor.ensureVisible(rect.y)
                scrollSyncTimer.restart()
            }
        }

        // Status bar
        EditorStatusBar {
            visible: AppController.currentDocument.filePath !== ""
                && !mainContent.isJsonlActive && !mainContent.isPdfActive
            viewMode: mainContent.viewMode
            editorCursorPosition: editor.cursorPosition
        }
    }
}
