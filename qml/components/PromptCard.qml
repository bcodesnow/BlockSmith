import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: card

    property string promptId: ""
    property string promptName: ""
    property string promptContent: ""
    property string promptCategory: ""

    signal copyRequested()
    signal editRequested()

    implicitHeight: cardLayout.implicitHeight + 16
    color: cardMa.containsMouse ? Theme.bgCardHov : Theme.bgCard
    radius: 4
    border.color: Theme.border
    border.width: 1

    MouseArea {
        id: cardMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: card.copyRequested()
        onDoubleClicked: card.editRequested()
    }

    ColumnLayout {
        id: cardLayout
        anchors.fill: parent
        anchors.margins: 8
        spacing: 4

        RowLayout {
            Layout.fillWidth: true

            Label {
                text: card.promptName
                font.pixelSize: Theme.fontSizeM
                font.bold: true
                color: Theme.textPrimary
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            // Copy button
            Rectangle {
                width: 22
                height: 22
                radius: Theme.radius
                color: copyMa.containsMouse ? Theme.borderHover : "transparent"

                Label {
                    anchors.centerIn: parent
                    text: "\u2398"  // clipboard symbol
                    font.pixelSize: 14
                    color: Theme.textSecondary
                }

                MouseArea {
                    id: copyMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: card.copyRequested()
                }
            }
        }

        // Content preview
        Label {
            text: card.promptContent.substring(0, 120).replace(/\n/g, " ")
            font.pixelSize: Theme.fontSizeXS
            color: Theme.textSecondary
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        // Category pill
        Rectangle {
            visible: card.promptCategory.length > 0
            width: catLabel.implicitWidth + 10
            height: 18
            radius: 9
            color: {
                switch(card.promptCategory) {
                    case "audit":    return "#5a3d3d"
                    case "review":   return "#3d5a3d"
                    case "debug":    return "#5a4d3d"
                    case "generate": return "#3d3d5a"
                    default:         return "#4a4a4a"
                }
            }

            Label {
                id: catLabel
                anchors.centerIn: parent
                text: card.promptCategory
                font.pixelSize: Theme.fontSizeS
                color: Theme.textPrimary
            }
        }
    }
}
