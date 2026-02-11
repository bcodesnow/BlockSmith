import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: findBar
    color: "#2d2d2d"
    border.color: "#444"
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
                font.pixelSize: 12
                color: "#ddd"
                placeholderTextColor: "#666"
                background: Rectangle {
                    color: "#1e1e1e"
                    radius: 3
                    border.color: findField.activeFocus ? "#6c9bd2" : "#555"
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
                Keys.onReturnPressed: findBar.findNext(text, caseSensitiveBtn.checked)
            }

            // Match counter
            Label {
                text: findField.text.length > 0
                    ? (findBar.matchCount > 0 ? findBar.currentMatch + "/" + findBar.matchCount : "No results")
                    : ""
                font.pixelSize: 10
                color: findBar.matchCount > 0 ? "#999" : "#e06c75"
                Layout.preferredWidth: 60
                horizontalAlignment: Text.AlignHCenter
            }

            // Case sensitive toggle
            Rectangle {
                id: caseSensitiveBtn
                width: 26
                height: 26
                radius: 3
                color: checked ? "#3d6a99" : (caseMa.containsMouse ? "#444" : "transparent")
                property bool checked: false
                ToolTip.text: "Case sensitive"
                ToolTip.visible: caseMa.containsMouse
                ToolTip.delay: 400

                Label {
                    anchors.centerIn: parent
                    text: "Aa"
                    font.pixelSize: 11
                    font.bold: true
                    color: parent.checked ? "#fff" : "#999"
                }
                MouseArea {
                    id: caseMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        parent.checked = !parent.checked
                        if (findField.text.length > 0)
                            findBar.findNext(findField.text, parent.checked)
                    }
                }
            }

            // Previous
            Rectangle {
                width: 26; height: 26; radius: 3
                color: prevMa.containsMouse ? "#444" : "transparent"
                Label {
                    anchors.centerIn: parent
                    text: "\u25B2"
                    font.pixelSize: 10
                    color: "#ccc"
                }
                MouseArea {
                    id: prevMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: findBar.findPrev(findField.text, caseSensitiveBtn.checked)
                }
            }

            // Next
            Rectangle {
                width: 26; height: 26; radius: 3
                color: nextMa.containsMouse ? "#444" : "transparent"
                Label {
                    anchors.centerIn: parent
                    text: "\u25BC"
                    font.pixelSize: 10
                    color: "#ccc"
                }
                MouseArea {
                    id: nextMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: findBar.findNext(findField.text, caseSensitiveBtn.checked)
                }
            }

            // Close
            Rectangle {
                width: 26; height: 26; radius: 3
                color: closeMa.containsMouse ? "#555" : "transparent"
                Label {
                    anchors.centerIn: parent
                    text: "\u2715"
                    font.pixelSize: 12
                    color: "#999"
                }
                MouseArea {
                    id: closeMa
                    anchors.fill: parent
                    hoverEnabled: true
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
                font.pixelSize: 12
                color: "#ddd"
                placeholderTextColor: "#666"
                background: Rectangle {
                    color: "#1e1e1e"
                    radius: 3
                    border.color: replaceField.activeFocus ? "#6c9bd2" : "#555"
                    border.width: 1
                }
                Keys.onEscapePressed: findBar.close()
            }

            // Replace one
            Rectangle {
                width: replaceOneLabel.implicitWidth + 12
                height: 26; radius: 3
                color: replaceOneMa.containsMouse ? "#444" : "#333"
                border.color: "#555"; border.width: 1
                Label {
                    id: replaceOneLabel
                    anchors.centerIn: parent
                    text: "Replace"
                    font.pixelSize: 11
                    color: "#ccc"
                }
                MouseArea {
                    id: replaceOneMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: findBar.replaceOne(findField.text, replaceField.text, caseSensitiveBtn.checked)
                }
            }

            // Replace all
            Rectangle {
                width: replaceAllLabel.implicitWidth + 12
                height: 26; radius: 3
                color: replaceAllMa.containsMouse ? "#444" : "#333"
                border.color: "#555"; border.width: 1
                Label {
                    id: replaceAllLabel
                    anchors.centerIn: parent
                    text: "All"
                    font.pixelSize: 11
                    color: "#ccc"
                }
                MouseArea {
                    id: replaceAllMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: findBar.replaceAll(findField.text, replaceField.text, caseSensitiveBtn.checked)
                }
            }
        }
    }
}
