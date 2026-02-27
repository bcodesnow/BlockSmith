import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import BlockSmith

Rectangle {
    id: outlinePanel
    color: Theme.bgPanel

    signal headingClicked(int lineNumber)

    property var headings: []
    property int cursorLine: 0

    readonly property int activeHeadingIndex: {
        let idx = -1
        for (let i = 0; i < headings.length; i++) {
            if (headings[i].line <= cursorLine) idx = i
            else break
        }
        return idx
    }

    function parseHeadings() {
        let doc = AppController.currentDocument
        let content = doc ? doc.rawContent : ""
        if (!content || content.length === 0) {
            headings = []
            return
        }

        let lines = content.split("\n")
        let result = []
        let inCodeBlock = false
        for (let i = 0; i < lines.length; i++) {
            let line = lines[i]
            // Skip headings inside fenced code blocks
            if (line.match(/^```/)) {
                inCodeBlock = !inCodeBlock
                continue
            }
            if (inCodeBlock) continue

            let m = line.match(/^(#{1,6})\s+(.+)/)
            if (m) {
                result.push({
                    level: m[1].length,
                    text: m[2].replace(/\s*#+\s*$/, '').trim(),  // strip trailing #
                    line: i + 1
                })
            }
        }
        headings = result
    }

    Timer {
        id: parseTimer
        interval: 300
        onTriggered: outlinePanel.parseHeadings()
    }

    // Dynamic document signal connections
    property var _oldDoc: null
    property var _connFuncs: []
    function reconnectDocSignals() {
        if (_oldDoc) {
            for (let entry of _connFuncs)
                _oldDoc[entry.sig].disconnect(entry.fn)
        }
        _connFuncs = []
        let doc = AppController.currentDocument
        _oldDoc = doc
        if (!doc) return
        let f1 = function() { parseTimer.restart() }
        let f2 = function() { outlinePanel.parseHeadings() }
        doc.rawContentChanged.connect(f1)
        doc.filePathChanged.connect(f2)
        _connFuncs.push({ sig: "rawContentChanged", fn: f1 })
        _connFuncs.push({ sig: "filePathChanged", fn: f2 })
    }
    Connections {
        target: AppController
        function onCurrentDocumentChanged() {
            outlinePanel.reconnectDocSignals()
            outlinePanel.parseHeadings()
        }
    }
    Component.onCompleted: reconnectDocSignals()

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.headerHeight
            color: Theme.bgHeader

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10

                Label {
                    text: "OUTLINE"
                    font.pixelSize: Theme.fontSizeXS
                    font.bold: true
                    font.letterSpacing: 1.2
                    color: Theme.textSecondary
                }

                Item { Layout.fillWidth: true }

                Label {
                    text: outlinePanel.headings.length
                    font.pixelSize: Theme.fontSizeXS
                    color: Theme.textMuted
                    visible: outlinePanel.headings.length > 0
                }
            }
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.border
        }

        // Heading list
        ListView {
            id: headingList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 0
            model: outlinePanel.headings

            delegate: Rectangle {
                width: ListView.view.width
                height: 28
                color: index === outlinePanel.activeHeadingIndex
                       ? Theme.highlightItemBg
                       : (headingMa.containsMouse ? Theme.bgCardHov : "transparent")

                MouseArea {
                    id: headingMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: outlinePanel.headingClicked(modelData.line)
                }

                // Active heading accent bar
                Rectangle {
                    visible: index === outlinePanel.activeHeadingIndex
                    width: 3
                    height: parent.height
                    color: Theme.accent
                }

                Label {
                    anchors.left: parent.left
                    anchors.leftMargin: 10 + (modelData.level - 1) * 14
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.text
                    font.pixelSize: modelData.level <= 2 ? Theme.fontSizeL : Theme.fontSizeM
                    font.bold: modelData.level <= 2
                    color: index === outlinePanel.activeHeadingIndex
                           ? Theme.textPrimary : Theme.textSecondary
                    elide: Text.ElideRight
                }
            }

            // Empty state
            Label {
                anchors.centerIn: parent
                visible: headingList.count === 0
                text: {
                    let doc = AppController.currentDocument
                    return (!doc || doc.filePath === "")
                          ? "Open a file to see\nits outline."
                          : "No headings found."
                }
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Theme.fontSizeXS
                color: Theme.textMuted
            }
        }
    }
}
