import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import BlockSmith

Menu {
    id: contextMenu

    property string targetPath: ""
    property int targetNodeType: -1
    property string cutItemPath: ""

    signal fileNewRequested(string dirPath)
    signal folderNewRequested(string dirPath)
    signal fileRenameRequested(string itemPath)
    signal deleteRequested(string itemPath, string itemName)
    signal cutPathChanged(string newPath)

    // nodeType: 0=project, 1=dir, 2=file
    function targetDir() {
        if (targetNodeType === 2) {
            let p = targetPath.replace(/\\/g, "/")
            return p.substring(0, p.lastIndexOf("/"))
        }
        return targetPath
    }

    MenuItem {
        text: "Open"
        visible: contextMenu.targetNodeType === 2
        height: visible ? implicitHeight : 0
        onTriggered: AppController.openFile(contextMenu.targetPath)
    }

    MenuSeparator {
        visible: contextMenu.targetNodeType !== 2
        height: visible ? implicitHeight : 0
    }

    MenuItem {
        text: "New File..."
        visible: contextMenu.targetNodeType !== 2
        height: visible ? implicitHeight : 0
        onTriggered: contextMenu.fileNewRequested(contextMenu.targetDir())
    }

    MenuItem {
        text: "New Folder..."
        visible: contextMenu.targetNodeType !== 2
        height: visible ? implicitHeight : 0
        onTriggered: contextMenu.folderNewRequested(contextMenu.targetDir())
    }

    MenuSeparator {}

    MenuItem {
        text: "Rename..."
        visible: contextMenu.targetNodeType !== 0
        height: visible ? implicitHeight : 0
        onTriggered: contextMenu.fileRenameRequested(contextMenu.targetPath)
    }

    MenuItem {
        text: "Duplicate"
        visible: contextMenu.targetNodeType === 2
        height: visible ? implicitHeight : 0
        onTriggered: {
            let err = AppController.fileManager.duplicateFile(contextMenu.targetPath)
            if (err && err.length > 0)
                console.warn("Duplicate failed:", err)
        }
    }

    MenuItem {
        text: "Cut"
        visible: contextMenu.targetNodeType !== 0
        height: visible ? implicitHeight : 0
        onTriggered: contextMenu.cutPathChanged(contextMenu.targetPath)
    }

    MenuItem {
        text: "Paste"
        visible: contextMenu.targetNodeType !== 2 && contextMenu.cutItemPath.length > 0
        height: visible ? implicitHeight : 0
        onTriggered: {
            let err = AppController.fileManager.moveItem(
                contextMenu.cutItemPath, contextMenu.targetDir())
            contextMenu.cutPathChanged("")
            if (err && err.length > 0)
                console.warn("Paste failed:", err)
        }
    }

    MenuSeparator {
        visible: contextMenu.targetNodeType !== 0
        height: visible ? implicitHeight : 0
    }

    MenuItem {
        text: "Delete..."
        visible: contextMenu.targetNodeType !== 0
        height: visible ? implicitHeight : 0
        onTriggered: {
            let parts = contextMenu.targetPath.replace(/\\/g, "/").split("/")
            contextMenu.deleteRequested(contextMenu.targetPath, parts[parts.length - 1])
        }
    }

    MenuSeparator {}

    MenuItem {
        text: "Reveal in Explorer"
        onTriggered: AppController.revealInExplorer(contextMenu.targetPath)
    }

    MenuItem {
        text: "Copy Path"
        onTriggered: AppController.copyToClipboard(contextMenu.targetPath)
    }

    MenuItem {
        text: "Copy Name"
        onTriggered: {
            let parts = contextMenu.targetPath.replace(/\\/g, "/").split("/")
            AppController.copyToClipboard(parts[parts.length - 1])
        }
    }
}
