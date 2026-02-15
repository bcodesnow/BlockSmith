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

    visible: true
    title: {
        let path = AppController.currentDocument.filePath
        let mod = AppController.currentDocument.modified ? " *" : ""
        return path ? "BlockSmith — " + path + mod : "BlockSmith"
    }

    // Auto-scan on startup
    Component.onCompleted: {
        if (AppController.configManager.autoScanOnStartup
            && AppController.configManager.searchPaths.length > 0) {
            AppController.scan()
        }
    }

    onClosing: {
        AppController.configManager.windowGeometry = {
            "x": root.x, "y": root.y,
            "w": root.width, "h": root.height
        }
        AppController.configManager.save()
    }

    SettingsDialog {
        id: settingsDialog
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
            AppController.currentDocument.save()
            AppController.forceOpenFile(pendingPath)
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
    }

    Connections {
        target: AppController
        function onScanComplete(count) {
            toast.show("Scan complete — " + count + " project" + (count !== 1 ? "s" : "") + " found")
        }
        function onUnsavedChangesWarning(pendingPath) {
            unsavedDialog.pendingPath = pendingPath
            unsavedDialog.open()
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
        onActivated: mainContentArea.openFind()
    }
    Shortcut {
        sequence: "Ctrl+H"
        onActivated: mainContentArea.openReplace()
    }
    Shortcut {
        sequence: "Ctrl+Shift+F"
        onActivated: {
            searchDialog.open()
            searchDialog.focusSearch()
        }
    }

    SplitView {
        anchors.fill: parent
        orientation: Qt.Horizontal

        // Left nav pane
        NavPanel {
            SplitView.preferredWidth: 250
            SplitView.minimumWidth: 180
            onSettingsRequested: settingsDialog.open()
            onNewProjectRequested: newProjectDialog.openDialog()
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
            SplitView.preferredWidth: 280
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
}
