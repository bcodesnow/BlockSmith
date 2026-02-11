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
        spacing: 10

        // Folder row
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Label { text: "Folder:"; color: "#999"; font.pixelSize: 12 }

            Label {
                id: folderLabel
                Layout.fillWidth: true
                font.pixelSize: 12
                color: "#ccc"
                elide: Text.ElideMiddle
                text: ""
            }

            Button {
                text: "Browse..."
                flat: true
                palette.buttonText: "#ccc"
                background: Rectangle {
                    color: parent.hovered ? "#555" : "#3a3a3a"
                    radius: 3
                    border.color: "#555"
                    border.width: 1
                }
                onClicked: folderDialog.open()
            }
        }

        // Trigger file row
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Label { text: "Create:"; color: "#999"; font.pixelSize: 12 }

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
            color: "#e06060"
            font.pixelSize: 11
            visible: text.length > 0
        }

        // Buttons
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

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
