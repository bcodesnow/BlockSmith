import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import BlockSmith

Rectangle {
    id: filterBar

    Layout.fillWidth: true
    Layout.preferredHeight: 40
    color: Theme.bgHeader

    property alias searchField: searchField

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.sp8
        anchors.rightMargin: Theme.sp8
        spacing: Theme.sp8

        // Search field
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 26
            color: Theme.bg
            radius: Theme.radius
            border.color: searchField.activeFocus ? Theme.borderFocus : Theme.border
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.sp4
                anchors.rightMargin: Theme.sp4
                spacing: Theme.sp4

                Label {
                    text: "\uD83D\uDD0D"
                    font.pixelSize: Theme.fontSizeS
                    color: Theme.textMuted
                }

                TextField {
                    id: searchField
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    placeholderText: "Search content..."
                    placeholderTextColor: Theme.textPlaceholder
                    font.pixelSize: Theme.fontSizeM
                    color: Theme.textEditor
                    background: null
                    onTextChanged: searchTimer.restart()

                    Keys.onEscapePressed: {
                        text = ""
                        focus = false
                    }
                }

                // Clear button
                Rectangle {
                    visible: searchField.text.length > 0
                    width: 16; height: 16; radius: 8
                    color: clearMa.containsMouse ? Theme.bgButtonHov : "transparent"
                    Label {
                        anchors.centerIn: parent
                        text: "\u2715"
                        font.pixelSize: 9
                        color: Theme.textMuted
                    }
                    MouseArea {
                        id: clearMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: searchField.text = ""
                    }
                }
            }
        }

        Timer {
            id: searchTimer
            interval: 200
            onTriggered: AppController.jsonlStore.textFilter = searchField.text
        }

        // Separator
        Rectangle { width: 1; Layout.fillHeight: true; Layout.topMargin: 8; Layout.bottomMargin: 8; color: Theme.border }

        // Role filter pills
        Row {
            spacing: Theme.sp4

            // "All" pill
            Rectangle {
                width: allLabel.implicitWidth + 12
                height: 22; radius: 11
                color: AppController.jsonlStore.roleFilter === "" ? Theme.bgActive : Theme.bgButton
                border.color: AppController.jsonlStore.roleFilter === "" ? Theme.accent : Theme.border
                border.width: 1

                Label {
                    id: allLabel
                    anchors.centerIn: parent
                    text: "All"
                    font.pixelSize: Theme.fontSizeS
                    color: AppController.jsonlStore.roleFilter === "" ? Theme.textWhite : Theme.textSecondary
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: AppController.jsonlStore.roleFilter = ""
                }
            }

            Repeater {
                model: AppController.jsonlStore.availableRoles
                delegate: Rectangle {
                    required property string modelData
                    width: pillLabel.implicitWidth + 12
                    height: 22; radius: 11
                    color: AppController.jsonlStore.roleFilter === modelData ? Theme.bgActive : Theme.bgButton
                    border.color: AppController.jsonlStore.roleFilter === modelData
                                  ? Theme.roleColor(modelData) : Theme.border
                    border.width: 1

                    Label {
                        id: pillLabel
                        anchors.centerIn: parent
                        text: parent.modelData
                        font.pixelSize: Theme.fontSizeS
                        color: AppController.jsonlStore.roleFilter === parent.modelData
                               ? Theme.textWhite : Theme.textSecondary
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (AppController.jsonlStore.roleFilter === parent.modelData)
                                AppController.jsonlStore.roleFilter = ""
                            else
                                AppController.jsonlStore.roleFilter = parent.modelData
                        }
                    }
                }
            }
        }

        // Tool use toggle
        Rectangle {
            width: toolToggleLabel.implicitWidth + 12
            height: 22; radius: 11
            color: AppController.jsonlStore.toolUseOnly ? Theme.bgActive : Theme.bgButton
            border.color: AppController.jsonlStore.toolUseOnly ? Theme.accentOrange : Theme.border
            border.width: 1

            Label {
                id: toolToggleLabel
                anchors.centerIn: parent
                text: "\u2699 tools"
                font.pixelSize: Theme.fontSizeS
                color: AppController.jsonlStore.toolUseOnly ? Theme.textWhite : Theme.textMuted
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: AppController.jsonlStore.toolUseOnly = !AppController.jsonlStore.toolUseOnly
            }
        }
    }
}
