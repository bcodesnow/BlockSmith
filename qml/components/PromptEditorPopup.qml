import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import BlockSmith

Dialog {
    id: dialog

    parent: Overlay.overlay
    anchors.centerIn: parent
    width: Math.min(parent.width * 0.8, 900)
    height: Math.min(parent.height * 0.8, 650)

    modal: true
    title: isNew ? "New Prompt" : "Edit Prompt"
    standardButtons: Dialog.Cancel

    property string promptId: ""
    property bool isNew: promptId === ""
    property var promptData: ({})

    function openNewWithContent(content) {
        promptId = ""
        nameField.text = ""
        categoryField.text = ""
        promptEditorArea.text = content
        dialog.open()
    }

    function openPrompt(id) {
        promptId = id
        if (id === "") {
            // New prompt
            nameField.text = ""
            categoryField.text = ""
            promptEditorArea.text = ""
        } else {
            promptData = AppController.promptStore.getPrompt(id)
            if (!promptData.id) return
            nameField.text = promptData.name
            categoryField.text = promptData.category || ""
            promptEditorArea.text = promptData.content
        }
        dialog.open()
    }

    function savePrompt() {
        let name = nameField.text.trim()
        if (name.length === 0) return

        let content = promptEditorArea.text
        let category = categoryField.text.trim()

        if (isNew) {
            AppController.promptStore.createPrompt(name, content, category)
        } else {
            AppController.promptStore.updatePrompt(promptId, name, content, category)
        }

        dialog.close()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        // Name + Category row
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Label { text: "Name:"; color: "#999"; font.pixelSize: 12 }
            TextField {
                id: nameField
                Layout.fillWidth: true
                font.pixelSize: 13
            }

            Label { text: "Category:"; color: "#999"; font.pixelSize: 12 }
            TextField {
                id: categoryField
                Layout.preferredWidth: 160
                font.pixelSize: 13
                placeholderText: "e.g. audit, review"
            }
        }

        // Split editor / preview
        SplitView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            orientation: Qt.Horizontal

            ScrollView {
                SplitView.fillWidth: true
                SplitView.minimumWidth: 200

                TextArea {
                    id: promptEditorArea
                    font.family: "Consolas"
                    font.pixelSize: 13
                    wrapMode: TextArea.Wrap
                    color: "#d4d4d4"
                    selectionColor: "#264f78"
                    selectedTextColor: "#fff"
                    placeholderText: "Enter prompt content..."
                    placeholderTextColor: "#666"
                    background: Rectangle { color: "#1e1e1e" }
                }
            }

            ScrollView {
                SplitView.preferredWidth: parent.width * 0.45
                SplitView.minimumWidth: 200

                background: Rectangle { color: "#1e1e1e" }

                TextEdit {
                    padding: 12
                    readOnly: true
                    textFormat: TextEdit.RichText
                    wrapMode: TextEdit.Wrap
                    color: "#d4d4d4"
                    text: {
                        let html = AppController.md4cRenderer.render(promptEditorArea.text)
                        return "<style>h1,h2,h3{color:#e0e0e0;}code{background:#333;font-family:Consolas;}a{color:#6c9bd2;}</style>" + html
                    }
                }
            }
        }

        // Action buttons
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Item { Layout.fillWidth: true }

            Button {
                text: "Delete Prompt"
                flat: true
                visible: !dialog.isNew
                palette.buttonText: "#e06060"
                onClicked: {
                    AppController.promptStore.removePrompt(dialog.promptId)
                    dialog.close()
                }
            }

            Button {
                text: dialog.isNew ? "Create Prompt" : "Save Prompt"
                highlighted: true
                onClicked: dialog.savePrompt()
            }
        }
    }
}
