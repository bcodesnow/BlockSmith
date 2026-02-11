import QtQuick
import QtQuick.Controls

Rectangle {
    id: toast

    property string message: ""
    property int duration: 2000

    function show(msg) {
        message = msg
        opacity = 1.0
        hideTimer.restart()
    }

    parent: Overlay.overlay
    anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
    anchors.bottom: parent ? parent.bottom : undefined
    anchors.bottomMargin: 40

    width: toastLabel.implicitWidth + 32
    height: 36
    radius: 18
    color: "#333"
    border.color: "#555"
    border.width: 1
    opacity: 0.0
    visible: opacity > 0

    Behavior on opacity {
        NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
    }

    Label {
        id: toastLabel
        anchors.centerIn: parent
        text: toast.message
        font.pixelSize: 12
        color: "#ddd"
    }

    Timer {
        id: hideTimer
        interval: toast.duration
        onTriggered: toast.opacity = 0.0
    }
}
