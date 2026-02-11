import QtQuick
import QtQuick.Controls
import BlockSmith

ScrollView {
    id: previewRoot

    property string markdown: ""

    background: Rectangle {
        color: "#1e1e1e"
    }

    Flickable {
        contentWidth: previewRoot.availableWidth
        contentHeight: previewText.implicitHeight + 32

        TextEdit {
            id: previewText
            width: parent.contentWidth
            padding: 16
            readOnly: true
            textFormat: TextEdit.RichText
            wrapMode: TextEdit.Wrap
            selectByMouse: true

            text: {
                let html = AppController.md4cRenderer.render(previewRoot.markdown)
                return "<style>"
                    + "body { color: #d4d4d4; font-family: Segoe UI, sans-serif; font-size: 13px; }"
                    + "h1, h2, h3, h4 { color: #e0e0e0; margin-top: 12px; }"
                    + "code { background: #333; padding: 2px 4px; font-family: Consolas; }"
                    + "pre { background: #2a2a2a; padding: 8px; }"
                    + "a { color: #6c9bd2; }"
                    + "blockquote { border-left: 3px solid #555; padding-left: 8px; color: #aaa; }"
                    + "</style>" + html
            }

            color: "#d4d4d4"
            selectionColor: "#264f78"
            selectedTextColor: "#ffffff"
        }
    }
}
