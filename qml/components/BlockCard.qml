import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: card

    property string blockId: ""
    property string blockName: ""
    property string blockContent: ""
    property var blockTags: []
    property int usageCount: 0
    property bool diverged: false

    signal clicked()
    signal editRequested()
    signal insertRequested()

    implicitHeight: cardLayout.implicitHeight + 16
    color: hovered ? Theme.bgCardHov : Theme.bgCard
    radius: 4
    border.color: Theme.border
    border.width: 1

    property bool hovered: cardMa.containsMouse || insertMa.containsMouse

    MouseArea {
        id: cardMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: card.clicked()
        onDoubleClicked: card.editRequested()
    }

    // Diverged indicator — orange left border
    Rectangle {
        visible: card.diverged
        width: 3
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.topMargin: 1
        anchors.bottomMargin: 1
        color: Theme.accentOrange
        radius: card.radius
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
                font.pixelSize: Theme.fontSizeM
                font.bold: true
                color: Theme.textPrimary
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Label {
                text: card.blockId
                font.pixelSize: Theme.fontSizeS
                font.family: Theme.fontMono
                color: Theme.textMuted
            }

            // Insert into file button — always present, styled on hover
            Rectangle {
                width: insertRow.implicitWidth + 12
                height: 22
                radius: Theme.radius
                color: insertMa.containsMouse ? "#4a6a9a" : (card.hovered ? Theme.bgButton : "transparent")
                border.color: card.hovered ? Theme.accent : "transparent"
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
                        font.pixelSize: Theme.fontSizeL
                        color: Theme.accent
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Label {
                        text: "Insert"
                        font.pixelSize: Theme.fontSizeS
                        color: Theme.textPrimary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: insertMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: card.insertRequested()
                }
            }
        }

        // Content preview
        Label {
            text: card.blockContent.substring(0, 120).replace(/\n/g, " ")
            font.pixelSize: Theme.fontSizeXS
            color: Theme.textSecondary
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        // Tags + usage
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

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
                            font.pixelSize: Theme.fontSizeS
                            color: Theme.textPrimary
                        }
                    }
                }
            }

            Label {
                visible: card.usageCount > 0
                text: card.usageCount + (card.usageCount === 1 ? " file" : " files")
                font.pixelSize: Theme.fontSizeS
                color: Theme.accentGreen
            }
        }
    }
}
