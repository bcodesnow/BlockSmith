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
                let doc = AppController.currentDocument
                if (doc) {
                    if (banner.isDeleted)
                        doc.clear()
                    else
                        doc.reload()
                }
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

    // Dynamic document signal connections
    property var _oldDoc: null
    property var _connFuncs: []
    function reconnectDocSignals() {
        if (_oldDoc) {
            for (let entry of _connFuncs)
                _oldDoc[entry.sig].disconnect(entry.fn)
        }
        _connFuncs = []
        let doc = AppController.currentDocument
        _oldDoc = doc
        if (!doc) return
        let f1 = function() {
            banner.isDeleted = false
            banner.visible = true
        }
        let f2 = function() {
            banner.isDeleted = true
            banner.visible = true
        }
        let f3 = function() {
            banner.visible = false
            banner.filePathChanged()
        }
        doc.fileChangedExternally.connect(f1)
        doc.fileDeletedExternally.connect(f2)
        doc.filePathChanged.connect(f3)
        _connFuncs.push({ sig: "fileChangedExternally", fn: f1 })
        _connFuncs.push({ sig: "fileDeletedExternally", fn: f2 })
        _connFuncs.push({ sig: "filePathChanged", fn: f3 })
    }
    Connections {
        target: AppController
        function onCurrentDocumentChanged() { banner.reconnectDocSignals() }
    }
    Component.onCompleted: reconnectDocSignals()
}
