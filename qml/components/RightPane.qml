import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import BlockSmith

Rectangle {
    id: rightPane
    color: Theme.bgPanel

    signal blockEditRequested(string blockId)
    signal blockInsertRequested(string blockId)
    signal promptEditRequested(string promptId)

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Tab bar
        TabBar {
            id: tabBar
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.headerHeight

            background: Rectangle { color: Theme.bgHeader }
            onCurrentIndexChanged: {
                if (currentIndex !== 0)
                    AppController.highlightBlock("")
            }

            TabButton {
                text: "Blocks"
                width: implicitWidth
                font.pixelSize: Theme.fontSizeXS
                font.bold: true
                palette.buttonText: tabBar.currentIndex === 0 ? Theme.textPrimary : Theme.textMuted

                background: Rectangle {
                    color: tabBar.currentIndex === 0 ? Theme.bgPanel : Theme.bgHeader
                    Rectangle {
                        width: parent.width
                        height: 2
                        color: Theme.accent
                        visible: tabBar.currentIndex === 0
                        anchors.bottom: parent.bottom
                    }
                }
            }

            TabButton {
                text: "Prompts"
                width: implicitWidth
                font.pixelSize: Theme.fontSizeXS
                font.bold: true
                palette.buttonText: tabBar.currentIndex === 1 ? Theme.textPrimary : Theme.textMuted

                background: Rectangle {
                    color: tabBar.currentIndex === 1 ? Theme.bgPanel : Theme.bgHeader
                    Rectangle {
                        width: parent.width
                        height: 2
                        color: Theme.accent
                        visible: tabBar.currentIndex === 1
                        anchors.bottom: parent.bottom
                    }
                }
            }
        }

        // Content
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: tabBar.currentIndex

            BlockListPanel {
                onBlockEditRequested: function(blockId) {
                    rightPane.blockEditRequested(blockId)
                }
                onBlockInsertRequested: function(blockId) {
                    rightPane.blockInsertRequested(blockId)
                }
            }

            PromptListPanel {
                onPromptEditRequested: function(promptId) {
                    rightPane.promptEditRequested(promptId)
                }
            }
        }
    }
}
