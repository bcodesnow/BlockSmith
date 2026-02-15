import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: findBar
    color: Theme.bgPanel
    border.color: Theme.border
    border.width: 1
    visible: false
    height: replaceMode ? 68 : 36

    property bool replaceMode: false
    property int matchCount: 0
    property int currentMatch: 0

    signal findNext(string text, bool caseSensitive)
    signal findPrev(string text, bool caseSensitive)
    signal replaceOne(string findText, string replaceText, bool caseSensitive)
    signal replaceAll(string findText, string replaceText, bool caseSensitive)
    signal closed()

    function openFind() {
        replaceMode = false
        visible = true
        findField.forceActiveFocus()
        findField.selectAll()
    }

    function openReplace() {
        replaceMode = true
        visible = true
        findField.forceActiveFocus()
        findField.selectAll()
    }

    function close() {
        visible = false
        matchCount = 0
        currentMatch = 0
        closed()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 4
        spacing: 2

        // Find row
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            TextField {
                id: findField
                Layout.fillWidth: true
                Layout.preferredHeight: 26
                placeholderText: "Find..."
                font.pixelSize: Theme.fontSizeM
                color: Theme.textPrimary
                placeholderTextColor: Theme.textPlaceholder
                background: Rectangle {
                    color: Theme.bg
                    radius: Theme.radius
                    border.color: findField.activeFocus ? Theme.borderFocus : Theme.borderHover
                    border.width: 1
                }

                onTextChanged: {
                    if (text.length > 0)
                        findBar.findNext(text, caseSensitiveBtn.checked)
                    else {
                        findBar.matchCount = 0
                        findBar.currentMatch = 0
                    }
                }

                Keys.onEscapePressed: findBar.close()
                Keys.onReturnPressed: function(event) {
                    if (event.modifiers & Qt.ShiftModifier)
                        findBar.findPrev(text, caseSensitiveBtn.checked)
                    else
                        findBar.findNext(text, caseSensitiveBtn.checked)
                }
            }

            // Match counter
            Label {
                text: findField.text.length > 0
                    ? (findBar.matchCount > 0 ? findBar.currentMatch + "/" + findBar.matchCount : "No results")
                    : ""
                font.pixelSize: Theme.fontSizeS
                color: findBar.matchCount > 0 ? Theme.textSecondary : Theme.accentRed
                Layout.preferredWidth: 60
                horizontalAlignment: Text.AlignHCenter
            }

            // Case sensitive toggle
            Rectangle {
                id: caseSensitiveBtn
                width: 26
                height: 26
                radius: Theme.radius
                color: checked ? Theme.bgActive : (caseMa.containsMouse ? Theme.border : "transparent")
                property bool checked: false
                ToolTip.text: "Case sensitive"
                ToolTip.visible: caseMa.containsMouse
                ToolTip.delay: 400

                Label {
                    anchors.centerIn: parent
                    text: "Aa"
                    font.pixelSize: Theme.fontSizeXS
                    font.bold: true
                    color: parent.checked ? Theme.textWhite : Theme.textSecondary
                }
                MouseArea {
                    id: caseMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        parent.checked = !parent.checked
                        if (findField.text.length > 0)
                            findBar.findNext(findField.text, parent.checked)
                    }
                }
            }

            // Previous
            Rectangle {
                width: 26; height: 26; radius: Theme.radius
                color: prevMa.containsMouse ? Theme.border : "transparent"
                Label {
                    anchors.centerIn: parent
                    text: "\u25B2"
                    font.pixelSize: Theme.fontSizeS
                    color: Theme.textPrimary
                }
                MouseArea {
                    id: prevMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: findBar.findPrev(findField.text, caseSensitiveBtn.checked)
                }
            }

            // Next
            Rectangle {
                width: 26; height: 26; radius: Theme.radius
                color: nextMa.containsMouse ? Theme.border : "transparent"
                Label {
                    anchors.centerIn: parent
                    text: "\u25BC"
                    font.pixelSize: Theme.fontSizeS
                    color: Theme.textPrimary
                }
                MouseArea {
                    id: nextMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: findBar.findNext(findField.text, caseSensitiveBtn.checked)
                }
            }

            // Close
            Rectangle {
                width: 26; height: 26; radius: Theme.radius
                color: closeMa.containsMouse ? Theme.bgButtonHov : "transparent"
                Label {
                    anchors.centerIn: parent
                    text: "\u2715"
                    font.pixelSize: Theme.fontSizeM
                    color: Theme.textSecondary
                }
                MouseArea {
                    id: closeMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: findBar.close()
                }
            }
        }

        // Replace row
        RowLayout {
            Layout.fillWidth: true
            spacing: 4
            visible: findBar.replaceMode

            TextField {
                id: replaceField
                Layout.fillWidth: true
                Layout.preferredHeight: 26
                placeholderText: "Replace..."
                font.pixelSize: Theme.fontSizeM
                color: Theme.textPrimary
                placeholderTextColor: Theme.textPlaceholder
                background: Rectangle {
                    color: Theme.bg
                    radius: Theme.radius
                    border.color: replaceField.activeFocus ? Theme.borderFocus : Theme.borderHover
                    border.width: 1
                }
                Keys.onEscapePressed: findBar.close()
            }

            // Replace one
            Rectangle {
                width: replaceOneLabel.implicitWidth + 12
                height: 26; radius: Theme.radius
                color: replaceOneMa.containsMouse ? Theme.border : Theme.bgHeader
                border.color: Theme.borderHover; border.width: 1
                Label {
                    id: replaceOneLabel
                    anchors.centerIn: parent
                    text: "Replace"
                    font.pixelSize: Theme.fontSizeXS
                    color: Theme.textPrimary
                }
                MouseArea {
                    id: replaceOneMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: findBar.replaceOne(findField.text, replaceField.text, caseSensitiveBtn.checked)
                }
            }

            // Replace all
            Rectangle {
                width: replaceAllLabel.implicitWidth + 12
                height: 26; radius: Theme.radius
                color: replaceAllMa.containsMouse ? Theme.border : Theme.bgHeader
                border.color: Theme.borderHover; border.width: 1
                Label {
                    id: replaceAllLabel
                    anchors.centerIn: parent
                    text: "All"
                    font.pixelSize: Theme.fontSizeXS
                    color: Theme.textPrimary
                }
                MouseArea {
                    id: replaceAllMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: findBar.replaceAll(findField.text, replaceField.text, caseSensitiveBtn.checked)
                }
            }
        }
    }
}
