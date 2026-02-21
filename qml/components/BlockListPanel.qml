import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import BlockSmith

Rectangle {
    id: blockPanel
    color: Theme.bgPanel

    signal blockEditRequested(string blockId)
    signal blockInsertRequested(string blockId)

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
                anchors.rightMargin: 10

                Label {
                    text: "BLOCKS"
                    font.pixelSize: Theme.fontSizeXS
                    font.bold: true
                    font.letterSpacing: 1.2
                    color: Theme.textSecondary
                }

                Item { Layout.fillWidth: true }

                Label {
                    text: AppController.blockStore.count
                    font.pixelSize: Theme.fontSizeXS
                    color: Theme.textMuted
                }

                // Add block button
                Rectangle {
                    width: 22
                    height: 22
                    radius: Theme.radius
                    color: addBlockMa.containsMouse ? Theme.borderHover : "transparent"

                    Label {
                        anchors.centerIn: parent
                        text: "+"
                        font.pixelSize: 16
                        font.bold: true
                        color: Theme.textSecondary
                    }

                    MouseArea {
                        id: addBlockMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: blockPanel.blockEditRequested("")
                    }
                }
            }
        }

        // Search box
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            Layout.margins: 6
            color: Theme.bg
            radius: Theme.radius
            border.color: searchField.activeFocus ? Theme.borderFocus : Theme.border
            border.width: 1

            TextField {
                id: searchField
                anchors.fill: parent
                anchors.margins: 1
                placeholderText: "Search blocks..."
                placeholderTextColor: Theme.textPlaceholder
                font.pixelSize: Theme.fontSizeM
                color: Theme.textPrimary
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
                           ? Theme.bgActive
                           : (tagPillMa.containsMouse ? Theme.bgButtonHov : Theme.bgButton)
                    border.color: Theme.borderHover
                    border.width: AppController.blockStore.tagFilter === modelData ? 0 : 1

                    Label {
                        id: filterTag
                        anchors.centerIn: parent
                        text: modelData === "" ? "All" : modelData
                        font.pixelSize: Theme.fontSizeS
                        color: Theme.textPrimary
                    }

                    MouseArea {
                        id: tagPillMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
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
            color: Theme.border
        }

        // Block list
        ListView {
            id: blockListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 4
            model: AppController.blockStore

            // Increments each time the sync index is rebuilt — triggers delegate rebind
            property int indexRevision: 0

            Connections {
                target: AppController.syncEngine
                function onIndexReady() { blockListView.indexRevision++ }
            }

            delegate: BlockCard {
                id: blockDelegate
                width: ListView.view.width - 12
                anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
                blockId: model.blockId
                blockName: model.name
                blockContent: model.content
                blockTags: model.tags
                // O(1) lookups from cached index; re-evaluated when indexRevision changes
                usageCount: blockListView.indexRevision < -1 ? 0 : AppController.syncEngine.filesContainingBlock(model.blockId).length
                diverged: blockListView.indexRevision < -1 ? false : AppController.syncEngine.isBlockDiverged(model.blockId)
                onClicked: AppController.highlightBlock(model.blockId)
                onEditRequested: blockPanel.blockEditRequested(model.blockId)
                onInsertRequested: blockPanel.blockInsertRequested(model.blockId)
            }

            // Empty state
            Label {
                anchors.centerIn: parent
                visible: parent.count === 0
                text: AppController.blockStore.count === 0
                      ? "No blocks yet.\nClick + or select text\nin the editor to create one."
                      : "No blocks match filter."
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Theme.fontSizeXS
                color: Theme.textMuted
            }
        }
    }
}
