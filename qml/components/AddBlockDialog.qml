import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import BlockSmith

Dialog {
    id: dialog

    parent: Overlay.overlay
    anchors.centerIn: parent
    width: 420
    height: 240

    modal: true
    title: "Add as Block"
    standardButtons: Dialog.Ok | Dialog.Cancel

    property string selectedText: ""
    property int selectionStart: 0
    property int selectionEnd: 0

    signal blockCreated(string blockId)

    onAccepted: {
        let name = nameField.text.trim()
        if (name.length === 0) return

        let tags = tagsField.text.split(",").map(s => s.trim()).filter(s => s.length > 0)
        let sourceFile = AppController.currentDocument.filePath

        let blockId = AppController.blockStore.createBlock(name, dialog.selectedText, tags, sourceFile)
        AppController.currentDocument.wrapSelectionAsBlock(
            dialog.selectionStart, dialog.selectionEnd, blockId, name)
        AppController.currentDocument.save()

        blockCreated(blockId)
    }

    onOpened: {
        nameField.text = ""
        tagsField.text = ""
        nameField.forceActiveFocus()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.sp8

        Label {
            text: "Block Name"
            font.bold: true
            color: palette.text
        }

        TextField {
            id: nameField
            Layout.fillWidth: true
            placeholderText: "e.g. code-style, testing-rules"
            font.pixelSize: Theme.fontSizeL
            Keys.onReturnPressed: dialog.accept()
        }

        Label {
            text: "Tags (comma-separated, optional)"
            font.bold: true
            color: palette.text
        }

        TextField {
            id: tagsField
            Layout.fillWidth: true
            placeholderText: "e.g. ts, style, testing"
            font.pixelSize: Theme.fontSizeL
        }

        Label {
            text: "Selected: " + dialog.selectedText.substring(0, 80).replace(/\n/g, " ") + (dialog.selectedText.length > 80 ? "..." : "")
            font.pixelSize: Theme.fontSizeXS
            color: Theme.textMuted
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }
    }
}
