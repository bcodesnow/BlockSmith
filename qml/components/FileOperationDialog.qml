import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import BlockSmith

Dialog {
    id: dialog

    parent: Overlay.overlay
    anchors.centerIn: parent
    width: 400
    modal: true
    standardButtons: Dialog.Ok | Dialog.Cancel

    // Mode: "newFile", "newFolder", "rename"
    property string mode: "newFile"
    property string targetPath: ""
    property string errorText: ""

    title: {
        if (mode === "newFile") return "New File"
        if (mode === "newFolder") return "New Folder"
        return "Rename"
    }

    function openNewFile(dirPath) {
        mode = "newFile"
        targetPath = dirPath
        nameField.text = ""
        errorText = ""
        dialog.open()
        nameField.forceActiveFocus()
    }

    function openNewFolder(dirPath) {
        mode = "newFolder"
        targetPath = dirPath
        nameField.text = ""
        errorText = ""
        dialog.open()
        nameField.forceActiveFocus()
    }

    function openRename(itemPath) {
        mode = "rename"
        targetPath = itemPath
        let parts = itemPath.replace(/\\/g, "/").split("/")
        nameField.text = parts[parts.length - 1]
        errorText = ""
        dialog.open()
        nameField.forceActiveFocus()
        nameField.selectAll()
    }

    onAccepted: performAction()

    function performAction() {
        let name = nameField.text.trim()
        if (name.length === 0) return

        let err = ""
        if (mode === "newFile") {
            err = AppController.fileManager.createFile(targetPath, name)
        } else if (mode === "newFolder") {
            err = AppController.fileManager.createFolder(targetPath, name)
        } else if (mode === "rename") {
            err = AppController.fileManager.renameItem(targetPath, name)
        }

        if (err && err.length > 0) {
            errorText = err
            dialog.open()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.sp8

        Label {
            text: {
                if (dialog.mode === "newFile") return "File name:"
                if (dialog.mode === "newFolder") return "Folder name:"
                return "New name:"
            }
            color: Theme.textSecondary
            font.pixelSize: Theme.fontSizeM
        }

        TextField {
            id: nameField
            Layout.fillWidth: true
            font.pixelSize: Theme.fontSizeL
            placeholderText: dialog.mode === "newFolder" ? "folder-name" : "filename.md"
            Keys.onReturnPressed: dialog.accept()
        }

        Label {
            visible: dialog.errorText.length > 0
            text: dialog.errorText
            color: Theme.accentRed
            font.pixelSize: Theme.fontSizeXS
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }
    }
}
