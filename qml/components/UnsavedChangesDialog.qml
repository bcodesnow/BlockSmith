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
    property int pendingTabIndex: -1

    signal saveFailed(string message)

    Label {
        text: "Current file has unsaved changes.\nSave before closing?"
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
        let tabIdx = pendingTabIndex
        let doc = tabIdx >= 0 ? AppController.tabModel.tabDocument(tabIdx)
                              : AppController.currentDocument
        if (!doc) return

        // Save, then force-close the tab
        let cSaved = function() {
            doc.saved.disconnect(cSaved)
            doc.saveFailed.disconnect(cFailed)
            if (tabIdx >= 0)
                AppController.tabModel.closeTab(tabIdx)
            else if (pendingPath)
                AppController.forceOpenFile(pendingPath)
        }
        let cFailed = function(error) {
            doc.saved.disconnect(cSaved)
            doc.saveFailed.disconnect(cFailed)
            unsavedDialog.saveFailed("Save failed — tab not closed")
        }
        doc.saved.connect(cSaved)
        doc.saveFailed.connect(cFailed)
        doc.save()
    }
    onDiscarded: {
        let tabIdx = pendingTabIndex
        if (tabIdx >= 0) {
            AppController.tabModel.forceCloseTab(tabIdx)
        } else if (pendingPath) {
            AppController.forceOpenFile(pendingPath)
        }
    }
    onRejected: {
        pendingTabIndex = -1
        pendingPath = ""
    }
}
