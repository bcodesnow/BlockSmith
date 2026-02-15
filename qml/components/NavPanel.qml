import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import BlockSmith

Rectangle {
    id: navPanel
    color: Theme.bgPanel

    property bool hasProjects: false

    signal settingsRequested()
    signal newProjectRequested()
    signal fileNewRequested(string dirPath)
    signal folderNewRequested(string dirPath)
    signal fileRenameRequested(string itemPath)

    // Cut state for cut/paste workflow
    property string cutItemPath: ""

    Connections {
        target: AppController
        function onScanComplete(count) {
            navPanel.hasProjects = count > 0
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.headerHeight
            color: Theme.bgHeader

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 6
                spacing: 4

                Label {
                    text: "PROJECTS"
                    font.pixelSize: Theme.fontSizeXS
                    font.bold: true
                    font.letterSpacing: 1.2
                    color: Theme.textSecondary
                    Layout.fillWidth: true
                }

                // Expand all
                Rectangle {
                    width: 24
                    height: 24
                    radius: Theme.radius
                    color: expandMa.containsMouse ? Theme.bgButtonHov : "transparent"
                    visible: navPanel.hasProjects
                    ToolTip.text: "Expand all"
                    ToolTip.visible: expandMa.containsMouse
                    ToolTip.delay: 400

                    Label {
                        anchors.centerIn: parent
                        text: "\u229E"
                        font.pixelSize: 14
                        color: Theme.textSecondary
                    }
                    MouseArea {
                        id: expandMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: treeView.expandRecursively()
                    }
                }

                // Collapse all
                Rectangle {
                    width: 24
                    height: 24
                    radius: Theme.radius
                    color: collapseMa.containsMouse ? Theme.bgButtonHov : "transparent"
                    visible: navPanel.hasProjects
                    ToolTip.text: "Collapse all"
                    ToolTip.visible: collapseMa.containsMouse
                    ToolTip.delay: 400

                    Label {
                        anchors.centerIn: parent
                        text: "\u229F"
                        font.pixelSize: 14
                        color: Theme.textSecondary
                    }
                    MouseArea {
                        id: collapseMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: treeView.collapseRecursively()
                    }
                }
            }
        }

        // Tree view area
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Empty state
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 8
                visible: !navPanel.hasProjects

                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: "No projects found"
                    font.pixelSize: Theme.fontSizeL
                    color: Theme.textMuted
                }

                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Add search paths in Settings,\nthen click Scan."
                    font.pixelSize: Theme.fontSizeXS
                    color: Theme.textMuted
                    horizontalAlignment: Text.AlignHCenter
                    lineHeight: 1.3
                }
            }

            TreeView {
                id: treeView
                anchors.fill: parent
                visible: navPanel.hasProjects
                model: AppController.projectTreeModel
                clip: true

                selectionModel: ItemSelectionModel {
                    model: treeView.model
                }

                delegate: TreeViewDelegate {
                    id: treeDelegate
                    implicitHeight: 26
                    indentation: 14
                    leftMargin: 4

                    // Hide the built-in indicator (we draw our own)
                    indicator: Item {}

                    property bool isHighlighted: model.nodeType === 2
                        && AppController.highlightedFiles.indexOf(model.filePath) >= 0

                    contentItem: RowLayout {
                        spacing: 5

                        // Expand indicator for non-leaf nodes
                        Label {
                            visible: model.nodeType !== 2
                            text: treeDelegate.expanded ? "\u25BE" : "\u25B8"
                            font.pixelSize: Theme.fontSizeS
                            color: Theme.textSecondary
                            Layout.preferredWidth: 10
                        }

                        // Icon
                        Label {
                            text: {
                                if (model.nodeType === 0) return "\u25A0"   // project root — filled square
                                if (model.nodeType === 1) return "\u25AB"   // directory — small square
                                if (model.isTriggerFile)  return "\u25C6"   // trigger file — diamond
                                if (treeDelegate.isHighlighted) return "\u25CF" // highlighted — filled circle
                                return "\u25CB"                              // md file — circle
                            }
                            font.pixelSize: model.nodeType === 0 ? 11 : 9
                            color: {
                                if (treeDelegate.isHighlighted) return Theme.accentGreen
                                if (model.nodeType === 0) return Theme.accent
                                if (model.isTriggerFile)  return Theme.accentGold
                                if (model.nodeType === 1) return Theme.textMuted
                                return Theme.textSecondary
                            }
                            Layout.preferredWidth: 12
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Label {
                            text: model.display
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            font.bold: model.nodeType === 0
                            font.pixelSize: Theme.fontSizeM
                            ToolTip.text: model.filePath
                            ToolTip.visible: treeDelegate.hovered && truncated
                            ToolTip.delay: 600
                            color: {
                                if (treeDelegate.current) return Theme.textWhite
                                if (treeDelegate.isHighlighted) return "#a5d6a7"
                                if (model.nodeType === 0) return Theme.textPrimary
                                return Theme.textPrimary
                            }
                        }
                    }

                    background: Rectangle {
                        color: treeDelegate.current ? Theme.bgActive :
                               treeDelegate.isHighlighted ? "#2a3a2a" :
                               treeDelegate.hovered ? "#383838" : "transparent"
                    }

                    TapHandler {
                        onTapped: {
                            if (model.nodeType === 2) {
                                treeView.selectionModel.setCurrentIndex(
                                    treeView.index(treeDelegate.row, 0),
                                    ItemSelectionModel.ClearAndSelect)
                                AppController.openFile(model.filePath)
                            } else {
                                treeView.toggleExpanded(treeDelegate.row)
                            }
                        }
                    }

                    TapHandler {
                        acceptedButtons: Qt.RightButton
                        onTapped: {
                            treeContextMenu.targetPath = model.filePath
                            treeContextMenu.targetNodeType = model.nodeType
                            treeContextMenu.popup()
                        }
                    }
                }
            }

            Menu {
                id: treeContextMenu
                property string targetPath: ""
                property int targetNodeType: -1

                // nodeType: 0=project, 1=dir, 2=file
                // For dirs/projects, resolve to dir path; for files, use parent dir
                function targetDir() {
                    if (targetNodeType === 2) {
                        let p = targetPath.replace(/\\/g, "/")
                        return p.substring(0, p.lastIndexOf("/"))
                    }
                    return targetPath
                }

                MenuItem {
                    text: "Open"
                    visible: treeContextMenu.targetNodeType === 2
                    height: visible ? implicitHeight : 0
                    onTriggered: AppController.openFile(treeContextMenu.targetPath)
                }

                MenuSeparator {
                    visible: treeContextMenu.targetNodeType !== 2
                    height: visible ? implicitHeight : 0
                }

                MenuItem {
                    text: "New File..."
                    visible: treeContextMenu.targetNodeType !== 2
                    height: visible ? implicitHeight : 0
                    onTriggered: navPanel.fileNewRequested(treeContextMenu.targetDir())
                }

                MenuItem {
                    text: "New Folder..."
                    visible: treeContextMenu.targetNodeType !== 2
                    height: visible ? implicitHeight : 0
                    onTriggered: navPanel.folderNewRequested(treeContextMenu.targetDir())
                }

                MenuSeparator {}

                MenuItem {
                    text: "Rename..."
                    visible: treeContextMenu.targetNodeType !== 0
                    height: visible ? implicitHeight : 0
                    onTriggered: navPanel.fileRenameRequested(treeContextMenu.targetPath)
                }

                MenuItem {
                    text: "Duplicate"
                    visible: treeContextMenu.targetNodeType === 2
                    height: visible ? implicitHeight : 0
                    onTriggered: {
                        let err = AppController.fileManager.duplicateFile(treeContextMenu.targetPath)
                        if (err && err.length > 0)
                            console.warn("Duplicate failed:", err)
                    }
                }

                MenuItem {
                    text: "Cut"
                    visible: treeContextMenu.targetNodeType !== 0
                    height: visible ? implicitHeight : 0
                    onTriggered: navPanel.cutItemPath = treeContextMenu.targetPath
                }

                MenuItem {
                    text: "Paste"
                    visible: treeContextMenu.targetNodeType !== 2 && navPanel.cutItemPath.length > 0
                    height: visible ? implicitHeight : 0
                    onTriggered: {
                        let err = AppController.fileManager.moveItem(
                            navPanel.cutItemPath, treeContextMenu.targetDir())
                        navPanel.cutItemPath = ""
                        if (err && err.length > 0)
                            console.warn("Paste failed:", err)
                    }
                }

                MenuSeparator {
                    visible: treeContextMenu.targetNodeType !== 0
                    height: visible ? implicitHeight : 0
                }

                MenuItem {
                    text: "Delete..."
                    visible: treeContextMenu.targetNodeType !== 0
                    height: visible ? implicitHeight : 0
                    onTriggered: {
                        deleteDialog.itemPath = treeContextMenu.targetPath
                        let parts = treeContextMenu.targetPath.replace(/\\/g, "/").split("/")
                        deleteDialog.itemName = parts[parts.length - 1]
                        deleteDialog.open()
                    }
                }

                MenuSeparator {}

                MenuItem {
                    text: "Reveal in Explorer"
                    onTriggered: AppController.revealInExplorer(treeContextMenu.targetPath)
                }

                MenuItem {
                    text: "Copy Path"
                    onTriggered: AppController.copyToClipboard(treeContextMenu.targetPath)
                }

                MenuItem {
                    text: "Copy Name"
                    onTriggered: {
                        let parts = treeContextMenu.targetPath.replace(/\\/g, "/").split("/")
                        AppController.copyToClipboard(parts[parts.length - 1])
                    }
                }
            }

            // Delete confirmation dialog
            Dialog {
                id: deleteDialog
                parent: Overlay.overlay
                anchors.centerIn: parent
                width: 380
                modal: true
                title: "Delete"

                property string itemPath: ""
                property string itemName: ""

                Label {
                    text: "Delete \"" + deleteDialog.itemName + "\"?\nThis cannot be undone."
                    wrapMode: Text.Wrap
                    width: parent.width
                    color: Theme.textPrimary
                }

                footer: DialogButtonBox {
                    Button {
                        text: "Delete"
                        DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
                        palette.buttonText: Theme.accentRed
                    }
                    Button {
                        text: "Cancel"
                        DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
                    }
                }

                onAccepted: {
                    let err = AppController.fileManager.deleteItem(deleteDialog.itemPath)
                    if (err && err.length > 0)
                        console.warn("Delete failed:", err)
                }
            }
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.border
        }

        // Footer with buttons
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            color: Theme.bgHeader

            RowLayout {
                anchors.fill: parent
                anchors.margins: 6
                spacing: 6

                Button {
                    Layout.fillWidth: true
                    flat: true
                    palette.buttonText: Theme.textPrimary
                    background: Rectangle {
                        color: parent.hovered ? Theme.bgButtonHov : Theme.bgButton
                        radius: Theme.radius
                        border.color: Theme.borderHover
                        border.width: 1
                    }
                    onClicked: AppController.scan()

                    contentItem: Row {
                        anchors.centerIn: parent
                        spacing: 5
                        Label {
                            text: "\u21BB"
                            font.pixelSize: 14
                            color: Theme.textPrimary
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Label {
                            text: "Scan"
                            font.pixelSize: Theme.fontSizeM
                            color: Theme.textPrimary
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                Button {
                    Layout.fillWidth: true
                    flat: true
                    palette.buttonText: Theme.textPrimary
                    background: Rectangle {
                        color: parent.hovered ? Theme.bgButtonHov : Theme.bgButton
                        radius: Theme.radius
                        border.color: Theme.borderHover
                        border.width: 1
                    }
                    onClicked: navPanel.newProjectRequested()

                    contentItem: Row {
                        anchors.centerIn: parent
                        spacing: 5
                        Label {
                            text: "+"
                            font.pixelSize: 14
                            font.bold: true
                            color: Theme.textPrimary
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Label {
                            text: "New"
                            font.pixelSize: Theme.fontSizeM
                            color: Theme.textPrimary
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                Button {
                    Layout.fillWidth: true
                    flat: true
                    palette.buttonText: Theme.textPrimary
                    background: Rectangle {
                        color: parent.hovered ? Theme.bgButtonHov : Theme.bgButton
                        radius: Theme.radius
                        border.color: Theme.borderHover
                        border.width: 1
                    }
                    onClicked: navPanel.settingsRequested()

                    contentItem: Row {
                        anchors.centerIn: parent
                        spacing: 5
                        Label {
                            text: "\u2699"
                            font.pixelSize: 14
                            color: Theme.textPrimary
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Label {
                            text: "Settings"
                            font.pixelSize: Theme.fontSizeM
                            color: Theme.textPrimary
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }
    }
}
