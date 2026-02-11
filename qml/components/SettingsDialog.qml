import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import BlockSmith

Dialog {
    id: dialog

    parent: Overlay.overlay
    anchors.centerIn: parent
    width: 560
    height: 680

    modal: true
    title: "Settings"
    standardButtons: Dialog.Save | Dialog.Cancel

    property var editSearchPaths: []
    property var editIgnorePatterns: []

    onOpened: {
        searchPathsArea.text = [].concat(AppController.configManager.searchPaths).join("\n")
        ignorePatternsArea.text = [].concat(AppController.configManager.ignorePatterns).join("\n")
        triggerFilesArea.text = [].concat(AppController.configManager.triggerFiles).join("\n")
        autoScanCheck.checked = AppController.configManager.autoScanOnStartup
        syntaxHighlightCheck.checked = AppController.configManager.syntaxHighlightEnabled
    }

    onAccepted: {
        let paths = searchPathsArea.text.split("\n").filter(s => s.trim().length > 0)
        let patterns = ignorePatternsArea.text.split("\n").filter(s => s.trim().length > 0)
        let triggers = triggerFilesArea.text.split("\n").filter(s => s.trim().length > 0)
        AppController.configManager.searchPaths = paths
        AppController.configManager.ignorePatterns = patterns
        AppController.configManager.triggerFiles = triggers
        AppController.configManager.autoScanOnStartup = autoScanCheck.checked
        AppController.configManager.syntaxHighlightEnabled = syntaxHighlightCheck.checked
        AppController.configManager.save()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        Label {
            text: "Search Paths"
            font.bold: true
        }

        Label {
            text: "One directory per line. These will be scanned for projects."
            color: "#666"
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: 140

            TextArea {
                id: searchPathsArea
                placeholderText: "C:/Users/you/projects\nC:/Users/you/work"
                font.family: "Consolas"
                wrapMode: TextArea.NoWrap
            }
        }

        Label {
            text: "Ignore Patterns"
            font.bold: true
        }

        Label {
            text: "Directory names to skip during scanning. One per line."
            color: "#666"
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: 100

            TextArea {
                id: ignorePatternsArea
                placeholderText: "node_modules\n.git\nbuild"
                font.family: "Consolas"
                wrapMode: TextArea.NoWrap
            }
        }

        Label {
            text: "Project Markers"
            font.bold: true
        }

        Label {
            text: "File or directory names that mark a project root (e.g. CLAUDE.md, .git)."
            color: "#666"
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: 80

            TextArea {
                id: triggerFilesArea
                placeholderText: "CLAUDE.md\nAGENTS.md\n.git"
                font.family: "Consolas"
                wrapMode: TextArea.NoWrap
            }
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: "#444"
        }

        Label {
            text: "Options"
            font.bold: true
        }

        CheckBox {
            id: autoScanCheck
            text: "Auto-scan on startup"
            checked: true
        }

        CheckBox {
            id: syntaxHighlightCheck
            text: "Syntax highlighting in editor"
            checked: true
        }
    }
}
