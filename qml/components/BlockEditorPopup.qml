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
    title: "Edit Block"
    standardButtons: Dialog.Cancel

    property string blockId: ""
    property var blockData: ({})
    property var syncStatus: []

    function openBlock(id) {
        blockId = id
        blockData = AppController.blockStore.getBlock(id)
        if (!blockData.id) return

        nameField.text = blockData.name
        tagsField.text = (blockData.tags || []).join(", ")
        editorArea.text = blockData.content
        refreshSyncStatus()
        dialog.open()
    }

    function refreshSyncStatus() {
        syncStatus = AppController.syncEngine.blockSyncStatus(blockId)
    }

    onAccepted: saveAndPush()

    function saveAndPush() {
        let name = nameField.text.trim()
        if (name !== blockData.name && name.length > 0)
            AppController.blockStore.renameBlock(blockId, name)

        let tags = tagsField.text.split(",").map(s => s.trim()).filter(s => s.length > 0)
        // Update tags: clear and re-add
        let oldTags = blockData.tags || []
        for (let t of oldTags) AppController.blockStore.removeTag(blockId, t)
        for (let t of tags) AppController.blockStore.addTag(blockId, t)

        AppController.blockStore.updateBlock(blockId, editorArea.text)
        let count = AppController.syncEngine.pushBlock(blockId)

        // Reload current doc if it was affected
        AppController.currentDocument.reload()
        dialog.close()
    }

    BlockDiffPopup {
        id: diffPopup
        onPulled: {
            let updated = AppController.blockStore.getBlock(dialog.blockId)
            editorArea.text = updated.content
            dialog.refreshSyncStatus()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        // Name + Tags row
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Label { text: "Name:"; color: "#999"; font.pixelSize: 12 }
            TextField {
                id: nameField
                Layout.fillWidth: true
                font.pixelSize: 13
            }

            Label { text: "Tags:"; color: "#999"; font.pixelSize: 12 }
            TextField {
                id: tagsField
                Layout.preferredWidth: 200
                font.pixelSize: 13
                placeholderText: "comma-separated"
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
                    id: editorArea
                    font.family: "Consolas"
                    font.pixelSize: 13
                    wrapMode: TextArea.Wrap
                    color: "#d4d4d4"
                    selectionColor: "#264f78"
                    selectedTextColor: "#fff"
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
                        let html = AppController.md4cRenderer.render(editorArea.text)
                        return "<style>h1,h2,h3{color:#e0e0e0;}code{background:#333;font-family:Consolas;}a{color:#6c9bd2;}</style>" + html
                    }
                }
            }
        }

        // Used-in footer with sync status
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(syncList.contentHeight + syncHeader.height + 8, 100)
            color: "#252525"
            radius: 3
            visible: dialog.syncStatus.length > 0

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 4
                spacing: 2

                Label {
                    id: syncHeader
                    text: "Used in " + dialog.syncStatus.length + " file" + (dialog.syncStatus.length !== 1 ? "s" : "") + ":"
                    font.pixelSize: 11
                    font.bold: true
                    color: "#888"
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

                        // Sync status dot
                        Label {
                            text: "\u25CF"
                            font.pixelSize: 8
                            color: modelData.status === "synced" ? "#4caf50" : "#ff9800"
                        }

                        Label {
                            text: modelData.filePath
                            font.pixelSize: 10
                            color: "#aaa"
                            elide: Text.ElideMiddle
                            Layout.fillWidth: true
                        }

                        Label {
                            text: modelData.status === "synced" ? "synced" : "diverged"
                            font.pixelSize: 10
                            color: modelData.status === "synced" ? "#4caf50" : "#ff9800"
                        }

                        // Diff button for diverged files
                        Rectangle {
                            width: diffLabel.implicitWidth + 10
                            height: 18
                            radius: 3
                            color: diffMa.containsMouse ? "#555" : "#3a3a3a"
                            visible: modelData.status === "diverged"

                            Label {
                                id: diffLabel
                                anchors.centerIn: parent
                                text: "Diff & Pull"
                                font.pixelSize: 10
                                color: "#6c9bd2"
                            }

                            MouseArea {
                                id: diffMa
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    diffPopup.openDiff(
                                        dialog.blockId,
                                        modelData.filePath,
                                        editorArea.text,
                                        modelData.fileContent || "")
                                }
                            }
                        }
                    }
                }
            }
        }

        Label {
            visible: dialog.syncStatus.length === 0
            text: "Not used in any scanned files."
            font.pixelSize: 11
            color: "#666"
        }

        // Action buttons
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Item { Layout.fillWidth: true }

            Button {
                text: "Delete Block"
                flat: true
                palette.buttonText: "#e06060"
                onClicked: {
                    AppController.blockStore.removeBlock(dialog.blockId)
                    dialog.close()
                }
            }

            Button {
                text: "Save && Push to All Files"
                highlighted: true
                onClicked: dialog.saveAndPush()
            }
        }
    }
}
