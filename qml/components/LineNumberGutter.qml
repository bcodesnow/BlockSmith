import QtQuick
import QtQuick.Controls
import BlockSmith

Rectangle {
    id: gutter

    required property TextArea textArea
    required property var lineHeights
    required property var blockRanges
    required property FontMetrics fontMetrics
    required property real scrollY
    required property real textTopPadding

    color: Theme.bgGutter
    clip: true
    z: 2

    width: {
        let lineCount = Math.max(1, (textArea.text || "").split("\n").length)
        let digits = Math.max(3, lineCount.toString().length)
        return digits * fontMetrics.averageCharacterWidth + 20
    }

    // Current line (computed once, not per-delegate)
    readonly property int currentLine: {
        let pos = textArea.cursorPosition
        let t = textArea.text || ""
        return t.substring(0, pos).split("\n").length
    }

    function blockAtLine(lineNum) {
        let r = gutter.blockRanges
        for (let i = 0; i < r.length; i++) {
            if (lineNum >= r[i].startLine && lineNum <= r[i].endLine)
                return r[i]
        }
        return null
    }

    // Right border
    Rectangle {
        anchors.right: parent.right
        width: 1
        height: parent.height
        color: Theme.bgHeader
    }

    Column {
        y: -gutter.scrollY + gutter.textTopPadding

        Repeater {
            model: Math.max(1, (gutter.textArea.text || "").split("\n").length)

            delegate: Item {
                width: gutter.width - 4
                height: gutter.lineHeights[index] || gutter.fontMetrics.lineSpacing

                // Block region indicator strip (left edge)
                Rectangle {
                    id: blockStrip
                    width: 4
                    height: parent.height
                    anchors.left: parent.left

                    property var blockInfo: gutter.blockAtLine(index + 1)

                    color: {
                        if (!blockInfo) return "transparent"
                        if (blockInfo.status === "synced") return Theme.accentGreen
                        if (blockInfo.status === "diverged") return Theme.accentOrange
                        return Theme.accent // local
                    }

                    ToolTip.text: blockInfo
                        ? blockInfo.name + " [" + blockInfo.id + "] \u2014 " + blockInfo.status
                        : ""
                    ToolTip.visible: blockInfo ? stripMa.containsMouse : false
                    ToolTip.delay: 400

                    MouseArea {
                        id: stripMa
                        anchors.fill: parent
                        hoverEnabled: true
                    }
                }

                Label {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: index + 1
                    font: gutter.textArea.font
                    color: (index + 1) === gutter.currentLine ? Theme.textBright : Theme.textSecondary
                }
            }
        }
    }
}
