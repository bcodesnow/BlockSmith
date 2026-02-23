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
    }

    // Unsaved changes dialog
    Dialog {
        id: unsavedDialog
        parent: Overlay.overlay
        anchors.centerIn: parent
        width: 400
        modal: true
        title: "Unsaved Changes"

        property string pendingPath: ""

        Label {
            text: "Current file has unsaved changes.\nSave before switching?"
            wrapMode: Text.Wrap
            width: parent.width
            color: Theme.textPrimary
        }

        footer: DialogButtonBox {
            Button { text: "Save"; DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole }
            Button { text: "Discard"; DialogButtonBox.buttonRole: DialogButtonBox.DestructiveRole }
            Button { text: "Cancel"; DialogButtonBox.buttonRole: DialogButtonBox.RejectRole }
        }

        onAccepted: {
            let target = pendingPath
            // One-shot: switch file only after save succeeds
            let cSaved = function() {
                AppController.currentDocument.saved.disconnect(cSaved)
                AppController.currentDocument.saveFailed.disconnect(cFailed)
                AppController.forceOpenFile(target)
            }
            let cFailed = function(error) {
                AppController.currentDocument.saved.disconnect(cSaved)
                AppController.currentDocument.saveFailed.disconnect(cFailed)
                toast.show("Save failed — file not switched")
            }
            AppController.currentDocument.saved.connect(cSaved)
            AppController.currentDocument.saveFailed.connect(cFailed)
            AppController.currentDocument.save()
        }
        onDiscarded: {
            AppController.forceOpenFile(pendingPath)
        }
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
                mainContentArea.viewMode = (mainContentArea.viewMode + 1) % 3
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
        onActivated: mainContentArea.openFind()
    }
    Shortcut {
        sequence: "Ctrl+H"
        context: Qt.ApplicationShortcut
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
        onActivated: root.close()
    }

    SplitView {
        id: mainLayout
        anchors.fill: parent
        orientation: Qt.Horizontal
        opacity: 0

        handle: Rectangle {
            implicitWidth: 3
            implicitHeight: 3
            color: SplitHandle.pressed ? Theme.accent
                 : SplitHandle.hovered ? Theme.borderHover
                 : Theme.border
            containmentMask: Item {
                x: parent ? (parent.width - width) / 2 : 0
                width: 12
                height: parent ? parent.height : 0
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
        }

        // Right pane — Blocks / Prompts tabs
        RightPane {
            id: rightPane
            SplitView.preferredWidth: AppController.configManager.splitRightWidth
            SplitView.minimumWidth: 200
            onBlockEditRequested: function(blockId) {
                blockEditorPopup.openBlock(blockId)
            }
            onBlockInsertRequested: function(blockId) {
                root.insertBlockIntoFile(blockId)
            }
            onPromptEditRequested: function(promptId) {
                promptEditorPopup.openPrompt(promptId)
            }
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
