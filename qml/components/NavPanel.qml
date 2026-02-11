import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import BlockSmith

Rectangle {
    id: navPanel
    color: "#2b2b2b"

    property bool hasProjects: false

    signal settingsRequested()
    signal newProjectRequested()

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
            Layout.preferredHeight: 36
            color: "#333333"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 6
                spacing: 4

                Label {
                    text: "PROJECTS"
                    font.pixelSize: 11
                    font.bold: true
                    font.letterSpacing: 1.2
                    color: "#999"
                    Layout.fillWidth: true
                }

                // Expand all
                Rectangle {
                    width: 24
                    height: 24
                    radius: 3
                    color: expandMa.containsMouse ? "#555" : "transparent"
                    visible: navPanel.hasProjects
                    ToolTip.text: "Expand all"
                    ToolTip.visible: expandMa.containsMouse
                    ToolTip.delay: 400

                    Label {
                        anchors.centerIn: parent
                        text: "\u229E"
                        font.pixelSize: 14
                        color: "#999"
                    }
                    MouseArea {
                        id: expandMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: treeView.expandRecursively()
                    }
                }

                // Collapse all
                Rectangle {
                    width: 24
                    height: 24
                    radius: 3
                    color: collapseMa.containsMouse ? "#555" : "transparent"
                    visible: navPanel.hasProjects
                    ToolTip.text: "Collapse all"
                    ToolTip.visible: collapseMa.containsMouse
                    ToolTip.delay: 400

                    Label {
                        anchors.centerIn: parent
                        text: "\u229F"
                        font.pixelSize: 14
                        color: "#999"
                    }
                    MouseArea {
                        id: collapseMa
                        anchors.fill: parent
                        hoverEnabled: true
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
                    font.pixelSize: 13
                    color: "#777"
                }

                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Add search paths in Settings,\nthen click Scan."
                    font.pixelSize: 11
                    color: "#666"
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
                            font.pixelSize: 10
                            color: "#aaa"
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
                                if (treeDelegate.isHighlighted) return "#4caf50"
                                if (model.nodeType === 0) return "#6c9bd2"
                                if (model.isTriggerFile)  return "#e0c060"
                                if (model.nodeType === 1) return "#888"
                                return "#999"
                            }
                            Layout.preferredWidth: 12
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Label {
                            text: model.display
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            font.bold: model.nodeType === 0
                            font.pixelSize: 12
                            color: {
                                if (treeDelegate.current) return "#fff"
                                if (treeDelegate.isHighlighted) return "#a5d6a7"
                                if (model.nodeType === 0) return "#ddd"
                                return "#ccc"
                            }
                        }
                    }

                    background: Rectangle {
                        color: treeDelegate.current ? "#3d6a99" :
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

                MenuItem {
                    text: "Open"
                    visible: treeContextMenu.targetNodeType === 2
                    height: visible ? implicitHeight : 0
                    onTriggered: AppController.openFile(treeContextMenu.targetPath)
                }

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
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: "#444"
        }

        // Footer with buttons
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            color: "#333333"

            RowLayout {
                anchors.fill: parent
                anchors.margins: 6
                spacing: 6

                Button {
                    Layout.fillWidth: true
                    flat: true
                    palette.buttonText: "#ccc"
                    background: Rectangle {
                        color: parent.hovered ? "#555" : "#3a3a3a"
                        radius: 3
                        border.color: "#555"
                        border.width: 1
                    }
                    onClicked: AppController.scan()

                    contentItem: Row {
                        anchors.centerIn: parent
                        spacing: 5
                        Label {
                            text: "\u21BB"
                            font.pixelSize: 14
                            color: "#ccc"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Label {
                            text: "Scan"
                            font.pixelSize: 12
                            color: "#ccc"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                Button {
                    Layout.fillWidth: true
                    flat: true
                    palette.buttonText: "#ccc"
                    background: Rectangle {
                        color: parent.hovered ? "#555" : "#3a3a3a"
                        radius: 3
                        border.color: "#555"
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
                            color: "#ccc"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Label {
                            text: "New"
                            font.pixelSize: 12
                            color: "#ccc"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                Button {
                    Layout.fillWidth: true
                    flat: true
                    palette.buttonText: "#ccc"
                    background: Rectangle {
                        color: parent.hovered ? "#555" : "#3a3a3a"
                        radius: 3
                        border.color: "#555"
                        border.width: 1
                    }
                    onClicked: navPanel.settingsRequested()

                    contentItem: Row {
                        anchors.centerIn: parent
                        spacing: 5
                        Label {
                            text: "\u2699"
                            font.pixelSize: 14
                            color: "#ccc"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Label {
                            text: "Settings"
                            font.pixelSize: 12
                            color: "#ccc"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }
    }
}
