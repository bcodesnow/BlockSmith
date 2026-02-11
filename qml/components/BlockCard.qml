import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: card

    property string blockId: ""
    property string blockName: ""
    property string blockContent: ""
    property var blockTags: []

    signal clicked()
    signal editRequested()
    signal insertRequested()

    implicitHeight: cardLayout.implicitHeight + 16
    color: hovered ? "#383838" : "#2f2f2f"
    radius: 4
    border.color: "#444"
    border.width: 1

    property bool hovered: cardMa.containsMouse || insertMa.containsMouse

    MouseArea {
        id: cardMa
        anchors.fill: parent
        hoverEnabled: true
        onClicked: card.clicked()
        onDoubleClicked: card.editRequested()
    }

    ColumnLayout {
        id: cardLayout
        anchors.fill: parent
        anchors.margins: 8
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Label {
                text: card.blockName
                font.pixelSize: 12
                font.bold: true
                color: "#ddd"
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Label {
                text: card.blockId
                font.pixelSize: 9
                font.family: "Consolas"
                color: "#666"
            }

            // Insert into file button — always present, styled on hover
            Rectangle {
                width: insertRow.implicitWidth + 12
                height: 22
                radius: 3
                color: insertMa.containsMouse ? "#4a6a9a" : (card.hovered ? "#3a3a3a" : "transparent")
                border.color: card.hovered ? "#6c9bd2" : "transparent"
                border.width: 1
                opacity: card.hovered ? 1.0 : 0.0
                ToolTip.text: "Insert into current file"
                ToolTip.visible: insertMa.containsMouse
                ToolTip.delay: 400

                Row {
                    id: insertRow
                    anchors.centerIn: parent
                    spacing: 3

                    Label {
                        text: "\u2913"
                        font.pixelSize: 13
                        color: "#6c9bd2"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Label {
                        text: "Insert"
                        font.pixelSize: 10
                        color: "#ccc"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: insertMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: card.insertRequested()
                }
            }
        }

        // Content preview
        Label {
            text: card.blockContent.substring(0, 120).replace(/\n/g, " ")
            font.pixelSize: 11
            color: "#999"
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        // Tags
        Flow {
            Layout.fillWidth: true
            spacing: 4
            visible: card.blockTags.length > 0

            Repeater {
                model: card.blockTags
                Rectangle {
                    width: tagLabel.implicitWidth + 10
                    height: 18
                    radius: 9
                    color: "#3d5a80"

                    Label {
                        id: tagLabel
                        anchors.centerIn: parent
                        text: modelData
                        font.pixelSize: 10
                        color: "#ccc"
                    }
                }
            }
        }
    }
}
