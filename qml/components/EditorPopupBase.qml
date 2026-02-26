import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import BlockSmith

Dialog {
    id: popup

    parent: Overlay.overlay
    anchors.centerIn: parent
    width: Math.min(parent.width * 0.8, 900)
    height: Math.min(parent.height * 0.8, 650)

    modal: true
    standardButtons: Dialog.Cancel

    property bool isNew: false
    property string metaLabel: "Tags:"
    property string metaPlaceholder: "comma-separated"
    property string deleteLabel: "Delete"
    property string saveLabel: "Save"

    property alias nameText: nameField.text
    property alias metaText: metaField.text
    property alias editorText: editorArea.text

    // Extra content inserted between the editor and action buttons (e.g. sync status)
    default property alias extraContent: extraSlot.data

    signal saveRequested()
    signal deleteConfirmed()

    function focusName() {
        nameField.forceActiveFocus()
    }

    // Reset delete confirmation state
    function resetDelete() {
        deleteBtn.confirming = false
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.sp8

        // Name + meta row
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.sp8

            Label { text: "Name:"; color: Theme.textSecondary; font.pixelSize: Theme.fontSizeM }
            TextField {
                id: nameField
                Layout.fillWidth: true
                font.pixelSize: Theme.fontSizeL
            }

            Label { text: popup.metaLabel; color: Theme.textSecondary; font.pixelSize: Theme.fontSizeM }
            TextField {
                id: metaField
                Layout.preferredWidth: 200
                font.pixelSize: Theme.fontSizeL
                placeholderText: popup.metaPlaceholder
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
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.fontSizeL
                    wrapMode: TextArea.Wrap
                    color: Theme.textEditor
                    selectionColor: Theme.bgSelection
                    selectedTextColor: Theme.textWhite
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
                    text: Theme.previewCss + AppController.md4cRenderer.render(editorArea.text)
                }
            }
        }

        // Slot for extra content (sync status footer, etc.)
        ColumnLayout {
            id: extraSlot
            Layout.fillWidth: true
            spacing: Theme.sp8
        }

        // Action buttons
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.sp8

            Item { Layout.fillWidth: true }

            Button {
                id: deleteBtn
                property bool confirming: false
                text: confirming ? "Confirm Delete?" : popup.deleteLabel
                flat: true
                visible: !popup.isNew
                palette.buttonText: Theme.accentRed
                onClicked: {
                    if (!confirming) {
                        confirming = true
                        deleteResetTimer.restart()
                    } else {
                        popup.deleteConfirmed()
                    }
                }
                Timer {
                    id: deleteResetTimer
                    interval: 3000
                    onTriggered: deleteBtn.confirming = false
                }
            }

            Button {
                text: popup.saveLabel
                highlighted: true
                onClicked: popup.saveRequested()
            }
        }
    }
}
