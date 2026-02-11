import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import BlockSmith

Rectangle {
    id: rightPane
    color: "#2b2b2b"

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
            Layout.preferredHeight: 32

            background: Rectangle { color: "#333333" }
            onCurrentIndexChanged: {
                if (currentIndex !== 0)
                    AppController.highlightBlock("")
            }

            TabButton {
                text: "Blocks"
                width: implicitWidth
                font.pixelSize: 11
                font.bold: true
                palette.buttonText: tabBar.currentIndex === 0 ? "#ddd" : "#888"

                background: Rectangle {
                    color: tabBar.currentIndex === 0 ? "#2b2b2b" : "#333333"
                    Rectangle {
                        width: parent.width
                        height: 2
                        color: "#6c9bd2"
                        visible: tabBar.currentIndex === 0
                        anchors.bottom: parent.bottom
                    }
                }
            }

            TabButton {
                text: "Prompts"
                width: implicitWidth
                font.pixelSize: 11
                font.bold: true
                palette.buttonText: tabBar.currentIndex === 1 ? "#ddd" : "#888"

                background: Rectangle {
                    color: tabBar.currentIndex === 1 ? "#2b2b2b" : "#333333"
                    Rectangle {
                        width: parent.width
                        height: 2
                        color: "#6c9bd2"
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
