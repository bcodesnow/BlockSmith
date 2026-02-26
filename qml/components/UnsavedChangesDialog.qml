import QtQuick
import QtQuick.Controls
import BlockSmith

Dialog {
    id: unsavedDialog

    parent: Overlay.overlay
    anchors.centerIn: parent
    width: 400
    modal: true
    title: "Unsaved Changes"

    property string pendingPath: ""

    signal saveFailed(string message)

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
        let cSaved = function() {
            AppController.currentDocument.saved.disconnect(cSaved)
            AppController.currentDocument.saveFailed.disconnect(cFailed)
            AppController.forceOpenFile(target)
        }
        let cFailed = function(error) {
            AppController.currentDocument.saved.disconnect(cSaved)
            AppController.currentDocument.saveFailed.disconnect(cFailed)
            unsavedDialog.saveFailed("Save failed — file not switched")
        }
        AppController.currentDocument.saved.connect(cSaved)
        AppController.currentDocument.saveFailed.connect(cFailed)
        AppController.currentDocument.save()
    }
    onDiscarded: {
        AppController.forceOpenFile(pendingPath)
    }
}
