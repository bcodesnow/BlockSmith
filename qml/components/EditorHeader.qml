import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import BlockSmith

Rectangle {
    id: header
    color: Theme.bgHeader

    required property int viewMode
    required property bool editorVisible
    required property bool hasPreviewPane
    required property bool isJsonlActive
    required property var editorTextArea   // TextArea ref for undo/redo

    signal viewModeSelected(int mode)

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 4

        // File path
        Label {
            text: {
                if (header.isJsonlActive)
                    return AppController.jsonlStore.filePath
                return AppController.currentDocument.filePath
                       ? AppController.currentDocument.filePath
                       : "No file open"
            }
            font.pixelSize: Theme.fontSizeM
            color: Theme.textSecondary
            elide: Text.ElideMiddle
            Layout.fillWidth: true
        }

        // Modified indicator
        Label {
            visible: AppController.currentDocument.modified && !header.isJsonlActive
            text: "\u25CF"
            font.pixelSize: Theme.fontSizeS
            color: Theme.accentGold
            ToolTip.text: "Unsaved changes"
            ToolTip.visible: modifiedMa.containsMouse
            MouseArea {
                id: modifiedMa
                anchors.fill: parent
                hoverEnabled: true
            }
        }

        // Edit / Split / Preview toggle
        Rectangle {
            visible: header.hasPreviewPane
            Layout.preferredWidth: modeRow.implicitWidth + 4
            Layout.preferredHeight: 24
            color: Theme.bgPanel
            radius: Theme.radius

            RowLayout {
                id: modeRow
                anchors.fill: parent
                spacing: 0

                component ModeBtn: Button {
                    required property int mode
                    flat: true
                    font.pixelSize: Theme.fontSizeXS
                    Layout.preferredHeight: 24
                    palette.buttonText: header.viewMode === mode ? Theme.textWhite : Theme.textSecondary
                    background: Rectangle {
                        color: header.viewMode === mode ? Theme.bgActive : "transparent"
                        radius: Theme.radius
                    }
                    onClicked: header.viewModeSelected(mode)
                }

                ModeBtn { text: "Edit"; mode: MainContent.ViewMode.Edit }
                ModeBtn { text: "Split"; mode: MainContent.ViewMode.Split }
                ModeBtn { text: "Preview"; mode: MainContent.ViewMode.Preview }
            }
        }

        // Toolbar toggle
        Rectangle {
            width: 26; height: 24; radius: Theme.radius
            color: toolbarToggleMa.containsMouse ? Theme.bgButtonHov : "transparent"
            visible: header.editorVisible
            ToolTip.text: AppController.configManager.editorToolbarVisible ? "Hide toolbar" : "Show toolbar"
            ToolTip.visible: toolbarToggleMa.containsMouse
            ToolTip.delay: 400

            Label {
                anchors.centerIn: parent
                text: "\u2261"
                font.pixelSize: 16
                color: AppController.configManager.editorToolbarVisible ? Theme.textPrimary : Theme.textMuted
            }
            MouseArea {
                id: toolbarToggleMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    AppController.configManager.editorToolbarVisible = !AppController.configManager.editorToolbarVisible
                }
            }
        }

        // Undo button
        Button {
            visible: header.editorVisible
            text: "\u21B6"
            flat: true
            font.pixelSize: 14
            enabled: header.editorTextArea ? header.editorTextArea.canUndo : false
            Layout.preferredWidth: 26
            Layout.preferredHeight: 24
            palette.buttonText: enabled ? Theme.textPrimary : Theme.textMuted
            ToolTip.text: "Undo (Ctrl+Z)"
            ToolTip.visible: hovered
            ToolTip.delay: 400
            background: Rectangle {
                color: parent.hovered && parent.enabled ? Theme.bgButtonHov : "transparent"
                radius: Theme.radius
            }
            onClicked: header.editorTextArea.undo()
        }

        // Redo button
        Button {
            visible: header.editorVisible
            text: "\u21B7"
            flat: true
            font.pixelSize: 14
            enabled: header.editorTextArea ? header.editorTextArea.canRedo : false
            Layout.preferredWidth: 26
            Layout.preferredHeight: 24
            palette.buttonText: enabled ? Theme.textPrimary : Theme.textMuted
            ToolTip.text: "Redo (Ctrl+Shift+Z)"
            ToolTip.visible: hovered
            ToolTip.delay: 400
            background: Rectangle {
                color: parent.hovered && parent.enabled ? Theme.bgButtonHov : "transparent"
                radius: Theme.radius
            }
            onClicked: header.editorTextArea.redo()
        }

        // Save button
        Button {
            visible: !header.isJsonlActive
            text: "Save"
            flat: true
            font.pixelSize: Theme.fontSizeXS
            enabled: AppController.currentDocument.modified
            Layout.preferredHeight: 24
            palette.buttonText: enabled ? Theme.textPrimary : Theme.textMuted
            background: Rectangle {
                color: parent.hovered && parent.enabled ? Theme.bgButtonHov : Theme.bgButton
                radius: Theme.radius
                border.color: Theme.borderHover
                border.width: 1
            }
            onClicked: AppController.currentDocument.save()
        }
    }
}
