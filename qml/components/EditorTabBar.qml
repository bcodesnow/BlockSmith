import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import BlockSmith

Rectangle {
    id: tabBar
    color: Theme.bgHeader
    height: visible ? 30 : 0
    visible: AppController.tabModel.count > 0

    signal tabCloseRequested(int index)

    // Scroll buttons for overflow
    Rectangle {
        id: scrollLeftBtn
        width: 20; height: parent.height
        anchors.left: parent.left
        color: scrollLeftMa.containsMouse ? Theme.bgButtonHov : "transparent"
        visible: tabListView.contentX > 0
        z: 2

        Label {
            anchors.centerIn: parent
            text: "\u25C0"
            font.pixelSize: 10
            color: Theme.textSecondary
        }
        MouseArea {
            id: scrollLeftMa
            anchors.fill: parent
            hoverEnabled: true
            onClicked: tabListView.contentX = Math.max(0, tabListView.contentX - 150)
        }
    }

    // Tab list — fixed anchors with conditional margins to avoid binding loops
    ListView {
        id: tabListView
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: scrollLeftBtn.visible ? scrollLeftBtn.width : 0
        anchors.rightMargin: overflowBtn.width
            + (scrollRightBtn.visible ? scrollRightBtn.width : 0)
        orientation: ListView.Horizontal
        clip: true
        model: AppController.tabModel
        currentIndex: AppController.tabModel.activeIndex
        highlightFollowsCurrentItem: false
        highlight: null
        interactive: false // we handle scrolling ourselves
        spacing: 0

        // Mouse wheel scrolling
        WheelHandler {
            onWheel: function(event) {
                let delta = event.angleDelta.y || event.angleDelta.x
                tabListView.contentX = Math.max(0,
                    Math.min(tabListView.contentWidth - tabListView.width,
                             tabListView.contentX - delta))
            }
        }

        delegate: Rectangle {
            id: tabDelegate
            width: Math.min(220, Math.max(80, tabLabel.implicitWidth + 52))
            height: tabBar.height
            color: isActive ? Theme.bg
                 : tabDelegateMa.containsMouse ? Theme.bgPanel : Theme.bgHeader

            required property int index
            required property string fileName
            required property string filePath
            required property bool isModified
            required property bool isPinned
            required property bool isActive

            // Active tab indicator (bottom border)
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 2
                color: Theme.accent
                visible: tabDelegate.isActive
            }

            // Right border separator
            Rectangle {
                anchors.right: parent.right
                width: 1
                height: parent.height
                color: Theme.border
                opacity: 0.5
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 4
                spacing: 4

                // Pin indicator
                Label {
                    visible: tabDelegate.isPinned
                    text: "\uD83D\uDCCC"
                    font.pixelSize: 9
                    color: Theme.textMuted
                }

                // File name
                Label {
                    id: tabLabel
                    text: tabDelegate.fileName
                    font.pixelSize: Theme.fontSizeXS
                    color: tabDelegate.isActive ? Theme.textPrimary
                         : tabDelegateMa.containsMouse ? Theme.textSecondary
                         : Theme.textMuted
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                // Modified dot / Close button
                Rectangle {
                    width: 18; height: 18
                    radius: 3
                    color: closeBtnMa.containsMouse ? Theme.bgButtonHov : "transparent"

                    Label {
                        anchors.centerIn: parent
                        text: closeBtnMa.containsMouse ? "\u2715"
                            : tabDelegate.isModified ? "\u25CF" : ""
                        font.pixelSize: closeBtnMa.containsMouse ? 10 : 8
                        color: tabDelegate.isModified && !closeBtnMa.containsMouse
                               ? Theme.accentGold : Theme.textMuted
                    }

                    MouseArea {
                        id: closeBtnMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: tabBar.tabCloseRequested(tabDelegate.index)
                    }

                    visible: tabDelegate.isActive || tabDelegateMa.containsMouse
                             || tabDelegate.isModified
                }
            }

            MouseArea {
                id: tabDelegateMa
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                z: -1

                onClicked: function(mouse) {
                    if (mouse.button === Qt.MiddleButton) {
                        tabBar.tabCloseRequested(tabDelegate.index)
                    } else if (mouse.button === Qt.RightButton) {
                        tabContextMenu.tabFilePath = tabDelegate.filePath
                        tabContextMenu.popup()
                    } else {
                        AppController.tabModel.activeIndex = (tabDelegate.index)
                    }
                }
            }

            ToolTip.text: tabDelegate.filePath
            ToolTip.visible: tabDelegateMa.containsMouse && !tabDelegateMa.pressed
            ToolTip.delay: 600
        }
    }

    // Scroll right button
    Rectangle {
        id: scrollRightBtn
        width: 20; height: parent.height
        anchors.right: parent.right
        anchors.rightMargin: overflowBtn.width
        color: scrollRightMa.containsMouse ? Theme.bgButtonHov : "transparent"
        visible: tabListView.contentX < tabListView.contentWidth - tabListView.width - 1
        z: 2

        Label {
            anchors.centerIn: parent
            text: "\u25B6"
            font.pixelSize: 10
            color: Theme.textSecondary
        }
        MouseArea {
            id: scrollRightMa
            anchors.fill: parent
            hoverEnabled: true
            onClicked: tabListView.contentX = Math.min(
                tabListView.contentWidth - tabListView.width,
                tabListView.contentX + 150)
        }
    }

    // Overflow dropdown
    Rectangle {
        id: overflowBtn
        width: 24; height: parent.height
        anchors.right: parent.right
        color: overflowMa.containsMouse ? Theme.bgButtonHov : "transparent"
        visible: AppController.tabModel.count > 0

        Label {
            anchors.centerIn: parent
            text: "\u25BE"
            font.pixelSize: 12
            color: Theme.textSecondary
        }
        MouseArea {
            id: overflowMa
            anchors.fill: parent
            hoverEnabled: true
            onClicked: overflowMenu.open()
        }
    }

    // Overflow popup listing all tabs
    Popup {
        id: overflowMenu
        x: parent.width - width
        y: parent.height
        width: 280
        padding: 4
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: Theme.bgPanel
            border.color: Theme.border
            border.width: 1
            radius: Theme.radius
        }

        ListView {
            width: parent.width
            height: Math.min(contentHeight, 300)
            clip: true
            model: AppController.tabModel

            delegate: Rectangle {
                width: ListView.view.width
                height: 28
                color: isActive ? Theme.bgSelection
                     : overflowItemMa.containsMouse ? Theme.bgCardHov : "transparent"
                radius: 2

                required property int index
                required property string fileName
                required property bool isModified
                required property bool isActive

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 6

                    Label {
                        visible: isModified
                        text: "\u25CF"
                        font.pixelSize: 8
                        color: Theme.accentGold
                    }

                    Label {
                        text: fileName
                        font.pixelSize: Theme.fontSizeXS
                        color: isActive ? Theme.textBright : Theme.textPrimary
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                MouseArea {
                    id: overflowItemMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        AppController.tabModel.activeIndex = (index)
                        overflowMenu.close()
                    }
                }
            }
        }
    }

    // Context menu — stores filePath (stable) instead of index (can shift)
    Menu {
        id: tabContextMenu
        property string tabFilePath: ""

        function resolveIndex() {
            return AppController.tabModel.findTab(tabFilePath)
        }

        MenuItem {
            text: "Close"
            onTriggered: {
                let idx = tabContextMenu.resolveIndex()
                if (idx >= 0) tabBar.tabCloseRequested(idx)
            }
        }
        MenuItem {
            text: "Close Others"
            onTriggered: {
                let idx = tabContextMenu.resolveIndex()
                if (idx >= 0) AppController.tabModel.closeOtherTabs(idx)
            }
        }
        MenuItem {
            text: "Close to the Right"
            onTriggered: {
                let idx = tabContextMenu.resolveIndex()
                if (idx >= 0) AppController.tabModel.closeTabsToRight(idx)
            }
        }
        MenuItem {
            text: "Close All"
            onTriggered: AppController.tabModel.closeAllTabs()
        }
        MenuItem {
            text: "Close Saved"
            onTriggered: AppController.tabModel.closeSavedTabs()
        }
        MenuSeparator {}
        MenuItem {
            text: "Copy File Path"
            onTriggered: AppController.copyToClipboard(tabContextMenu.tabFilePath)
        }
        MenuItem {
            text: "Reveal in Explorer"
            onTriggered: AppController.revealInExplorer(tabContextMenu.tabFilePath)
        }
        MenuSeparator {}
        MenuItem {
            text: {
                let idx = tabContextMenu.resolveIndex()
                if (idx >= 0) {
                    let mi = AppController.tabModel.index(idx, 0)
                    return AppController.tabModel.data(mi, TabModel.IsPinnedRole)
                           ? "Unpin Tab" : "Pin Tab"
                }
                return "Pin Tab"
            }
            onTriggered: {
                let idx = tabContextMenu.resolveIndex()
                if (idx < 0) return
                let mi = AppController.tabModel.index(idx, 0)
                let pinned = AppController.tabModel.data(mi, TabModel.IsPinnedRole)
                if (pinned)
                    AppController.tabModel.unpinTab(idx)
                else
                    AppController.tabModel.pinTab(idx)
            }
        }
    }
}
