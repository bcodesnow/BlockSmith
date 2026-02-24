import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import BlockSmith

Rectangle {
    id: footer

    signal scanClicked()
    signal newProjectClicked()
    signal settingsClicked()

    Layout.fillWidth: true
    Layout.preferredHeight: 44
    color: Theme.bgHeader

    RowLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 6

        Button {
            Layout.fillWidth: true
            flat: true
            palette.buttonText: Theme.textPrimary
            background: Rectangle {
                color: parent.hovered ? Theme.bgButtonHov : Theme.bgButton
                radius: Theme.radius
                border.color: Theme.borderHover
                border.width: 1
            }
            onClicked: footer.scanClicked()

            contentItem: Row {
                anchors.centerIn: parent
                spacing: 5
                Label {
                    text: "\u21BB"
                    font.pixelSize: 14
                    color: Theme.textPrimary
                    anchors.verticalCenter: parent.verticalCenter
                }
                Label {
                    text: "Scan"
                    font.pixelSize: Theme.fontSizeM
                    color: Theme.textPrimary
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        Button {
            Layout.fillWidth: true
            flat: true
            palette.buttonText: Theme.textPrimary
            background: Rectangle {
                color: parent.hovered ? Theme.bgButtonHov : Theme.bgButton
                radius: Theme.radius
                border.color: Theme.borderHover
                border.width: 1
            }
            onClicked: footer.newProjectClicked()

            contentItem: Row {
                anchors.centerIn: parent
                spacing: 5
                Label {
                    text: "+"
                    font.pixelSize: 14
                    font.bold: true
                    color: Theme.textPrimary
                    anchors.verticalCenter: parent.verticalCenter
                }
                Label {
                    text: "New"
                    font.pixelSize: Theme.fontSizeM
                    color: Theme.textPrimary
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        Button {
            Layout.fillWidth: true
            flat: true
            palette.buttonText: Theme.textPrimary
            background: Rectangle {
                color: parent.hovered ? Theme.bgButtonHov : Theme.bgButton
                radius: Theme.radius
                border.color: Theme.borderHover
                border.width: 1
            }
            onClicked: footer.settingsClicked()

            contentItem: Row {
                anchors.centerIn: parent
                spacing: 5
                Label {
                    text: "\u2699"
                    font.pixelSize: 14
                    color: Theme.textPrimary
                    anchors.verticalCenter: parent.verticalCenter
                }
                Label {
                    text: "Settings"
                    font.pixelSize: Theme.fontSizeM
                    color: Theme.textPrimary
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }
}
