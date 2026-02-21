import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import BlockSmith

Dialog {
    id: diffDialog

    parent: Overlay.overlay
    anchors.centerIn: parent
    width: Math.min(parent.width * 0.85, 1000)
    height: Math.min(parent.height * 0.7, 550)

    modal: true
    title: "Block Diff — " + diffDialog.filePath
    standardButtons: Dialog.Cancel

    property string blockId: ""
    property string filePath: ""
    property string registryContent: ""
    property string fileContent: ""

    signal pulled()

    function openDiff(blockId, filePath, registryContent, fileContent) {
        diffDialog.blockId = blockId
        diffDialog.filePath = filePath
        diffDialog.registryContent = registryContent
        diffDialog.fileContent = fileContent
        diffDialog.open()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.sp8

        // Side-by-side diff with headers
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Theme.sp8

            // Registry side
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 4

                Label {
                    text: "Registry (BlockStore)"
                    font.pixelSize: Theme.fontSizeM
                    font.bold: true
                    color: Theme.accent
                    Layout.alignment: Qt.AlignHCenter
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Theme.diffRegistryBg
                    radius: 4
                    border.color: Theme.diffRegistryBorder
                    border.width: 1

                    ScrollView {
                        anchors.fill: parent
                        anchors.margins: 1

                        TextArea {
                            readOnly: true
                            text: diffDialog.registryContent
                            font.family: Theme.fontMono
                            font.pixelSize: Theme.fontSizeM
                            color: Theme.textEditor
                            wrapMode: TextArea.Wrap
                            background: null
                        }
                    }
                }
            }

            // File side
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 4

                Label {
                    text: "File Content"
                    font.pixelSize: Theme.fontSizeM
                    font.bold: true
                    color: Theme.accentOrange
                    Layout.alignment: Qt.AlignHCenter
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Theme.diffFileBg
                    radius: 4
                    border.color: Theme.diffFileBorder
                    border.width: 1

                    ScrollView {
                        anchors.fill: parent
                        anchors.margins: 1

                        TextArea {
                            readOnly: true
                            text: diffDialog.fileContent
                            font.family: Theme.fontMono
                            font.pixelSize: Theme.fontSizeM
                            color: Theme.textEditor
                            wrapMode: TextArea.Wrap
                            background: null
                        }
                    }
                }
            }
        }

        // Action buttons
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.sp8

            Label {
                text: "Pull will overwrite the registry block with the file's version."
                font.pixelSize: Theme.fontSizeXS
                color: Theme.textMuted
                Layout.fillWidth: true
            }

            Button {
                text: "Pull from File"
                highlighted: true
                onClicked: {
                    AppController.syncEngine.pullBlock(diffDialog.blockId, diffDialog.filePath)
                    diffDialog.pulled()
                    diffDialog.close()
                }
            }
        }
    }
}
