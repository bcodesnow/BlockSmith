import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import BlockSmith

Dialog {
    id: dialog

    parent: Overlay.overlay
    anchors.centerIn: parent
    width: 480
    height: 200

    modal: true
    title: "New Project"
    standardButtons: Dialog.Cancel

    property var triggerFiles: []

    function openDialog() {
        triggerFiles = AppController.fileTriggerFiles()
        if (triggerFiles.length === 0) {
            // No file-type triggers configured
            return
        }
        triggerCombo.currentIndex = 0
        folderLabel.text = ""
        errorLabel.text = ""
        dialog.open()
    }

    FolderDialog {
        id: folderDialog
        title: "Select project folder"
        onAccepted: {
            let path = selectedFolder.toString()
            // Strip file:/// prefix
            if (Qt.platform.os === "windows")
                path = path.replace(/^file:\/\/\//, "")
            else
                path = path.replace(/^file:\/\//, "")
            folderLabel.text = decodeURIComponent(path)
            errorLabel.text = ""
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.sp8

        // Folder row
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.sp8

            Label { text: "Folder:"; color: Theme.textSecondary; font.pixelSize: Theme.fontSizeM }

            Label {
                id: folderLabel
                Layout.fillWidth: true
                font.pixelSize: Theme.fontSizeM
                color: Theme.textPrimary
                elide: Text.ElideMiddle
                text: ""
            }

            Button {
                text: "Browse..."
                flat: true
                palette.buttonText: Theme.textPrimary
                background: Rectangle {
                    color: parent.hovered ? Theme.bgButtonHov : Theme.bgButton
                    radius: Theme.radius
                    border.color: Theme.borderHover
                    border.width: 1
                }
                onClicked: folderDialog.open()
            }
        }

        // Trigger file row
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.sp8

            Label { text: "Create:"; color: Theme.textSecondary; font.pixelSize: Theme.fontSizeM }

            ComboBox {
                id: triggerCombo
                Layout.fillWidth: true
                model: dialog.triggerFiles
            }
        }

        // Error label
        Label {
            id: errorLabel
            Layout.fillWidth: true
            color: Theme.accentRed
            font.pixelSize: Theme.fontSizeXS
            visible: text.length > 0
        }

        // Buttons
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.sp8

            Item { Layout.fillWidth: true }

            Button {
                text: "Create Project"
                highlighted: true
                enabled: folderLabel.text.length > 0
                onClicked: {
                    let err = AppController.createProject(
                        folderLabel.text,
                        triggerCombo.currentText)
                    if (err && err.length > 0) {
                        errorLabel.text = err
                    } else {
                        dialog.close()
                    }
                }
            }
        }
    }
}
