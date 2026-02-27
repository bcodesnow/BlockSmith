import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import BlockSmith

ColumnLayout {
    spacing: Theme.sp12

    property alias searchPathsText: searchPathsArea.text
    property alias ignorePatternsText: ignorePatternsArea.text
    property alias triggerFilesText: triggerFilesArea.text
    property alias autoScanChecked: autoScanCheck.checked
    property alias scanDepthValue: scanDepthSpin.value

    function loadFromConfig() {
        searchPathsArea.text = [].concat(AppController.configManager.searchPaths).join("\n")
        ignorePatternsArea.text = [].concat(AppController.configManager.ignorePatterns).join("\n")
        triggerFilesArea.text = [].concat(AppController.configManager.triggerFiles).join("\n")
        autoScanCheck.checked = AppController.configManager.autoScanOnStartup
        scanDepthSpin.value = AppController.configManager.scanDepth
        searchMdCheck.checked = AppController.configManager.searchIncludeMarkdown
        searchJsonCheck.checked = AppController.configManager.searchIncludeJson
        searchYamlCheck.checked = AppController.configManager.searchIncludeYaml
        searchJsonlCheck.checked = AppController.configManager.searchIncludeJsonl
        searchTxtCheck.checked = AppController.configManager.searchIncludePlaintext
        searchPdfCheck.checked = AppController.configManager.searchIncludePdf
    }

    function saveToConfig() {
        let paths = searchPathsArea.text.split("\n").filter(s => s.trim().length > 0)
        let patterns = ignorePatternsArea.text.split("\n").filter(s => s.trim().length > 0)
        let triggers = triggerFilesArea.text.split("\n").filter(s => s.trim().length > 0)
        AppController.configManager.searchPaths = paths
        AppController.configManager.ignorePatterns = patterns
        AppController.configManager.triggerFiles = triggers
        AppController.configManager.autoScanOnStartup = autoScanCheck.checked
        AppController.configManager.scanDepth = scanDepthSpin.value
        AppController.configManager.searchIncludeMarkdown = searchMdCheck.checked
        AppController.configManager.searchIncludeJson = searchJsonCheck.checked
        AppController.configManager.searchIncludeYaml = searchYamlCheck.checked
        AppController.configManager.searchIncludeJsonl = searchJsonlCheck.checked
        AppController.configManager.searchIncludePlaintext = searchTxtCheck.checked
        AppController.configManager.searchIncludePdf = searchPdfCheck.checked
    }

    Label {
        text: "Search Paths"
        font.bold: true
        color: Theme.textPrimary
    }

    Label {
        text: "One directory per line. These will be scanned for projects."
        color: Theme.textMuted
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }

    ScrollView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 80

        TextArea {
            id: searchPathsArea
            placeholderText: "C:/Users/you/projects\nC:/Users/you/work"
            placeholderTextColor: Theme.textPlaceholder
            font.family: Theme.fontMono
            wrapMode: TextArea.NoWrap
            color: Theme.textEditor
            background: Rectangle {
                color: Theme.bg
                radius: Theme.radius
                border.color: Theme.border
                border.width: 1
            }
        }
    }

    Label {
        text: "Ignore Patterns"
        font.bold: true
        color: Theme.textPrimary
    }

    Label {
        text: "Directory names to skip during scanning. One per line."
        color: Theme.textMuted
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }

    ScrollView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 60

        TextArea {
            id: ignorePatternsArea
            placeholderText: "node_modules\n.git\nbuild"
            placeholderTextColor: Theme.textPlaceholder
            font.family: Theme.fontMono
            wrapMode: TextArea.NoWrap
            color: Theme.textEditor
            background: Rectangle {
                color: Theme.bg
                radius: Theme.radius
                border.color: Theme.border
                border.width: 1
            }
        }
    }

    Label {
        text: "Project Markers"
        font.bold: true
        color: Theme.textPrimary
    }

    Label {
        text: "File or directory names that mark a project root (e.g. CLAUDE.md, .git)."
        color: Theme.textMuted
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }

    ScrollView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 50

        TextArea {
            id: triggerFilesArea
            placeholderText: "CLAUDE.md\nAGENTS.md\n.git"
            placeholderTextColor: Theme.textPlaceholder
            font.family: Theme.fontMono
            wrapMode: TextArea.NoWrap
            color: Theme.textEditor
            background: Rectangle {
                color: Theme.bg
                radius: Theme.radius
                border.color: Theme.border
                border.width: 1
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: Theme.border
    }

    CheckBox {
        id: autoScanCheck
        text: "Auto-scan on startup"
        checked: true
    }

    Label {
        text: "Global Search Formats"
        font.bold: true
        color: Theme.textPrimary
    }

    Label {
        text: "Choose which file types are included in Ctrl+Shift+F results."
        color: Theme.textMuted
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }

    Flow {
        Layout.fillWidth: true
        spacing: Theme.sp16

        CheckBox {
            id: searchMdCheck
            text: "Markdown (.md)"
            checked: true
        }

        CheckBox {
            id: searchJsonCheck
            text: "JSON (.json)"
            checked: true
        }

        CheckBox {
            id: searchYamlCheck
            text: "YAML (.yaml/.yml)"
            checked: true
        }

        CheckBox {
            id: searchJsonlCheck
            text: "JSONL (.jsonl)"
            checked: false
        }

        CheckBox {
            id: searchTxtCheck
            text: "Plain Text (.txt)"
            checked: true
        }

        CheckBox {
            id: searchPdfCheck
            text: "PDF (.pdf)"
            checked: false
        }
    }

    RowLayout {
        spacing: Theme.sp8

        Label { text: "Scan depth:" }

        SpinBox {
            id: scanDepthSpin
            from: 0
            to: 50
            value: 0
            editable: true

            textFromValue: function(value) {
                return value === 0 ? "Unlimited" : value.toString()
            }
            valueFromText: function(text) {
                if (text.toLowerCase() === "unlimited") return 0
                return parseInt(text) || 0
            }
        }

        Label {
            text: "0 = unlimited"
            color: Theme.textMuted
        }
    }

    Item { Layout.fillHeight: true }
}
