import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import BlockSmith

Dialog {
    id: dialog

    parent: Overlay.overlay
    anchors.centerIn: parent
    width: 560
    height: 760

    modal: true
    title: "Settings"
    standardButtons: Dialog.Save | Dialog.Cancel

    signal scanRequested()

    // Snapshot scan-relevant values to detect changes
    property var _prevPaths: ""
    property var _prevPatterns: ""
    property var _prevTriggers: ""
    property int _prevDepth: 0
    property bool _prevClaudeFolder: false

    onOpened: {
        _prevPaths = [].concat(AppController.configManager.searchPaths).join("\n")
        _prevPatterns = [].concat(AppController.configManager.ignorePatterns).join("\n")
        _prevTriggers = [].concat(AppController.configManager.triggerFiles).join("\n")
        _prevDepth = AppController.configManager.scanDepth
        _prevClaudeFolder = AppController.configManager.includeClaudeCodeFolder
        searchPathsArea.text = [].concat(AppController.configManager.searchPaths).join("\n")
        ignorePatternsArea.text = [].concat(AppController.configManager.ignorePatterns).join("\n")
        triggerFilesArea.text = [].concat(AppController.configManager.triggerFiles).join("\n")
        autoScanCheck.checked = AppController.configManager.autoScanOnStartup
        syntaxHighlightCheck.checked = AppController.configManager.syntaxHighlightEnabled
        scanDepthSpin.value = AppController.configManager.scanDepth
        imageSubfolderField.text = AppController.configManager.imageSubfolder
        claudeCodeCheck.checked = AppController.configManager.includeClaudeCodeFolder
        sbWordCountCheck.checked = AppController.configManager.statusBarWordCount
        sbCharCountCheck.checked = AppController.configManager.statusBarCharCount
        sbLineCountCheck.checked = AppController.configManager.statusBarLineCount
        sbReadingTimeCheck.checked = AppController.configManager.statusBarReadingTime
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
        AppController.configManager.scanDepth = scanDepthSpin.value
        AppController.configManager.imageSubfolder = imageSubfolderField.text.trim() || "images"
        AppController.configManager.includeClaudeCodeFolder = claudeCodeCheck.checked
        AppController.configManager.statusBarWordCount = sbWordCountCheck.checked
        AppController.configManager.statusBarCharCount = sbCharCountCheck.checked
        AppController.configManager.statusBarLineCount = sbLineCountCheck.checked
        AppController.configManager.statusBarReadingTime = sbReadingTimeCheck.checked
        AppController.configManager.save()

        // Auto-rescan if scan-relevant settings changed
        if (searchPathsArea.text !== _prevPaths
            || ignorePatternsArea.text !== _prevPatterns
            || triggerFilesArea.text !== _prevTriggers
            || scanDepthSpin.value !== _prevDepth
            || claudeCodeCheck.checked !== _prevClaudeFolder) {
            scanRequested()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.sp12

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
            Layout.preferredHeight: 140

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
            Layout.preferredHeight: 100

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
            Layout.preferredHeight: 80

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

        // Separator
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.border
        }

        Label {
            text: "Options"
            font.bold: true
            color: Theme.textPrimary
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

        RowLayout {
            spacing: Theme.sp8

            Label {
                text: "Scan depth:"
            }

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

        RowLayout {
            spacing: Theme.sp8

            Label {
                text: "Image subfolder:"
            }

            TextField {
                id: imageSubfolderField
                text: "images"
                Layout.preferredWidth: 150
                font.family: Theme.fontMono
                color: Theme.textEditor
                background: Rectangle {
                    color: Theme.bg
                    radius: Theme.radius
                    border.color: Theme.border
                    border.width: 1
                }
            }

            Label {
                text: "Relative to document"
                color: Theme.textMuted
            }
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.border
        }

        Label {
            text: "Integrations"
            font.bold: true
            color: Theme.textPrimary
        }

        CheckBox {
            id: claudeCodeCheck
            text: "Include Claude Code folder"
            checked: false
        }

        Label {
            text: AppController.configManager.claudeCodeFolderPath()
            color: Theme.textMuted
            font.family: Theme.fontMono
            font.pixelSize: Theme.fontSizeXS
            Layout.leftMargin: 24
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.border
        }

        Label {
            text: "Status Bar"
            font.bold: true
            color: Theme.textPrimary
        }

        Flow {
            Layout.fillWidth: true
            spacing: Theme.sp16

            CheckBox {
                id: sbWordCountCheck
                text: "Word count"
                checked: true
            }
            CheckBox {
                id: sbCharCountCheck
                text: "Character count"
                checked: true
            }
            CheckBox {
                id: sbLineCountCheck
                text: "Line count"
                checked: true
            }
            CheckBox {
                id: sbReadingTimeCheck
                text: "Reading time"
                checked: true
            }
        }
    }
}
