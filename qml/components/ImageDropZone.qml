import QtQuick
import QtQuick.Controls
import BlockSmith

Item {
    id: dropZone

    signal imageDropped(string fileUrl)

    // Check if a URL points to a supported image format
    function isImageUrl(url) {
        let lower = url.toString().toLowerCase()
        return lower.endsWith(".png") || lower.endsWith(".jpg")
            || lower.endsWith(".jpeg") || lower.endsWith(".gif")
            || lower.endsWith(".svg") || lower.endsWith(".webp")
            || lower.endsWith(".bmp")
    }

    DropArea {
        anchors.fill: parent
        keys: ["text/uri-list"]

        onEntered: function(drag) {
            let dominated = false
            for (let i = 0; i < drag.urls.length; i++) {
                if (dropZone.isImageUrl(drag.urls[i])) { dominated = true; break }
            }
            drag.accepted = dominated
            dropOverlay.visible = dominated
        }

        onExited: dropOverlay.visible = false

        onDropped: function(drop) {
            dropOverlay.visible = false
            for (let i = 0; i < drop.urls.length; i++) {
                if (dropZone.isImageUrl(drop.urls[i]))
                    dropZone.imageDropped(drop.urls[i])
            }
        }
    }

    Rectangle {
        id: dropOverlay
        anchors.fill: parent
        visible: false
        color: Qt.rgba(0.42, 0.61, 0.82, 0.15)
        border.color: Theme.accent
        border.width: 2
        radius: 4
        z: 10

        Label {
            anchors.centerIn: parent
            text: "Drop image here"
            color: Theme.accent
            font.pixelSize: 16
        }
    }
}
