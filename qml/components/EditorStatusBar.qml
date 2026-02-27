import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import BlockSmith

Rectangle {
    id: statusBar

    required property int viewMode
    required property int editorCursorPosition

    readonly property var doc: AppController.currentDocument

    Layout.fillWidth: true
    Layout.preferredHeight: 22
    color: Theme.bgFooter
    visible: doc && doc.filePath !== ""

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 12

        // Save-state indicator dot
        Rectangle {
            id: saveDot
            width: 8; height: 8; radius: 4
            color: statusBar.doc && statusBar.doc.modified ? Theme.accentGold : Theme.accentGreen
            opacity: statusBar.doc && statusBar.doc.modified ? 1.0 : 0.6
            ToolTip.text: statusBar.doc && statusBar.doc.modified ? "Unsaved changes" : "Saved"
            ToolTip.visible: saveDotMa.containsMouse
            ToolTip.delay: 400
            MouseArea {
                id: saveDotMa
                anchors.fill: parent
                hoverEnabled: true
            }
            SequentialAnimation on opacity {
                id: saveFlash
                running: false
                NumberAnimation { to: 1.0; duration: 0 }
                PauseAnimation { duration: 800 }
                NumberAnimation { to: 0.6; duration: 300 }
            }
        }

        // Cursor position
        Label {
            text: {
                if (statusBar.viewMode === MainContent.ViewMode.Preview) return "Preview mode"
                let doc = statusBar.doc
                if (!doc) return ""
                let pos = statusBar.editorCursorPosition
                let content = doc.rawContent
                let line = content.substring(0, pos).split("\n").length
                let lastNl = content.lastIndexOf("\n", pos - 1)
                let col = pos - (lastNl >= 0 ? lastNl : 0)
                return "Ln " + line + ", Col " + col
            }
            font.pixelSize: Theme.fontSizeS
            color: Theme.textMuted
        }

        Item { Layout.fillWidth: true }

        // Auto-saved flash label
        Label {
            id: autoSavedLabel
            text: "Auto-saved"
            font.pixelSize: Theme.fontSizeS
            color: Theme.accentGreen
            opacity: 0
            visible: opacity > 0

            SequentialAnimation on opacity {
                id: autoSaveFlash
                running: false
                NumberAnimation { to: 1.0; duration: 100 }
                PauseAnimation { duration: 1500 }
                NumberAnimation { to: 0; duration: 500 }
            }
        }

        // Encoding
        Label {
            text: statusBar.doc ? statusBar.doc.encoding : ""
            font.pixelSize: Theme.fontSizeS
            color: Theme.textMuted
        }

        // Zoom indicator (only visible when != 100%)
        Label {
            text: AppController.configManager.zoomLevel + "%"
            font.pixelSize: Theme.fontSizeS
            color: Theme.textMuted
            visible: AppController.configManager.zoomLevel !== 100

            MouseArea {
                id: zoomMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: AppController.configManager.zoomLevel = 100
            }

            ToolTip.text: "Click to reset zoom"
            ToolTip.visible: zoomMa.containsMouse
            ToolTip.delay: 400
        }

        // Configurable stats
        Label {
            text: {
                let doc = statusBar.doc
                if (!doc) return ""
                let c = doc.rawContent
                if (!c || c.length === 0) return ""
                let cfg = AppController.configManager
                let parts = []
                let words = c.trim().length === 0 ? 0 : c.trim().split(/\s+/).length
                if (cfg.statusBarWordCount) parts.push(words + " words")
                if (cfg.statusBarCharCount) parts.push(c.length + " chars")
                if (cfg.statusBarLineCount) parts.push(c.split("\n").length + " lines")
                if (cfg.statusBarReadingTime) parts.push(Math.max(1, Math.ceil(words / 225)) + " min read")
                return parts.join("  |  ")
            }
            font.pixelSize: Theme.fontSizeS
            color: Theme.textMuted
        }
    }

    // Dynamic document signal connections
    property var _oldDoc: null
    property var _connFuncs: []
    function reconnectDocSignals() {
        if (_oldDoc) {
            for (let entry of _connFuncs)
                _oldDoc[entry.sig].disconnect(entry.fn)
        }
        _connFuncs = []
        let d = statusBar.doc
        _oldDoc = d
        if (!d) return
        let f1 = function() { saveFlash.restart() }
        let f2 = function() { autoSaveFlash.restart() }
        d.saved.connect(f1)
        d.autoSaved.connect(f2)
        _connFuncs.push({ sig: "saved", fn: f1 })
        _connFuncs.push({ sig: "autoSaved", fn: f2 })
    }
    onDocChanged: reconnectDocSignals()
    Component.onCompleted: reconnectDocSignals()
}
