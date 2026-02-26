import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import BlockSmith

ColumnLayout {
    spacing: Theme.sp12

    function loadFromConfig() {
        themeCombo.currentIndex = AppController.configManager.themeMode === "light" ? 1 : 0
        fontCombo.currentIndex = Math.max(0, fontCombo.model.indexOf(AppController.configManager.editorFontFamily))
        syntaxHighlightCheck.checked = AppController.configManager.syntaxHighlightEnabled
        wordWrapCheck.checked = AppController.configManager.wordWrap
        imageSubfolderField.text = AppController.configManager.imageSubfolder
        sbWordCountCheck.checked = AppController.configManager.statusBarWordCount
        sbCharCountCheck.checked = AppController.configManager.statusBarCharCount
        sbLineCountCheck.checked = AppController.configManager.statusBarLineCount
        sbReadingTimeCheck.checked = AppController.configManager.statusBarReadingTime
        autoSaveCheck.checked = AppController.configManager.autoSaveEnabled
        autoSaveIntervalSpin.value = AppController.configManager.autoSaveInterval
    }

    function saveToConfig() {
        AppController.configManager.themeMode = themeCombo.currentIndex === 1 ? "light" : "dark"
        AppController.configManager.editorFontFamily = fontCombo.currentText
        AppController.configManager.syntaxHighlightEnabled = syntaxHighlightCheck.checked
        AppController.configManager.wordWrap = wordWrapCheck.checked
        AppController.configManager.imageSubfolder = imageSubfolderField.text.trim() || "images"
        AppController.configManager.statusBarWordCount = sbWordCountCheck.checked
        AppController.configManager.statusBarCharCount = sbCharCountCheck.checked
        AppController.configManager.statusBarLineCount = sbLineCountCheck.checked
        AppController.configManager.statusBarReadingTime = sbReadingTimeCheck.checked
        AppController.configManager.autoSaveEnabled = autoSaveCheck.checked
        AppController.configManager.autoSaveInterval = autoSaveIntervalSpin.value
    }

    Label {
        text: "Appearance"
        font.bold: true
        color: Theme.textPrimary
    }

    RowLayout {
        spacing: Theme.sp8

        Label { text: "Theme:" }

        ComboBox {
            id: themeCombo
            model: ["Dark", "Light"]
            Layout.preferredWidth: 120
        }
    }

    RowLayout {
        spacing: Theme.sp8

        Label { text: "Editor font:" }

        ComboBox {
            id: fontCombo
            model: ["Consolas", "Cascadia Code", "Cascadia Mono",
                    "JetBrains Mono", "Fira Code", "Source Code Pro",
                    "Courier New"]
            Layout.preferredWidth: 180
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: Theme.border
    }

    CheckBox {
        id: syntaxHighlightCheck
        text: "Syntax highlighting in editor"
        checked: true
    }

    CheckBox {
        id: wordWrapCheck
        text: "Word wrap"
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
