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
    signal exportRequested()
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

                // Export
                Rectangle {
                    width: 24
                    height: 24
                    radius: Theme.radius
                    color: exportMa.containsMouse ? Theme.bgButtonHov : "transparent"
                    visible: AppController.currentDocument.filePath !== ""
                    ToolTip.text: "Export (Ctrl+Shift+E)"
                    ToolTip.visible: exportMa.containsMouse
                    ToolTip.delay: 400

                    Label {
                        anchors.centerIn: parent
                        text: "\u21E9"
                        font.pixelSize: 14
                        color: Theme.textSecondary
                    }
                    MouseArea {
                        id: exportMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: navPanel.exportRequested()
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

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    background: Rectangle { color: "transparent" }
                    contentItem: Rectangle {
                        implicitWidth: 6
                        radius: 3
                        color: parent.pressed ? Theme.bgButtonPrs
                             : parent.hovered ? Theme.bgButtonHov : Theme.borderHover
                    }
                }

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
                                if (treeDelegate.isHighlighted) return Theme.accentGreenLight
                                if (model.nodeType === 0) return Theme.textPrimary
                                return Theme.textPrimary
                            }
                        }

                        // Creation date for projects and directories
                        Label {
                            visible: model.nodeType !== 2 && (model.createdDate ?? "") !== ""
                            text: model.createdDate ?? ""
                            font.pixelSize: Theme.fontSizeXS
                            color: Theme.textMuted
                        }
                    }

                    background: Rectangle {
                        color: treeDelegate.current ? Theme.bgActive :
                               treeDelegate.isHighlighted ? Theme.highlightItemBg :
                               treeDelegate.hovered ? Theme.bgCardHov : "transparent"
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

            NavContextMenu {
                id: treeContextMenu
                cutItemPath: navPanel.cutItemPath
                onFileNewRequested: function(dirPath) { navPanel.fileNewRequested(dirPath) }
                onFolderNewRequested: function(dirPath) { navPanel.folderNewRequested(dirPath) }
                onFileRenameRequested: function(itemPath) { navPanel.fileRenameRequested(itemPath) }
                onCutPathChanged: function(newPath) { navPanel.cutItemPath = newPath }
                onDeleteRequested: function(itemPath, itemName) {
                    deleteDialog.itemPath = itemPath
                    deleteDialog.itemName = itemName
                    deleteDialog.open()
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
        NavFooterBar {
            onScanClicked: AppController.scan()
            onNewProjectClicked: navPanel.newProjectRequested()
            onSettingsClicked: navPanel.settingsRequested()
        }
    }
}
