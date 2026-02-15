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
        deleteBtn.confirming = false
        dialog.open()
        nameField.forceActiveFocus()
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
        spacing: Theme.sp8

        // Name + Category row
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.sp8

            Label { text: "Name:"; color: Theme.textSecondary; font.pixelSize: Theme.fontSizeM }
            TextField {
                id: nameField
                Layout.fillWidth: true
                font.pixelSize: Theme.fontSizeL
            }

            Label { text: "Category:"; color: Theme.textSecondary; font.pixelSize: Theme.fontSizeM }
            TextField {
                id: categoryField
                Layout.preferredWidth: 160
                font.pixelSize: Theme.fontSizeL
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
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.fontSizeL
                    wrapMode: TextArea.Wrap
                    color: Theme.textEditor
                    selectionColor: Theme.bgSelection
                    selectedTextColor: Theme.textWhite
                    placeholderText: "Enter prompt content..."
                    placeholderTextColor: Theme.textPlaceholder
                    background: Rectangle { color: Theme.bg }
                }
            }

            ScrollView {
                SplitView.preferredWidth: parent.width * 0.45
                SplitView.minimumWidth: 200

                background: Rectangle { color: Theme.bg }

                TextEdit {
                    padding: Theme.sp12
                    readOnly: true
                    textFormat: TextEdit.RichText
                    wrapMode: TextEdit.Wrap
                    color: Theme.textEditor
                    text: Theme.previewCss + AppController.md4cRenderer.render(promptEditorArea.text)
                }
            }
        }

        // Action buttons
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.sp8

            Item { Layout.fillWidth: true }

            Button {
                id: deleteBtn
                property bool confirming: false
                text: confirming ? "Confirm Delete?" : "Delete Prompt"
                flat: true
                visible: !dialog.isNew
                palette.buttonText: Theme.accentRed
                onClicked: {
                    if (!confirming) {
                        confirming = true
                        deleteResetTimer.restart()
                    } else {
                        AppController.promptStore.removePrompt(dialog.promptId)
                        dialog.close()
                    }
                }
                Timer {
                    id: deleteResetTimer
                    interval: 3000
                    onTriggered: deleteBtn.confirming = false
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
