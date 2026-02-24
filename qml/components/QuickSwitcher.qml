import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import BlockSmith

Popup {
    id: quickSwitcher

    parent: Overlay.overlay
    x: Math.round((parent.width - width) / 2)
    y: Math.round(parent.height * 0.15)
    width: Math.min(parent.width * 0.6, 600)
    height: Math.min(parent.height * 0.55, 450)

    modal: true
    dim: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    padding: 0

    property var filteredResults: []
    property int selectedIndex: 0

    function openSwitcher() {
        filterInput.text = ""
        selectedIndex = 0
        updateResults()
        open()
        filterInput.forceActiveFocus()
    }

    onClosed: {
        filterInput.text = ""
        filteredResults = []
    }

    function updateResults() {
        filteredResults = AppController.fuzzyFilterFiles(filterInput.text)
        selectedIndex = filteredResults.length > 0 ? 0 : -1
    }

    function navigateUp() {
        if (filteredResults.length > 0 && selectedIndex > 0)
            selectedIndex--
    }

    function navigateDown() {
        if (filteredResults.length > 0 && selectedIndex < filteredResults.length - 1)
            selectedIndex++
    }

    function acceptCurrent() {
        if (selectedIndex >= 0 && selectedIndex < filteredResults.length) {
            let path = filteredResults[selectedIndex].filePath
            close()
            AppController.openFile(path)
        }
    }

    background: Rectangle {
        color: Theme.bgPanel
        border.color: Theme.border
        border.width: 1
        radius: 6
    }

    Overlay.modal: Rectangle {
        color: Qt.rgba(0, 0, 0, 0.4)
    }

    Timer {
        id: filterTimer
        interval: 80
        onTriggered: quickSwitcher.updateResults()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 0
        spacing: 0

        // Search input
        TextField {
            id: filterInput
            Layout.fillWidth: true
            Layout.preferredHeight: 38
            Layout.margins: 8
            Layout.bottomMargin: 4
            placeholderText: "Type to search files..."
            font.pixelSize: Theme.fontSizeL
            color: Theme.textPrimary
            placeholderTextColor: Theme.textPlaceholder
            background: Rectangle {
                color: Theme.bg
                radius: Theme.radius
                border.color: filterInput.activeFocus ? Theme.borderFocus : Theme.borderHover
                border.width: 1
            }

            onTextChanged: filterTimer.restart()

            Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Down) {
                    quickSwitcher.navigateDown()
                    event.accepted = true
                } else if (event.key === Qt.Key_Up) {
                    quickSwitcher.navigateUp()
                    event.accepted = true
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    quickSwitcher.acceptCurrent()
                    event.accepted = true
                }
            }
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.border
        }

        // Results list
        ListView {
            id: resultsList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: quickSwitcher.filteredResults
            currentIndex: quickSwitcher.selectedIndex

            delegate: Rectangle {
                width: ListView.view.width
                height: 42
                color: index === quickSwitcher.selectedIndex
                       ? Theme.bgSelection
                       : (resultMa.containsMouse ? Theme.bgCardHov : "transparent")

                MouseArea {
                    id: resultMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        quickSwitcher.selectedIndex = index
                        quickSwitcher.acceptCurrent()
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    anchors.topMargin: 4
                    anchors.bottomMargin: 4
                    spacing: 1

                    RowLayout {
                        spacing: 6
                        Layout.fillWidth: true

                        Label {
                            visible: modelData.isRecent
                            text: "\u25CB"
                            font.pixelSize: Theme.fontSizeS
                            color: Theme.textMuted
                        }

                        Label {
                            text: modelData.fileName
                            font.pixelSize: Theme.fontSizeM
                            font.bold: true
                            color: Theme.textPrimary
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    Label {
                        text: modelData.dirPath
                        font.pixelSize: Theme.fontSizeS
                        color: Theme.textMuted
                        elide: Text.ElideMiddle
                        Layout.fillWidth: true
                    }
                }
            }

            // Empty state
            Label {
                anchors.centerIn: parent
                visible: quickSwitcher.filteredResults.length === 0
                text: filterInput.text.length === 0
                      ? "Start typing to search files..."
                      : "No matching files."
                font.pixelSize: Theme.fontSizeM
                color: Theme.textMuted
            }
        }
    }
}
