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
        projectsTab.loadFromConfig()
        editorTab.loadFromConfig()
        integrationsTab.loadFromConfig()
    }

    onAccepted: {
        projectsTab.saveToConfig()
        editorTab.saveToConfig()
        integrationsTab.saveToConfig()
        AppController.configManager.save()

        // Auto-rescan if scan-relevant settings changed
        if (projectsTab.searchPathsText !== _prevPaths
            || projectsTab.ignorePatternsText !== _prevPatterns
            || projectsTab.triggerFilesText !== _prevTriggers
            || projectsTab.scanDepthValue !== _prevDepth
            || integrationsTab.claudeCodeChecked !== _prevClaudeFolder) {
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
            Layout.topMargin: Theme.sp12
            currentIndex: tabBar.currentIndex

            SettingsProjectsTab {
                id: projectsTab
            }

            SettingsEditorTab {
                id: editorTab
            }

            SettingsIntegrationsTab {
                id: integrationsTab
            }
        }
    }
}
