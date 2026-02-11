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
        spacing: 8

        // Side-by-side diff with headers
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8

            // Registry side
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 4

                Label {
                    text: "Registry (BlockStore)"
                    font.pixelSize: 12
                    font.bold: true
                    color: "#6c9bd2"
                    Layout.alignment: Qt.AlignHCenter
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "#1a2530"
                    radius: 4
                    border.color: "#3d5a80"
                    border.width: 1

                    ScrollView {
                        anchors.fill: parent
                        anchors.margins: 1

                        TextArea {
                            readOnly: true
                            text: diffDialog.registryContent
                            font.family: "Consolas"
                            font.pixelSize: 12
                            color: "#d4d4d4"
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
                    font.pixelSize: 12
                    font.bold: true
                    color: "#ff9800"
                    Layout.alignment: Qt.AlignHCenter
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "#2a2010"
                    radius: 4
                    border.color: "#806020"
                    border.width: 1

                    ScrollView {
                        anchors.fill: parent
                        anchors.margins: 1

                        TextArea {
                            readOnly: true
                            text: diffDialog.fileContent
                            font.family: "Consolas"
                            font.pixelSize: 12
                            color: "#d4d4d4"
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
            spacing: 8

            Label {
                text: "Pull will overwrite the registry block with the file's version."
                font.pixelSize: 11
                color: "#888"
                Layout.fillWidth: true
            }

            Button {
                text: "Close"
                flat: true
                palette.buttonText: "#ccc"
                onClicked: diffDialog.close()
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
