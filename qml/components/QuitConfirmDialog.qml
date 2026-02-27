import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import BlockSmith

Dialog {
    id: quitDialog

    parent: Overlay.overlay
    anchors.centerIn: parent
    width: 420
    modal: true
    title: "Unsaved Changes"

    property var dirtyPaths: []

    signal saveAllAndQuit()
    signal discardAllAndQuit()

    ColumnLayout {
        width: parent.width
        spacing: 8

        Label {
            text: quitDialog.dirtyPaths.length + " file(s) have unsaved changes:"
            color: Theme.textPrimary
            font.pixelSize: Theme.fontSizeM
        }

        Label {
            text: quitDialog.dirtyPaths.map(function(p) {
                return "  \u2022 " + p.split("/").pop()
            }).join("\n")
            color: Theme.textSecondary
            font.pixelSize: Theme.fontSizeM
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }
    }

    footer: DialogButtonBox {
        Button { text: "Save All & Quit"; DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole }
        Button { text: "Discard & Quit"; DialogButtonBox.buttonRole: DialogButtonBox.DestructiveRole }
        Button { text: "Cancel"; DialogButtonBox.buttonRole: DialogButtonBox.RejectRole }
    }

    onAccepted: saveAllAndQuit()
    onDiscarded: discardAllAndQuit()
}
