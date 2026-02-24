import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import BlockSmith

Rectangle {
    id: statusBar

    required property int viewMode
    required property int editorCursorPosition

    Layout.fillWidth: true
    Layout.preferredHeight: 22
    color: Theme.bgFooter
    visible: AppController.currentDocument.filePath !== ""

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 12

        // Save-state indicator dot
        Rectangle {
            id: saveDot
            width: 8; height: 8; radius: 4
            color: AppController.currentDocument.modified ? Theme.accentGold : Theme.accentGreen
            opacity: AppController.currentDocument.modified ? 1.0 : 0.6
            ToolTip.text: AppController.currentDocument.modified ? "Unsaved changes" : "Saved"
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
            Connections {
                target: AppController.currentDocument
                function onSaved() { saveFlash.restart() }
            }
        }

        // Cursor position
        Label {
            text: {
                if (statusBar.viewMode === MainContent.ViewMode.Preview) return "Preview mode"
                let pos = statusBar.editorCursorPosition
                let content = AppController.currentDocument.rawContent
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

            Connections {
                target: AppController.currentDocument
                function onAutoSaved() { autoSaveFlash.restart() }
            }
        }

        // Encoding
        Label {
            text: AppController.currentDocument.encoding
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
                let c = AppController.currentDocument.rawContent
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
}
