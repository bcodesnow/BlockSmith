import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import BlockSmith

Rectangle {
    id: viewer
    color: Theme.bg

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Filter bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            color: Theme.bgHeader

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
                                          ? roleColor(modelData) : Theme.border
                            border.width: 1

                            function roleColor(role) {
                                switch (role) {
                                case "user":      return Theme.accent
                                case "assistant":  return Theme.accentGreen
                                case "system":     return Theme.accentGold
                                case "tool":       return Theme.textMuted
                                default:           return Theme.textSecondary
                                }
                            }

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

        // Separator
        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

        // Entry list
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: entryList
                anchors.fill: parent
                model: AppController.jsonlStore
                clip: true
                spacing: 2
                leftMargin: Theme.sp4
                rightMargin: Theme.sp4
                topMargin: Theme.sp4
                bottomMargin: Theme.sp4

                delegate: JsonlEntryCard {
                    width: entryList.width - entryList.leftMargin - entryList.rightMargin
                }

                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
            }

            // Loading overlay
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.8)
                visible: AppController.jsonlStore.loading

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: Theme.sp12

                    BusyIndicator {
                        Layout.alignment: Qt.AlignHCenter
                        running: AppController.jsonlStore.loading
                    }

                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Loading... " + AppController.jsonlStore.loadProgress + " lines"
                        font.pixelSize: Theme.fontSizeM
                        color: Theme.textMuted
                    }
                }
            }

            // Empty state
            Label {
                anchors.centerIn: parent
                visible: !AppController.jsonlStore.loading
                         && AppController.jsonlStore.totalCount === 0
                text: "No entries"
                font.pixelSize: 14
                color: Theme.textMuted
            }

            // No results state
            Label {
                anchors.centerIn: parent
                visible: !AppController.jsonlStore.loading
                         && AppController.jsonlStore.totalCount > 0
                         && AppController.jsonlStore.filteredCount === 0
                text: "No entries match the current filter"
                font.pixelSize: 14
                color: Theme.textMuted
            }
        }

        // Status bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 22
            color: Theme.bgFooter

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: Theme.sp12

                Label {
                    text: "JSONL Viewer"
                    font.pixelSize: Theme.fontSizeS
                    color: Theme.textMuted
                }

                Item { Layout.fillWidth: true }

                Label {
                    text: {
                        let total = AppController.jsonlStore.totalCount
                        let filtered = AppController.jsonlStore.filteredCount
                        if (total === 0) return ""
                        if (filtered === total) return total + " entries"
                        return filtered + " / " + total + " entries"
                    }
                    font.pixelSize: Theme.fontSizeS
                    color: Theme.textMuted
                }
            }
        }
    }

    // Keyboard shortcuts
    Shortcut {
        sequence: "Ctrl+F"
        onActivated: searchField.forceActiveFocus()
    }

    // Toast for copy
    Connections {
        target: AppController.jsonlStore
        function onCopied(preview) {
            // Bubble up via toast — Main.qml handles this
        }
    }
}
