import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import BlockSmith

Rectangle {
    id: promptPanel
    color: "#2b2b2b"

    signal promptEditRequested(string promptId)

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
                anchors.rightMargin: 10

                Label {
                    text: "PROMPTS"
                    font.pixelSize: 11
                    font.bold: true
                    font.letterSpacing: 1.2
                    color: "#999"
                }

                Item { Layout.fillWidth: true }

                Label {
                    text: AppController.promptStore.count
                    font.pixelSize: 11
                    color: "#666"
                }

                // Add prompt button
                Rectangle {
                    width: 22
                    height: 22
                    radius: 3
                    color: addMa.containsMouse ? "#555" : "transparent"

                    Label {
                        anchors.centerIn: parent
                        text: "+"
                        font.pixelSize: 16
                        font.bold: true
                        color: "#999"
                    }

                    MouseArea {
                        id: addMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: promptPanel.promptEditRequested("")
                    }
                }
            }
        }

        // Search box
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            Layout.margins: 6
            color: "#1e1e1e"
            radius: 3
            border.color: promptSearchField.activeFocus ? "#6c9bd2" : "#444"
            border.width: 1

            TextField {
                id: promptSearchField
                anchors.fill: parent
                anchors.margins: 1
                placeholderText: "Search prompts..."
                placeholderTextColor: "#666"
                font.pixelSize: 12
                color: "#ddd"
                background: null
                onTextChanged: AppController.promptStore.searchFilter = text
            }
        }

        // Category filter
        Flow {
            Layout.fillWidth: true
            Layout.leftMargin: 6
            Layout.rightMargin: 6
            Layout.bottomMargin: 4
            spacing: 4
            visible: AppController.promptStore.allCategories.length > 0

            Repeater {
                model: [""].concat(AppController.promptStore.allCategories)
                Rectangle {
                    width: catTag.implicitWidth + 12
                    height: 20
                    radius: 10
                    color: AppController.promptStore.categoryFilter === modelData
                           ? "#3d6a99" : "#3a3a3a"
                    border.color: "#555"
                    border.width: AppController.promptStore.categoryFilter === modelData ? 0 : 1

                    Label {
                        id: catTag
                        anchors.centerIn: parent
                        text: modelData === "" ? "All" : modelData
                        font.pixelSize: 10
                        color: "#ccc"
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            AppController.promptStore.categoryFilter =
                                (AppController.promptStore.categoryFilter === modelData) ? "" : modelData
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

        // Prompt list
        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 4
            model: AppController.promptStore

            delegate: PromptCard {
                width: ListView.view.width - 12
                anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
                promptId: model.promptId
                promptName: model.name
                promptContent: model.content
                promptCategory: model.category
                onCopyRequested: AppController.promptStore.copyToClipboard(model.promptId)
                onEditRequested: promptPanel.promptEditRequested(model.promptId)
            }

            // Empty state
            Label {
                anchors.centerIn: parent
                visible: parent.count === 0
                text: AppController.promptStore.count === 0
                      ? "No prompts yet.\nClick + to create one."
                      : "No prompts match filter."
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 11
                color: "#666"
            }
        }
    }
}
