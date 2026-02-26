import QtQuick
import QtQuick.Controls

Menu {
    id: contextMenu

    required property var textArea

    signal addBlockRequested(string selectedText, int selStart, int selEnd)
    signal createPromptRequested(string selectedText)

    MenuItem {
        text: "Cut"
        enabled: contextMenu.textArea.selectedText.length > 0
        onTriggered: contextMenu.textArea.cut()
    }
    MenuItem {
        text: "Copy"
        enabled: contextMenu.textArea.selectedText.length > 0
        onTriggered: contextMenu.textArea.copy()
    }
    MenuItem {
        text: "Paste"
        onTriggered: contextMenu.textArea.paste()
    }
    MenuItem {
        text: "Select All"
        onTriggered: contextMenu.textArea.selectAll()
    }

    MenuSeparator {}

    MenuItem {
        text: "Add as Block"
        enabled: contextMenu.textArea.selectedText.length > 0
        onTriggered: {
            contextMenu.addBlockRequested(
                contextMenu.textArea.selectedText,
                contextMenu.textArea.selectionStart,
                contextMenu.textArea.selectionEnd)
        }
    }
    MenuItem {
        text: "Create Prompt from Selection"
        enabled: contextMenu.textArea.selectedText.length > 0
        onTriggered: {
            contextMenu.createPromptRequested(contextMenu.textArea.selectedText)
        }
    }
}
