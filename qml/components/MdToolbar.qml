import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import BlockSmith

Rectangle {
    id: toolbar
    height: 32
    color: Theme.bgHeader

    required property TextArea targetArea

    // --- Text manipulation functions ---

    function wrapSelection(prefix, suffix) {
        let start = targetArea.selectionStart
        let end = targetArea.selectionEnd

        if (start === end) {
            // No selection: insert both markers at cursor
            targetArea.insert(start, prefix + suffix)
            targetArea.cursorPosition = start + prefix.length
        } else {
            // Wrap selected text
            let sel = targetArea.selectedText
            targetArea.remove(start, end)
            targetArea.insert(start, prefix + sel + suffix)
            targetArea.select(start + prefix.length, start + prefix.length + sel.length)
        }
        targetArea.forceActiveFocus()
    }

    function insertAtCursor(text) {
        let pos = targetArea.cursorPosition
        targetArea.insert(pos, text)
        targetArea.cursorPosition = pos + text.length
        targetArea.forceActiveFocus()
    }

    function insertLinePrefix(prefix) {
        let pos = targetArea.cursorPosition
        let t = targetArea.text
        // Find start of current line
        let lineStart = pos - 1
        while (lineStart >= 0 && t[lineStart] !== '\n') lineStart--
        lineStart++

        targetArea.insert(lineStart, prefix)
        targetArea.cursorPosition = pos + prefix.length
        targetArea.forceActiveFocus()
    }

    function insertCodeBlock() {
        let start = targetArea.selectionStart
        let end = targetArea.selectionEnd

        if (start === end) {
            targetArea.insert(start, "```\n\n```")
            targetArea.cursorPosition = start + 4
        } else {
            let sel = targetArea.selectedText
            targetArea.remove(start, end)
            targetArea.insert(start, "```\n" + sel + "\n```")
            targetArea.select(start + 4, start + 4 + sel.length)
        }
        targetArea.forceActiveFocus()
    }

    function insertTable() {
        let tbl = "\n| Header | Header | Header |\n| ------ | ------ | ------ |\n| Cell   | Cell   | Cell   |\n"
        insertAtCursor(tbl)
    }

    function insertLink() {
        let start = targetArea.selectionStart
        let end = targetArea.selectionEnd

        if (start === end) {
            targetArea.insert(start, "[text](url)")
            targetArea.select(start + 1, start + 5)
        } else {
            let sel = targetArea.selectedText
            targetArea.remove(start, end)
            targetArea.insert(start, "[" + sel + "](url)")
            targetArea.select(start + sel.length + 3, start + sel.length + 6)
        }
        targetArea.forceActiveFocus()
    }

    function insertImage() {
        let start = targetArea.selectionStart
        let end = targetArea.selectionEnd

        if (start === end) {
            targetArea.insert(start, "![alt](path)")
            targetArea.select(start + 2, start + 5)
        } else {
            let sel = targetArea.selectedText
            targetArea.remove(start, end)
            targetArea.insert(start, "![" + sel + "](path)")
            targetArea.select(start + sel.length + 4, start + sel.length + 8)
        }
        targetArea.forceActiveFocus()
    }

    // Separator line
    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Theme.border
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        spacing: 2

        // --- Headers ---
        ToolbarButton { label: "H1"; tooltip: "Heading 1"; onClicked: insertLinePrefix("# ") }
        ToolbarButton { label: "H2"; tooltip: "Heading 2"; onClicked: insertLinePrefix("## ") }
        ToolbarButton { label: "H3"; tooltip: "Heading 3"; onClicked: insertLinePrefix("### ") }

        ToolbarSep {}

        // --- Inline ---
        ToolbarButton { label: "B"; bold: true; tooltip: "Bold (Ctrl+B)"; onClicked: wrapSelection("**", "**") }
        ToolbarButton { label: "I"; italic: true; tooltip: "Italic (Ctrl+I)"; onClicked: wrapSelection("*", "*") }
        ToolbarButton { label: "S"; strikethrough: true; tooltip: "Strikethrough"; onClicked: wrapSelection("~~", "~~") }

        ToolbarSep {}

        // --- Code ---
        ToolbarButton { label: "`"; tooltip: "Inline code (Ctrl+Shift+K)"; onClicked: wrapSelection("`", "`") }
        ToolbarButton { label: "{ }"; tooltip: "Code block"; onClicked: insertCodeBlock() }

        ToolbarSep {}

        // --- Lists ---
        ToolbarButton { label: "\u2022"; tooltip: "Bullet list"; onClicked: insertLinePrefix("- ") }
        ToolbarButton { label: "1."; tooltip: "Numbered list"; onClicked: insertLinePrefix("1. ") }
        ToolbarButton { label: "\u2610"; tooltip: "Task list"; onClicked: insertLinePrefix("- [ ] ") }

        ToolbarSep {}

        // --- Insert ---
        ToolbarButton { label: "\u2015"; tooltip: "Horizontal rule"; onClicked: insertAtCursor("\n---\n") }
        ToolbarButton { label: ">"; tooltip: "Blockquote"; onClicked: insertLinePrefix("> ") }
        ToolbarButton { label: "\u26D3"; tooltip: "Link"; onClicked: insertLink() }
        ToolbarButton { label: "\u25A3"; tooltip: "Image"; onClicked: insertImage() }
        ToolbarButton { label: "\u2637"; tooltip: "Table"; onClicked: insertTable() }

        Item { Layout.fillWidth: true }
    }

    // --- Inline components ---

    component ToolbarButton: Rectangle {
        property string label: ""
        property string tooltip: ""
        property bool bold: false
        property bool italic: false
        property bool strikethrough: false
        signal clicked()

        Layout.preferredWidth: Math.max(26, btnLabel.implicitWidth + 10)
        Layout.preferredHeight: 24
        radius: Theme.radius
        color: btnMa.containsMouse ? Theme.bgButtonHov : "transparent"

        ToolTip.text: tooltip
        ToolTip.visible: btnMa.containsMouse && tooltip.length > 0
        ToolTip.delay: 400

        Label {
            id: btnLabel
            anchors.centerIn: parent
            text: parent.label
            font.pixelSize: Theme.fontSizeXS
            font.bold: parent.bold
            font.italic: parent.italic
            font.strikeout: parent.strikethrough
            color: Theme.textPrimary
        }

        MouseArea {
            id: btnMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }

    component ToolbarSep: Rectangle {
        Layout.preferredWidth: 1
        Layout.preferredHeight: 18
        Layout.alignment: Qt.AlignVCenter
        color: Theme.border
    }
}
