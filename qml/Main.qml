import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import BlockSmith

ApplicationWindow {
    id: root

    width: AppController.configManager.windowGeometry["w"] ?? 1400
    height: AppController.configManager.windowGeometry["h"] ?? 900
    x: AppController.configManager.windowGeometry["x"] ?? 100
    y: AppController.configManager.windowGeometry["y"] ?? 100

    visible: false
    color: Theme.bg
    title: {
        let path = AppController.currentDocument.filePath
        let mod = AppController.currentDocument.modified ? " *" : ""
        return path ? "BlockSmith — " + path + mod : "BlockSmith"
    }

    // Deferred startup — C++ handles showing the window (DWM cloaked).
    // Timer lets the first frame render before the blocking scan runs.
    Timer {
        interval: 100
        running: true
        onTriggered: {
            splashOverlay.showTime = Date.now()
            if (AppController.configManager.autoScanOnStartup
                && (AppController.configManager.searchPaths.length > 0
                    || AppController.configManager.includeClaudeCodeFolder)) {
                splashOverlay.scanning = true
                AppController.scan()
            } else {
                splashOverlay.dismiss()
            }
        }
    }

    onClosing: {
        AppController.configManager.windowGeometry = {
            "x": root.x, "y": root.y,
            "w": root.width, "h": root.height
        }
        AppController.configManager.splitLeftWidth = navPanel.SplitView.preferredWidth
        AppController.configManager.splitRightWidth = rightPane.SplitView.preferredWidth
        AppController.configManager.save()
    }

    SettingsDialog {
        id: settingsDialog
        onScanRequested: AppController.scan()
    }

    BlockEditorPopup {
        id: blockEditorPopup
    }

    PromptEditorPopup {
        id: promptEditorPopup
    }

    Toast {
        id: toast
    }

    SearchDialog {
        id: searchDialog
    }

    NewProjectDialog {
        id: newProjectDialog
    }

    FileOperationDialog {
        id: fileOpDialog
    }

    ExportDialog {
        id: exportDialog
        onNotify: function(message) { toast.show(message) }
    }

    QuickSwitcher {
        id: quickSwitcher
    }

    UnsavedChangesDialog {
        id: unsavedDialog
        onSaveFailed: function(message) { toast.show(message) }
    }

    Connections {
        target: AppController.promptStore
        function onCopied(name) {
            toast.show("Copied '" + name + "'")
        }
        function onSaveFailed(message) {
            toast.show(message)
        }
    }

    Connections {
        target: AppController.blockStore
        function onSaveFailed(message) {
            toast.show(message)
        }
    }

    Connections {
        target: AppController.configManager
        function onSaveFailed(message) {
            toast.show(message)
        }
    }

    Connections {
        target: AppController.jsonlStore
        function onCopied(preview) {
            toast.show("Copied " + preview)
        }
        function onLoadFailed(error) {
            toast.show(error)
        }
    }

    Connections {
        target: AppController
        function onScanComplete(count) {
            splashOverlay.dismiss()
            toast.show("Scan complete — " + count + " project" + (count !== 1 ? "s" : "") + " found")
        }
        function onUnsavedChangesWarning(pendingPath) {
            unsavedDialog.pendingPath = pendingPath
            unsavedDialog.open()
        }
    }

    Connections {
        target: AppController.imageHandler
        function onImageSaved(path) {
            toast.show("Image saved")
        }
        function onImageError(error) {
            toast.show(error)
        }
    }

    Connections {
        target: AppController.currentDocument
        function onSaved() {
            toast.show("Saved")
        }
        function onLoadFailed(error) {
            toast.show(error)
        }
        function onSaveFailed(error) {
            toast.show(error)
        }
    }

    // Insert block into current file
    function insertBlockIntoFile(blockId) {
        if (AppController.currentDocument.filePath === "") {
            toast.show("Open a file first")
            return
        }
        let block = AppController.blockStore.getBlock(blockId)
        if (!block.id) return

        let pos = mainContentArea.editorVisible ? mainContentArea.editorCursorPosition : -1
        AppController.currentDocument.insertBlock(pos, block.id, block.name, block.content)
        AppController.currentDocument.save()
        mainContentArea.viewMode = MainContent.ViewMode.Edit
        toast.show("Inserted '" + block.name + "'")
    }

    // Keyboard shortcuts
    Shortcut {
        sequence: "Ctrl+S"
        onActivated: {
            if (AppController.currentDocument.modified)
                AppController.currentDocument.save()
        }
    }
    Shortcut {
        sequence: "Ctrl+Shift+S"
        onActivated: AppController.scan()
    }
    Shortcut {
        sequence: "Ctrl+E"
        onActivated: {
            if (AppController.currentDocument.filePath !== "")
                mainContentArea.cycleViewMode()
        }
    }
    Shortcut {
        sequence: "F5"
        onActivated: AppController.scan()
    }
    Shortcut {
        sequence: "Ctrl+,"
        onActivated: settingsDialog.open()
    }
    Shortcut {
        sequence: "Ctrl+R"
        onActivated: {
            if (AppController.currentDocument.filePath !== "")
                AppController.currentDocument.reload()
        }
    }
    Shortcut {
        sequence: "Ctrl+F"
        context: Qt.ApplicationShortcut
        enabled: !mainContentArea.isJsonlActive
        onActivated: mainContentArea.openFind()
    }
    Shortcut {
        sequence: "Ctrl+H"
        context: Qt.ApplicationShortcut
        enabled: !mainContentArea.isJsonlActive
        onActivated: mainContentArea.openReplace()
    }
    Shortcut {
        sequence: "Ctrl+Shift+F"
        context: Qt.ApplicationShortcut
        onActivated: {
            searchDialog.open()
            searchDialog.focusSearch()
        }
    }
    Shortcut {
        sequence: "Ctrl+Shift+E"
        onActivated: {
            if (AppController.currentDocument.filePath !== "")
                exportDialog.openDialog()
        }
    }

    // Zoom shortcuts
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
    Shortcut {
        sequence: "Ctrl+W"
        onActivated: AppController.currentDocument.clear()
    }
    Shortcut {
        sequence: "Ctrl+Q"
        onActivated: root.close()
    }
    Shortcut {
        sequence: "Ctrl+P"
        context: Qt.ApplicationShortcut
        onActivated: quickSwitcher.openSwitcher()
    }

    // Back/forward navigation
    Shortcut {
        sequence: "Alt+Left"
        enabled: AppController.canGoBack
        onActivated: AppController.goBack()
    }
    Shortcut {
        sequence: "Alt+Right"
        enabled: AppController.canGoForward
        onActivated: AppController.goForward()
    }

    SplitView {
        id: mainLayout
        anchors.fill: parent
        orientation: Qt.Horizontal
        opacity: 0

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

        // Left nav pane
        NavPanel {
            id: navPanel
            SplitView.preferredWidth: AppController.configManager.splitLeftWidth
            SplitView.minimumWidth: 180
            onSettingsRequested: settingsDialog.open()
            onNewProjectRequested: newProjectDialog.openDialog()
            onExportRequested: exportDialog.openDialog()
            onFileNewRequested: function(dirPath) { fileOpDialog.openNewFile(dirPath) }
            onFolderNewRequested: function(dirPath) { fileOpDialog.openNewFolder(dirPath) }
            onFileRenameRequested: function(itemPath) { fileOpDialog.openRename(itemPath) }
        }

        // Center content area
        MainContent {
            id: mainContentArea
            SplitView.fillWidth: true
            SplitView.minimumWidth: 300
            onCreatePromptRequested: function(content) {
                promptEditorPopup.openNewWithContent(content)
            }
            onNotifyRequested: function(message) {
                toast.show(message)
            }
        }

        // Right pane — Blocks / Prompts / Outline tabs
        RightPane {
            id: rightPane
            SplitView.preferredWidth: AppController.configManager.splitRightWidth
            SplitView.minimumWidth: 200
            editorCursorLine: mainContentArea.currentLine
            onBlockEditRequested: function(blockId) {
                blockEditorPopup.openBlock(blockId)
            }
            onBlockInsertRequested: function(blockId) {
                root.insertBlockIntoFile(blockId)
            }
            onPromptEditRequested: function(promptId) {
                promptEditorPopup.openPrompt(promptId)
            }
            onHeadingScrollRequested: function(lineNumber) {
                mainContentArea.scrollToLine(lineNumber)
            }
        }
    }

    // Mouse side buttons (back/forward) — behind splash, accepts only side buttons
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.BackButton | Qt.ForwardButton
        onClicked: function(mouse) {
            if (mouse.button === Qt.BackButton)
                AppController.goBack()
            else if (mouse.button === Qt.ForwardButton)
                AppController.goForward()
        }
    }

    SplashOverlay {
        id: splashOverlay
        anchors.fill: parent
        onDismissed: mainFadeIn.start()
    }

    NumberAnimation {
        id: mainFadeIn
        target: mainLayout
        property: "opacity"
        from: 0; to: 1
        duration: 300
        easing.type: Easing.InOutQuad
    }
}
