import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import BlockSmith

Dialog {
    id: dialog

    parent: Overlay.overlay
    anchors.centerIn: parent
    width: 560
    height: 580

    modal: true
    title: "Settings"
    standardButtons: Dialog.Save | Dialog.Cancel
    palette.accent: Theme.accent
    palette.highlight: Theme.accent

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
        autoSaveCheck.checked = AppController.configManager.autoSaveEnabled
        autoSaveIntervalSpin.value = AppController.configManager.autoSaveInterval
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
        AppController.configManager.autoSaveEnabled = autoSaveCheck.checked
        AppController.configManager.autoSaveInterval = autoSaveIntervalSpin.value
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
        spacing: 0

        TabBar {
            id: tabBar
            Layout.fillWidth: true

            TabButton {
                text: "Projects"
                width: implicitWidth
            }
            TabButton {
                text: "Editor"
                width: implicitWidth
            }
            TabButton {
                text: "Integrations"
                width: implicitWidth
            }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: tabBar.currentIndex

            // ── Tab 0: Projects ──
            ColumnLayout {
                spacing: Theme.sp12
                Layout.topMargin: Theme.sp12

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

            // ── Tab 1: Editor ──
            ColumnLayout {
                spacing: Theme.sp12
                Layout.topMargin: Theme.sp12

                CheckBox {
                    id: syntaxHighlightCheck
                    text: "Syntax highlighting in editor"
                    checked: true

                }

                RowLayout {
                    spacing: Theme.sp8

                    Label { text: "Image subfolder:" }

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

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Theme.border
                }

                Label {
                    text: "Auto-Save"
                    font.bold: true
                    color: Theme.textPrimary
                }

                CheckBox {
                    id: autoSaveCheck
                    text: "Enable auto-save"
                    checked: false

                }

                RowLayout {
                    spacing: Theme.sp8
                    enabled: autoSaveCheck.checked
                    opacity: enabled ? 1.0 : 0.5

                    Label { text: "Interval:" }

                    SpinBox {
                        id: autoSaveIntervalSpin
                        from: 5
                        to: 600
                        value: 30
                        editable: true
                        stepSize: 5
                    }

                    Label {
                        text: "seconds"
                        color: Theme.textMuted
                    }
                }

                Item { Layout.fillHeight: true }
            }

            // ── Tab 2: Integrations ──
            ColumnLayout {
                spacing: Theme.sp12
                Layout.topMargin: Theme.sp12

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
        }
    }
}
