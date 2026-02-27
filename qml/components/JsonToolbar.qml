import QtQuick
import QtQuick.Controls
import BlockSmith

Rectangle {
    id: root
    height: 32
    color: Theme.bgHeader
    signal notify(string message)

    Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 8
        spacing: 6

        Button {
            text: "Format JSON"
            flat: true
            height: 24
            font.pixelSize: Theme.fontSizeS
            palette.buttonText: Theme.textPrimary
            background: Rectangle {
                color: parent.hovered ? Theme.bgButtonHov : Theme.bgButton
                radius: Theme.radius
                border.color: Theme.borderHover
                border.width: 1
            }
            onClicked: {
                let doc = AppController.currentDocument
                if (!doc) return
                let result = doc.prettifyJson()
                if (result.length > 0) {
                    doc.rawContent = result
                } else {
                    root.notify("Invalid JSON — cannot format")
                }
            }
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Theme.border
    }
}

