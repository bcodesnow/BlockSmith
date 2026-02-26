import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import BlockSmith

Rectangle {
    id: banner
    color: Theme.isDark ? "#3d3520" : "#fff3cd"
    visible: false
    property bool isDeleted: false

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 8

        Label {
            text: banner.isDeleted
                  ? "File was deleted from disk."
                  : "File changed on disk."
            font.pixelSize: Theme.fontSizeS
            color: Theme.accentGold
            Layout.fillWidth: true
        }

        Button {
            text: banner.isDeleted ? "Close" : "Reload"
            flat: true
            font.pixelSize: Theme.fontSizeXS
            Layout.preferredHeight: 22
            palette.buttonText: Theme.textPrimary
            background: Rectangle {
                color: parent.hovered ? Theme.bgButtonHov : Theme.bgButton
                radius: Theme.radius
                border.color: Theme.borderHover
                border.width: 1
            }
            onClicked: {
                if (banner.isDeleted)
                    AppController.currentDocument.clear()
                else
                    AppController.currentDocument.reload()
                banner.visible = false
            }
        }

        Button {
            visible: !banner.isDeleted
            text: "Ignore"
            flat: true
            font.pixelSize: Theme.fontSizeXS
            Layout.preferredHeight: 22
            palette.buttonText: Theme.textSecondary
            background: Rectangle {
                color: parent.hovered ? Theme.bgButtonHov : "transparent"
                radius: Theme.radius
            }
            onClicked: banner.visible = false
        }
    }

    signal filePathChanged()

    Connections {
        target: AppController.currentDocument
        function onFileChangedExternally() {
            banner.isDeleted = false
            banner.visible = true
        }
        function onFileDeletedExternally() {
            banner.isDeleted = true
            banner.visible = true
        }
        function onFilePathChanged() {
            banner.visible = false
            banner.filePathChanged()
        }
    }
}
