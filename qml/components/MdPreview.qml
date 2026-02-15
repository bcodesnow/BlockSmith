import QtQuick
import QtQuick.Controls
import BlockSmith

ScrollView {
    id: previewRoot

    property string markdown: ""
    readonly property Flickable scrollFlickable: previewFlickable

    background: Rectangle {
        color: Theme.bg
    }

    Flickable {
        id: previewFlickable
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

            text: Theme.previewCss + AppController.md4cRenderer.render(previewRoot.markdown)

            color: Theme.textEditor
            selectionColor: Theme.bgSelection
            selectedTextColor: Theme.textWhite
        }
    }
}
