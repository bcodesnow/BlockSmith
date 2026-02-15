import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import BlockSmith

Dialog {
    id: searchDialog

    parent: Overlay.overlay
    anchors.centerIn: parent
    width: Math.min(parent.width * 0.7, 700)
    height: Math.min(parent.height * 0.7, 500)

    modal: true
    title: "Search All Files"
    standardButtons: Dialog.Close

    property var results: []

    function focusSearch() {
        searchInput.forceActiveFocus()
        searchInput.selectAll()
    }

    onOpened: focusSearch()

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.sp8

        // Search input
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            color: Theme.bg
            radius: Theme.radius
            border.color: searchInput.activeFocus ? Theme.borderFocus : Theme.border
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 4
                spacing: 6

                Label {
                    text: "\uD83D\uDD0D"
                    font.pixelSize: 14
                    color: Theme.textMuted
                }

                TextField {
                    id: searchInput
                    Layout.fillWidth: true
                    placeholderText: "Search across all project files..."
                    placeholderTextColor: Theme.textPlaceholder
                    font.pixelSize: Theme.fontSizeL
                    color: Theme.textPrimary
                    background: null

                    onTextChanged: {
                        searchTimer.restart()
                    }
                }

                Label {
                    text: searchDialog.results.length + " result" + (searchDialog.results.length !== 1 ? "s" : "")
                    font.pixelSize: Theme.fontSizeXS
                    color: Theme.textMuted
                    visible: searchInput.text.length >= 2
                }
            }
        }

        Timer {
            id: searchTimer
            interval: 300
            onTriggered: {
                if (searchInput.text.length >= 2) {
                    searchDialog.results = AppController.searchFiles(searchInput.text)
                } else {
                    searchDialog.results = []
                }
            }
        }

        // Results list
        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: searchDialog.results
            spacing: 1

            delegate: Rectangle {
                width: ListView.view.width
                height: resultLayout.implicitHeight + 8
                color: resultMa.containsMouse ? Theme.bgCardHov : Theme.bgPanel
                radius: 2

                MouseArea {
                    id: resultMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        AppController.openFile(modelData.filePath)
                        searchDialog.close()
                    }
                }

                RowLayout {
                    id: resultLayout
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: Theme.sp8

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Label {
                            text: modelData.text
                            font.family: Theme.fontMono
                            font.pixelSize: Theme.fontSizeM
                            color: Theme.textPrimary
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Label {
                            text: modelData.filePath
                            font.pixelSize: Theme.fontSizeS
                            color: Theme.textMuted
                            elide: Text.ElideMiddle
                            Layout.fillWidth: true
                        }
                    }

                    Label {
                        text: ":" + modelData.line
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.fontSizeXS
                        color: Theme.accent
                    }
                }
            }

            // Empty state
            Label {
                anchors.centerIn: parent
                visible: parent.count === 0 && searchInput.text.length >= 2
                text: "No results found."
                font.pixelSize: Theme.fontSizeL
                color: Theme.textMuted
            }

            Label {
                anchors.centerIn: parent
                visible: searchInput.text.length < 2
                text: "Type at least 2 characters to search."
                font.pixelSize: Theme.fontSizeL
                color: Theme.textMuted
            }
        }
    }
}
