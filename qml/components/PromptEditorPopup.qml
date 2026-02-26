import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import BlockSmith

EditorPopupBase {
    id: dialog

    property string promptId: ""
    property bool isNew: promptId === ""
    property var promptData: ({})

    title: isNew ? "New Prompt" : "Edit Prompt"
    metaLabel: "Category:"
    metaPlaceholder: "e.g. audit, review"
    deleteLabel: "Delete Prompt"
    saveLabel: isNew ? "Create Prompt" : "Save Prompt"

    function openNewWithContent(content) {
        promptId = ""
        nameText = ""
        metaText = ""
        editorText = content
        dialog.open()
    }

    function openPrompt(id) {
        promptId = id
        if (id === "") {
            nameText = ""
            metaText = ""
            editorText = ""
        } else {
            promptData = AppController.promptStore.getPrompt(id)
            if (!promptData.id) return
            nameText = promptData.name
            metaText = promptData.category || ""
            editorText = promptData.content
        }
        resetDelete()
        dialog.open()
        focusName()
    }

    onSaveRequested: savePrompt()

    onDeleteConfirmed: {
        AppController.promptStore.removePrompt(dialog.promptId)
        dialog.close()
    }

    function savePrompt() {
        let name = nameText.trim()
        if (name.length === 0) return

        let content = editorText
        let category = metaText.trim()

        if (isNew) {
            AppController.promptStore.createPrompt(name, content, category)
        } else {
            AppController.promptStore.updatePrompt(promptId, name, content, category)
        }

        dialog.close()
    }
}
