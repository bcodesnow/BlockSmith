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
        JsonlFilterBar {
            id: filterBar
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

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AlwaysOn
                    background: Rectangle { color: Theme.bg }
                    contentItem: Rectangle {
                        implicitWidth: 8
                        radius: 4
                        color: parent.pressed ? Theme.bgButtonPrs
                             : parent.hovered ? Theme.bgButtonHov : Theme.borderHover
                    }
                }
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
        enabled: viewer.visible
        onActivated: filterBar.searchField.forceActiveFocus()
    }

    // Toast for copy
    Connections {
        target: AppController.jsonlStore
        function onCopied(preview) {
            // Bubble up via toast — Main.qml handles this
        }
    }
}
