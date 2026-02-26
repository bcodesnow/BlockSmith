import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import BlockSmith

ColumnLayout {
    spacing: Theme.sp12

    property alias claudeCodeChecked: claudeCodeCheck.checked

    function loadFromConfig() {
        claudeCodeCheck.checked = AppController.configManager.includeClaudeCodeFolder
    }

    function saveToConfig() {
        AppController.configManager.includeClaudeCodeFolder = claudeCodeCheck.checked
    }

    Label {
        text: "Claude Code"
        font.bold: true
        color: Theme.textPrimary
    }

    CheckBox {
        id: claudeCodeCheck
        text: "Include Claude Code folder in project tree"
        checked: false
    }

    Label {
        text: AppController.configManager.claudeCodeFolderPath()
        color: Theme.textMuted
        font.family: Theme.fontMono
        font.pixelSize: Theme.fontSizeXS
        Layout.leftMargin: 24
    }

    Label {
        text: "Adds ~/.claude to the project tree for browsing transcripts,\nproject configs, and other Claude Code internal files."
        color: Theme.textMuted
        font.pixelSize: Theme.fontSizeXS
        wrapMode: Text.Wrap
        Layout.fillWidth: true
        Layout.leftMargin: 24
        lineHeight: 1.3
    }

    Item { Layout.fillHeight: true }
}
