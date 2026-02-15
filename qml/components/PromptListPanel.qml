import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import BlockSmith

Rectangle {
    id: promptPanel
    color: Theme.bgPanel

    signal promptEditRequested(string promptId)

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
                    text: "PROMPTS"
                    font.pixelSize: Theme.fontSizeXS
                    font.bold: true
                    font.letterSpacing: 1.2
                    color: Theme.textSecondary
                }

                Item { Layout.fillWidth: true }

                Label {
                    text: AppController.promptStore.count
                    font.pixelSize: Theme.fontSizeXS
                    color: Theme.textMuted
                }

                // Add prompt button
                Rectangle {
                    width: 22
                    height: 22
                    radius: Theme.radius
                    color: addMa.containsMouse ? Theme.borderHover : "transparent"

                    Label {
                        anchors.centerIn: parent
                        text: "+"
                        font.pixelSize: 16
                        font.bold: true
                        color: Theme.textSecondary
                    }

                    MouseArea {
                        id: addMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
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
            color: Theme.bg
            radius: Theme.radius
            border.color: promptSearchField.activeFocus ? Theme.borderFocus : Theme.border
            border.width: 1

            TextField {
                id: promptSearchField
                anchors.fill: parent
                anchors.margins: 1
                placeholderText: "Search prompts..."
                placeholderTextColor: Theme.textPlaceholder
                font.pixelSize: Theme.fontSizeM
                color: Theme.textPrimary
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
                           ? Theme.bgActive
                           : (catPillMa.containsMouse ? Theme.bgButtonHov : Theme.bgButton)
                    border.color: Theme.borderHover
                    border.width: AppController.promptStore.categoryFilter === modelData ? 0 : 1

                    Label {
                        id: catTag
                        anchors.centerIn: parent
                        text: modelData === "" ? "All" : modelData
                        font.pixelSize: Theme.fontSizeS
                        color: Theme.textPrimary
                    }

                    MouseArea {
                        id: catPillMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
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
            color: Theme.border
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
                font.pixelSize: Theme.fontSizeXS
                color: Theme.textMuted
            }
        }
    }
}
