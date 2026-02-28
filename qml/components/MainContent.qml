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

    // Null-safe document access
    readonly property var currentDoc: AppController.currentDocument
    readonly property bool hasDoc: currentDoc !== null && currentDoc.filePath !== ""

    readonly property bool hasPreviewPane: hasDoc && !isJsonlActive && !isPdfActive && !isDocxActive
        && currentDoc.previewKind === Document.PreviewMarkdown
    readonly property bool hasEditorToolbar: hasDoc
        && currentDoc.toolbarKind !== Document.ToolbarNone

    // Is a JSONL file currently loaded?
    readonly property bool isJsonlActive: AppController.jsonlStore.filePath !== ""

    // Is a PDF file currently loaded?
    readonly property bool isPdfActive: hasDoc && currentDoc.previewKind === Document.PreviewPdf

    // Is a DOCX file currently loaded?
    readonly property bool isDocxActive: hasDoc && currentDoc.previewKind === Document.PreviewDocx

    // Convenience: editor is visible in Edit or Split mode (and not JSONL/PDF/DOCX)
    readonly property bool editorVisible: viewMode !== MainContent.ViewMode.Preview
        && !isJsonlActive && !isPdfActive && !isDocxActive

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

    // --- Tab state save/restore ---

    // Save editor state before tab switch
    function saveTabState() {
        AppController.tabModel.saveEditorState(
            editor.cursorPosition,
            editor.scrollFlickable ? editor.scrollFlickable.contentY : 0,
            editor.textArea.selectionStart,
            editor.textArea.selectionEnd,
            mainContent.viewMode
        )
    }

    // Restore editor state after tab switch
    function restoreTabState() {
        let state = AppController.tabModel.editorState()
        if (!state) return
        mainContent.viewMode = state.viewMode || 0
        // Defer cursor/scroll restore to after text binding updates
        Qt.callLater(function() {
            if (state.cursorPosition > 0 && state.cursorPosition <= editor.textArea.text.length)
                editor.textArea.cursorPosition = state.cursorPosition
            if (state.scrollY > 0 && editor.scrollFlickable)
                editor.scrollFlickable.contentY = state.scrollY
        })
    }

    Connections {
        target: AppController.tabModel
        function onAboutToSwitchTab(oldIndex, newIndex) {
            if (oldIndex >= 0)
                mainContent.saveTabState()
        }
        function onActiveDocumentChanged() {
            Qt.callLater(function() {
                mainContent.restoreTabState()
            })
        }
    }

    function scrollToLine(lineNum) {
        if (viewMode === MainContent.ViewMode.Preview)
            viewMode = MainContent.ViewMode.Edit
        contentArea.scrollEditorToLine(lineNum)
    }

    function openFind() {
        if (!hasDoc) return
        if (viewMode === MainContent.ViewMode.Preview)
            viewMode = MainContent.ViewMode.Edit
        findReplaceBar.openFind()
    }

    function openReplace() {
        if (!hasDoc) return
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

        // Tab bar
        EditorTabBar {
            id: editorTabBar
            Layout.fillWidth: true
            onTabCloseRequested: function(index) {
                AppController.tabModel.closeTab(index)
            }
        }

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
                visible: !mainContent.hasDoc && !mainContent.isJsonlActive
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

            // DOCX viewer (replaces editor when .docx is open)
            DocxViewer {
                anchors.fill: parent
                visible: mainContent.isDocxActive
            }

            SplitView {
                id: editorSplitView
                anchors.fill: parent
                orientation: Qt.Horizontal
                visible: mainContent.hasDoc
                    && !mainContent.isJsonlActive && !mainContent.isPdfActive
                    && !mainContent.isDocxActive

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
                    readOnly: false
                    toolbarVisible: mainContent.editorVisible && mainContent.hasEditorToolbar
                                    && AppController.configManager.editorToolbarVisible

                    // Bidirectional text sync (declarative binding breaks after imperative writes)
                    property bool _syncing: false

                    Connections {
                        target: mainContent.currentDoc
                        function onRawContentChanged() {
                            if (editor._syncing) return
                            editor._syncing = true
                            editor.textArea.text = mainContent.currentDoc.rawContent
                            editor._syncing = false
                        }
                    }
                    Connections {
                        target: AppController
                        function onCurrentDocumentChanged() {
                            editor._syncing = true
                            editor.textArea.text = mainContent.hasDoc
                                ? mainContent.currentDoc.rawContent : ""
                            editor._syncing = false
                        }
                    }
                    textArea.onTextChanged: {
                        if (editor._syncing) return
                        if (mainContent.hasDoc
                            && textArea.text !== mainContent.currentDoc.rawContent) {
                            editor._syncing = true
                            mainContent.currentDoc.rawContent = textArea.text
                            editor._syncing = false
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
            visible: mainContent.hasDoc
                && !mainContent.isJsonlActive && !mainContent.isPdfActive
                && !mainContent.isDocxActive
            viewMode: mainContent.viewMode
            editorCursorPosition: editor.cursorPosition
        }
    }
}
