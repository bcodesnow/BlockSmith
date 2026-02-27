import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import BlockSmith

EditorPopupBase {
    id: dialog

    property string blockId: ""
    property bool isNew: blockId === ""
    property var blockData: ({})
    property var syncStatus: []

    title: isNew ? "New Block" : "Edit Block"
    metaLabel: "Tags:"
    metaPlaceholder: "comma-separated"
    deleteLabel: "Delete Block"
    saveLabel: isNew ? "Create Block" : "Save && Push to All Files"

    function openBlock(id) {
        blockId = id
        if (id === "") {
            nameText = ""
            metaText = ""
            editorText = ""
            syncStatus = []
        } else {
            blockData = AppController.blockStore.getBlock(id)
            if (!blockData.id) return
            nameText = blockData.name
            metaText = (blockData.tags || []).join(", ")
            editorText = blockData.content
            refreshSyncStatus()
        }
        resetDelete()
        dialog.open()
        focusName()
    }

    function refreshSyncStatus() {
        syncStatus = AppController.syncEngine.blockSyncStatus(blockId)
    }

    onAccepted: saveAndPush()
    onSaveRequested: saveAndPush()

    onDeleteConfirmed: {
        AppController.blockStore.removeBlock(dialog.blockId)
        dialog.close()
    }

    function saveAndPush() {
        let name = nameText.trim()
        if (name.length === 0) return

        let tags = metaText.split(",").map(s => s.trim()).filter(s => s.length > 0)

        if (isNew) {
            blockId = AppController.blockStore.createBlock(name, editorText, tags, "")
            dialog.close()
            return
        }

        if (name !== blockData.name)
            AppController.blockStore.renameBlock(blockId, name)

        // Update tags: clear and re-add
        let oldTags = blockData.tags || []
        for (let t of oldTags) AppController.blockStore.removeTag(blockId, t)
        for (let t of tags) AppController.blockStore.addTag(blockId, t)

        AppController.blockStore.updateBlock(blockId, editorText)
        AppController.syncEngine.pushBlock(blockId)

        let doc = AppController.currentDocument
        if (doc) doc.reload()
        dialog.close()
    }

    BlockDiffPopup {
        id: diffPopup
        onPulled: {
            let updated = AppController.blockStore.getBlock(dialog.blockId)
            dialog.editorText = updated.content
            dialog.refreshSyncStatus()
        }
    }

    // Sync status footer
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(syncList.contentHeight + syncHeader.height + 8, 100)
        color: Theme.bgFooter
        radius: Theme.radius
        visible: dialog.syncStatus.length > 0

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 4
            spacing: 2

            Label {
                id: syncHeader
                text: "Used in " + dialog.syncStatus.length + " file" + (dialog.syncStatus.length !== 1 ? "s" : "") + ":"
                font.pixelSize: Theme.fontSizeXS
                font.bold: true
                color: Theme.textMuted
            }

            ListView {
                id: syncList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: dialog.syncStatus
                spacing: 2

                delegate: RowLayout {
                    width: syncList.width
                    spacing: 6

                    Label {
                        text: "\u25CF"
                        font.pixelSize: 8
                        color: modelData.status === "synced" ? Theme.accentGreen : Theme.accentOrange
                    }

                    Label {
                        text: modelData.filePath
                        font.pixelSize: Theme.fontSizeS
                        color: Theme.textSecondary
                        elide: Text.ElideMiddle
                        Layout.fillWidth: true
                    }

                    Label {
                        text: modelData.status === "synced" ? "synced" : "diverged"
                        font.pixelSize: Theme.fontSizeS
                        color: modelData.status === "synced" ? Theme.accentGreen : Theme.accentOrange
                    }

                    Rectangle {
                        width: diffLabel.implicitWidth + 10
                        height: 18
                        radius: Theme.radius
                        color: diffMa.containsMouse ? Theme.bgButtonHov : Theme.bgButton
                        visible: modelData.status === "diverged"

                        Label {
                            id: diffLabel
                            anchors.centerIn: parent
                            text: "Diff & Pull"
                            font.pixelSize: Theme.fontSizeS
                            color: Theme.accent
                        }

                        MouseArea {
                            id: diffMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                diffPopup.openDiff(
                                    dialog.blockId,
                                    modelData.filePath,
                                    dialog.editorText,
                                    modelData.fileContent || "")
                            }
                        }
                    }
                }
            }
        }
    }

    Label {
        visible: !dialog.isNew && dialog.syncStatus.length === 0
        text: "Not used in any scanned files."
        font.pixelSize: Theme.fontSizeXS
        color: Theme.textMuted
    }
}
