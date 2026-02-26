import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import BlockSmith

Dialog {
    id: diffDialog

    parent: Overlay.overlay
    anchors.centerIn: parent
    width: Math.min(parent.width * 0.85, 1200)
    height: Math.min(parent.height * 0.8, 650)

    modal: true
    title: "Block Diff — " + diffDialog.filePath
    standardButtons: Dialog.Cancel

    property string blockId: ""
    property string filePath: ""
    property string registryContent: ""
    property string fileContent: ""
    property var diffLines: []
    property bool loadingDiff: false
    property string diffRequestId: ""

    // Build per-side models from flat diff list
    property var leftLines: []   // registry: context + removed, blank for added
    property var rightLines: []  // file: context + added, blank for removed

    signal pulled()

    function buildSideModels(lines) {
        var left = [], right = []
        for (var i = 0; i < lines.length; i++) {
            var d = lines[i]
            if (d.type === "context") {
                left.push({ text: d.text, type: "context", lineNum: d.lineA })
                right.push({ text: d.text, type: "context", lineNum: d.lineB })
            } else if (d.type === "removed") {
                left.push({ text: d.text, type: "removed", lineNum: d.lineA })
                right.push({ text: "", type: "blank", lineNum: -1 })
            } else if (d.type === "added") {
                left.push({ text: "", type: "blank", lineNum: -1 })
                right.push({ text: d.text, type: "added", lineNum: d.lineB })
            }
        }
        leftLines = left
        rightLines = right
    }

    function openDiff(blockId, filePath, registryContent, fileContent) {
        diffDialog.blockId = blockId
        diffDialog.filePath = filePath
        diffDialog.registryContent = registryContent
        diffDialog.fileContent = fileContent
        diffDialog.diffLines = []
        diffDialog.leftLines = []
        diffDialog.rightLines = []
        diffDialog.loadingDiff = true
        diffDialog.diffRequestId = Date.now().toString() + "-" + Math.random().toString(36).slice(2, 8)

        AppController.syncEngine.computeLineDiffAsync(diffDialog.diffRequestId, registryContent, fileContent)

        diffDialog.open()
    }

    Connections {
        target: AppController.syncEngine
        function onLineDiffReady(requestId, diff) {
            if (requestId !== diffDialog.diffRequestId)
                return
            diffDialog.diffLines = diff
            diffDialog.buildSideModels(diff)
            diffDialog.loadingDiff = false
        }
    }

    readonly property int lineHeight: Theme.fontSizeM + 6
    readonly property int gutterWidth: 36

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.sp8

        // Headers
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 20

            Label {
                anchors.left: parent.left
                width: (parent.width - Theme.sp8) / 2
                text: "Registry (BlockStore)"
                font.pixelSize: Theme.fontSizeM
                font.bold: true
                color: Theme.accent
                horizontalAlignment: Text.AlignHCenter
            }

            Label {
                anchors.right: parent.right
                width: (parent.width - Theme.sp8) / 2
                text: "File Content"
                font.pixelSize: Theme.fontSizeM
                font.bold: true
                color: Theme.accentOrange
                horizontalAlignment: Text.AlignHCenter
            }
        }

        // Side-by-side diff panes
        Item {
            id: diffRow
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Left pane (registry)
            Rectangle {
                id: leftPane
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: (parent.width - Theme.sp8) / 2
                color: Theme.diffRegistryBg
                radius: 4
                border.color: Theme.diffRegistryBorder
                border.width: 1
                clip: true

                ListView {
                    id: leftList
                    anchors.fill: parent
                    anchors.margins: 1
                    model: diffDialog.leftLines
                    boundsBehavior: Flickable.StopAtBounds
                    clip: true

                    onContentYChanged: {
                        if (!rightList.moving && !rightList.dragging)
                            rightList.contentY = contentY
                    }

                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: leftList.width
                        height: diffDialog.lineHeight
                        color: modelData.type === "removed" ? Theme.diffRemovedBg
                             : modelData.type === "blank"   ? "transparent"
                             : "transparent"

                        // Line number gutter
                        Rectangle {
                            width: diffDialog.gutterWidth
                            height: parent.height
                            color: Qt.darker(parent.color, 1.15)
                            visible: modelData.type !== "blank"

                            Text {
                                anchors.right: parent.right
                                anchors.rightMargin: 4
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.lineNum > 0 ? modelData.lineNum : ""
                                font.family: Theme.fontMono
                                font.pixelSize: Theme.fontSizeS
                                color: Theme.textMuted
                            }
                        }

                        // Diff marker
                        Text {
                            x: diffDialog.gutterWidth + 2
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.type === "removed" ? "−" : " "
                            font.family: Theme.fontMono
                            font.pixelSize: Theme.fontSizeM
                            color: modelData.type === "removed" ? Theme.accentRed : Theme.textMuted
                        }

                        // Line text
                        Text {
                            x: diffDialog.gutterWidth + 16
                            width: parent.width - x - 4
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.text
                            font.family: Theme.fontMono
                            font.pixelSize: Theme.fontSizeM
                            color: Theme.textEditor
                            elide: Text.ElideRight
                        }

                        // Separator
                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: 1
                            color: Theme.border
                            opacity: 0.15
                        }
                    }

                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                }
            }

            // Right pane (file)
            Rectangle {
                id: rightPane
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: (parent.width - Theme.sp8) / 2
                color: Theme.diffFileBg
                radius: 4
                border.color: Theme.diffFileBorder
                border.width: 1
                clip: true

                ListView {
                    id: rightList
                    anchors.fill: parent
                    anchors.margins: 1
                    model: diffDialog.rightLines
                    boundsBehavior: Flickable.StopAtBounds
                    clip: true

                    onContentYChanged: {
                        if (!leftList.moving && !leftList.dragging)
                            leftList.contentY = contentY
                    }

                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: rightList.width
                        height: diffDialog.lineHeight
                        color: modelData.type === "added" ? Theme.diffAddedBg
                             : modelData.type === "blank" ? "transparent"
                             : "transparent"

                        // Line number gutter
                        Rectangle {
                            width: diffDialog.gutterWidth
                            height: parent.height
                            color: Qt.darker(parent.color, 1.15)
                            visible: modelData.type !== "blank"

                            Text {
                                anchors.right: parent.right
                                anchors.rightMargin: 4
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.lineNum > 0 ? modelData.lineNum : ""
                                font.family: Theme.fontMono
                                font.pixelSize: Theme.fontSizeS
                                color: Theme.textMuted
                            }
                        }

                        // Diff marker
                        Text {
                            x: diffDialog.gutterWidth + 2
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.type === "added" ? "+" : " "
                            font.family: Theme.fontMono
                            font.pixelSize: Theme.fontSizeM
                            color: modelData.type === "added" ? Theme.accentGreen : Theme.textMuted
                        }

                        // Line text
                        Text {
                            x: diffDialog.gutterWidth + 16
                            width: parent.width - x - 4
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.text
                            font.family: Theme.fontMono
                            font.pixelSize: Theme.fontSizeM
                            color: Theme.textEditor
                            elide: Text.ElideRight
                        }

                        // Separator
                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: 1
                            color: Theme.border
                            opacity: 0.15
                        }
                    }

                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                }
            }

            Rectangle {
                anchors.fill: parent
                visible: diffDialog.loadingDiff
                color: Qt.rgba(0, 0, 0, 0.2)

                Column {
                    anchors.centerIn: parent
                    spacing: Theme.sp8

                    BusyIndicator {
                        running: diffDialog.loadingDiff
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Label {
                        text: "Computing diff..."
                        color: Theme.textPrimary
                        font.pixelSize: Theme.fontSizeM
                        anchors.horizontalCenter: parent.horizontalCenter
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
                enabled: !diffDialog.loadingDiff
                onClicked: {
                    AppController.syncEngine.pullBlock(diffDialog.blockId, diffDialog.filePath)
                    diffDialog.pulled()
                    diffDialog.close()
                }
            }
        }
    }
}
