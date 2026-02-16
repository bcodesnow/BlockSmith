import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import BlockSmith

Rectangle {
    id: card

    required property int index
    required property int lineNumber
    required property string preview
    required property string roleName
    required property bool hasToolUse
    required property string fullJson
    required property bool isExpanded

    implicitHeight: cardCol.implicitHeight
    color: Theme.bgCard
    radius: Theme.radius
    border.color: Theme.border
    border.width: 1

    // Left accent strip on hover
    Rectangle {
        width: 3
        height: parent.height - 2
        x: 1; y: 1
        radius: Theme.radius
        color: roleColor(card.roleName)
        opacity: cardMa.containsMouse ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }
    }

    // Role badge color
    function roleColor(role) {
        switch (role) {
        case "user":       return Theme.accent
        case "assistant":  return Theme.accentGreen
        case "system":     return Theme.accentGold
        case "tool":       return "#8888cc"
        case "progress":   return Theme.textMuted
        case "error":      return Theme.accentRed
        default:           return Theme.textSecondary
        }
    }

    // Short role label
    function roleLabel(role) {
        switch (role) {
        case "assistant": return "asst"
        case "progress":  return "prog"
        default:          return role
        }
    }

    MouseArea {
        id: cardMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: AppController.jsonlStore.toggleExpanded(card.index)
    }

    ColumnLayout {
        id: cardCol
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0

        // Header row
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: Theme.sp8
            spacing: Theme.sp8

            // Line number
            Label {
                text: card.lineNumber
                font.family: Theme.fontMono
                font.pixelSize: Theme.fontSizeS
                color: Theme.textMuted
                Layout.preferredWidth: 40
                horizontalAlignment: Text.AlignRight
            }

            // Role badge
            Rectangle {
                visible: card.roleName !== ""
                Layout.preferredWidth: roleBadgeLabel.implicitWidth + 12
                Layout.preferredHeight: 18
                radius: 9
                color: Qt.rgba(roleColor(card.roleName).r,
                               roleColor(card.roleName).g,
                               roleColor(card.roleName).b, 0.2)
                border.color: roleColor(card.roleName)
                border.width: 1

                Label {
                    id: roleBadgeLabel
                    anchors.centerIn: parent
                    text: card.roleLabel(card.roleName)
                    font.pixelSize: Theme.fontSizeS
                    color: roleColor(card.roleName)
                }
            }

            // Content preview
            Label {
                text: card.preview
                font.pixelSize: Theme.fontSizeM
                color: Theme.textPrimary
                elide: Text.ElideRight
                wrapMode: Text.Wrap
                maximumLineCount: 2
                Layout.fillWidth: true
            }

            // Tool use indicator
            Rectangle {
                visible: card.hasToolUse
                Layout.preferredWidth: toolLabel.implicitWidth + 8
                Layout.preferredHeight: 16
                radius: 8
                color: Theme.bgButton

                Label {
                    id: toolLabel
                    anchors.centerIn: parent
                    text: "\u2699"
                    font.pixelSize: Theme.fontSizeS
                    color: Theme.textMuted
                }
            }

            // Copy button (fade on hover — no layout shift)
            Rectangle {
                opacity: cardMa.containsMouse ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 120 } }
                Layout.preferredWidth: 22; Layout.preferredHeight: 22; radius: Theme.radius
                color: copyMa.containsMouse ? Theme.bgButtonHov : Theme.bgButton
                ToolTip.text: "Copy JSON"
                ToolTip.visible: copyMa.containsMouse
                ToolTip.delay: 400

                Label {
                    anchors.centerIn: parent
                    text: "\u2398"
                    font.pixelSize: 12
                    color: Theme.textSecondary
                }
                MouseArea {
                    id: copyMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: function(mouse) {
                        mouse.accepted = true
                        AppController.jsonlStore.copyEntry(card.index)
                    }
                }
            }

            // Expand indicator
            Label {
                text: card.isExpanded ? "\u25BC" : "\u25B6"
                font.pixelSize: 8
                color: Theme.textMuted
            }
        }

        // Expanded JSON view
        Rectangle {
            visible: card.isExpanded
            Layout.fillWidth: true
            Layout.leftMargin: Theme.sp8
            Layout.rightMargin: Theme.sp8
            Layout.bottomMargin: Theme.sp8
            Layout.preferredHeight: jsonText.implicitHeight + Theme.sp16
            color: Theme.bgPanel
            radius: Theme.radius
            border.color: Theme.border
            border.width: 1

            TextEdit {
                id: jsonText
                anchors.fill: parent
                anchors.margins: Theme.sp8
                text: card.fullJson
                readOnly: true
                selectByMouse: true
                font.family: Theme.fontMono
                font.pixelSize: Theme.fontSizeM
                color: Theme.textEditor
                wrapMode: TextEdit.Wrap
            }
        }
    }
}
