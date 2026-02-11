import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import BlockSmith

Rectangle {
    id: blockPanel
    color: "#2b2b2b"

    signal blockEditRequested(string blockId)
    signal blockInsertRequested(string blockId)

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            color: "#333333"

            Label {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 10
                text: "BLOCKS"
                font.pixelSize: 11
                font.bold: true
                font.letterSpacing: 1.2
                color: "#999"
            }

            Label {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 10
                text: AppController.blockStore.count
                font.pixelSize: 11
                color: "#666"
            }
        }

        // Search box
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            Layout.margins: 6
            color: "#1e1e1e"
            radius: 3
            border.color: searchField.activeFocus ? "#6c9bd2" : "#444"
            border.width: 1

            TextField {
                id: searchField
                anchors.fill: parent
                anchors.margins: 1
                placeholderText: "Search blocks..."
                placeholderTextColor: "#666"
                font.pixelSize: 12
                color: "#ddd"
                background: null
                onTextChanged: AppController.blockStore.searchFilter = text
            }
        }

        // Tag filter
        Flow {
            Layout.fillWidth: true
            Layout.leftMargin: 6
            Layout.rightMargin: 6
            Layout.bottomMargin: 4
            spacing: 4
            visible: AppController.blockStore.allTags.length > 0

            Repeater {
                model: [""].concat(AppController.blockStore.allTags)
                Rectangle {
                    width: filterTag.implicitWidth + 12
                    height: 20
                    radius: 10
                    color: AppController.blockStore.tagFilter === modelData
                           ? "#3d6a99" : "#3a3a3a"
                    border.color: "#555"
                    border.width: AppController.blockStore.tagFilter === modelData ? 0 : 1

                    Label {
                        id: filterTag
                        anchors.centerIn: parent
                        text: modelData === "" ? "All" : modelData
                        font.pixelSize: 10
                        color: "#ccc"
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            AppController.blockStore.tagFilter =
                                (AppController.blockStore.tagFilter === modelData) ? "" : modelData
                        }
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

        // Block list
        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 4
            model: AppController.blockStore

            delegate: BlockCard {
                width: ListView.view.width - 12
                anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
                blockId: model.blockId
                blockName: model.name
                blockContent: model.content
                blockTags: model.tags
                onClicked: AppController.highlightBlock(model.blockId)
                onEditRequested: blockPanel.blockEditRequested(model.blockId)
                onInsertRequested: blockPanel.blockInsertRequested(model.blockId)
            }

            // Empty state
            Label {
                anchors.centerIn: parent
                visible: parent.count === 0
                text: AppController.blockStore.count === 0
                      ? "No blocks yet.\nSelect text in the editor\nand right-click to create one."
                      : "No blocks match filter."
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 11
                color: "#666"
            }
        }
    }
}
