pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services
import qs.config
import "../../components/"

PanelWindow {
    id: root

    visible: true

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.namespace: "qs_modules"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: ClipboardService.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    color: "transparent"

    function hide() {
        ClipboardService.hide();
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.hide()
    }

    AnimatedPopup {
        id: clipboardAnim
        y: parent.height * 0.2
        anchors.horizontalCenter: parent.horizontalCenter
        width: 520
        height: clipboardPanel.height
        shown: ClipboardService.visible

        Rectangle {
            id: clipboardPanel
            width: 520

            property int fixedHeight: 36 + 32 + 1 + 28 + (Config.spacing * 3)
            property int listHeight: Math.min(420, clipList.contentHeight + 12)

            height: Math.max(200, fixedHeight + listHeight)
            radius: Config.radiusLarge
            color: Config.backgroundTransparentColor
            border.color: Qt.alpha(Config.accentColor, 0.2)
            border.width: 1

            Behavior on height {
                NumberAnimation {
                    duration: Config.animDuration
                    easing.type: Easing.OutCubic
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Config.spacing + 4
                spacing: Config.spacing

                RowLayout {
                    id: header
                    Layout.fillWidth: true
                    spacing: Config.spacing

                    Rectangle {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        radius: Config.radius
                        color: Config.surface1Color

                        Text {
                            anchors.centerIn: parent
                            text: "󰅍"
                            font.family: Config.font
                            font.pixelSize: Config.fontSizeLarge
                            color: Config.accentColor
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Clipboard"
                        font.family: Config.font
                        font.bold: true
                        font.pixelSize: Config.fontSizeLarge
                        color: Config.textColor
                    }

                    Rectangle {
                        visible: ClipboardService.filteredEntries.length > 0
                        Layout.preferredWidth: entryCountText.implicitWidth + 12
                        Layout.preferredHeight: 22
                        radius: height / 2
                        color: Config.surface1Color

                        Text {
                            id: entryCountText
                            anchors.centerIn: parent
                            text: ClipboardService.filteredEntries.length
                            font.family: Config.font
                            font.pixelSize: Config.fontSizeSmall
                            color: Config.subtextColor
                        }
                    }

                    ClearButton {
                        visible: ClipboardService.entries.length > 0
                        icon: ""
                        text: "Clear"

                        onClicked: ClipboardService.clearAll()
                    }
                }

                Item {
                    id: searchBar
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Config.spacing + 6
                        anchors.rightMargin: Config.spacing + 6
                        spacing: Config.spacing

                        TextField {
                            id: searchInput
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            color: Config.textColor
                            font.family: Config.font
                            font.pixelSize: Config.fontSizeNormal
                            verticalAlignment: TextInput.AlignVCenter
                            selectByMouse: true
                            placeholderText: "Search clipboard..."
                            placeholderTextColor: Config.mutedColor

                            background: null

                            onTextChanged: ClipboardService.query = text

                            Keys.onEscapePressed: root.hide()
                            Keys.onReturnPressed: {
                                const idx = ClipboardService.selectedIndex;
                                root.hide();
                                Qt.callLater(() => ClipboardService.selectItem(idx));
                            }
                            Keys.onUpPressed: ClipboardService.navigateUp()
                            Keys.onDownPressed: ClipboardService.navigateDown()
                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_J && (event.modifiers & Qt.ControlModifier)) {
                                    ClipboardService.navigateDown();
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_K && (event.modifiers & Qt.ControlModifier)) {
                                    ClipboardService.navigateUp();
                                    event.accepted = true;
                                }
                            }

                            Component.onCompleted: {
                                ClipboardService.query = "";
                                ClipboardService.selectedIndex = 0;
                                Qt.callLater(forceActiveFocus);
                            }
                        }

                        Rectangle {
                            visible: searchInput.text
                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 24
                            radius: height / 2
                            color: clearSearchMouse.containsMouse ? Config.surface2Color : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: "󰅖"
                                font.family: Config.font
                                font.pixelSize: Config.fontSizeSmall
                                color: Config.subtextColor
                            }

                            MouseArea {
                                id: clearSearchMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    searchInput.text = "";
                                    searchInput.forceActiveFocus();
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    id: separator
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Config.surface1Color
                }

                ListView {
                    id: clipList
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    clip: true
                    spacing: 2
                    model: ClipboardService.filteredEntries
                    currentIndex: ClipboardService.selectedIndex

                    highlightFollowsCurrentItem: false
                    highlight: Rectangle {
                        width: clipList.width
                        height: 44
                        radius: Config.radius
                        color: Config.surface2Color

                        y: clipList.currentItem ? clipList.currentItem.y : 0

                        Behavior on y {
                            NumberAnimation {
                                duration: Config.animDurationShort
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    delegate: Item {
                        id: delegateItem
                        required property int index
                        required property var modelData

                        width: clipList.width
                        height: 44

                        property bool isSelected: index === ClipboardService.selectedIndex
                        property bool isHovered: delegateMouse.containsMouse

                        MouseArea {
                            id: delegateMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            propagateComposedEvents: true

                            onClicked: mouse => {
                                const idx = delegateItem.index;
                                if (delegateItem.isSelected) {
                                    ClipboardService.hide();
                                    Qt.callLater(() => ClipboardService.selectItem(idx));
                                } else {
                                    ClipboardService.selectedIndex = idx;
                                }
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 8
                            spacing: 8

                            Text {
                                Layout.preferredWidth: 24
                                text: (delegateItem.index + 1).toString()
                                font.family: Config.font
                                font.pixelSize: Config.fontSizeSmall
                                color: Config.mutedColor
                                horizontalAlignment: Text.AlignRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: delegateItem.modelData?.text ?? ""
                                color: delegateItem.isSelected ? Config.textColor : Config.subtextColor
                                font.family: Config.font
                                font.pixelSize: Config.fontSizeNormal
                                font.weight: delegateItem.isSelected ? Font.DemiBold : Font.Normal
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }

                            ActionButton {
                                visible: delegateItem.isHovered || delegateItem.isSelected || hovered
                                icon: ""
                                size: 30
                                textColor: hovered ? Config.errorColor : Config.textColor
                                iconSize: Config.fontSizeNormal
                                baseColor: delegateItem.isSelected ? Config.surface2Color : "transparent"
                                hoverColor: delegateItem.isSelected ? Config.backgroundTransparentColor : Config.surface2Color

                                onClicked: ClipboardService.deleteItem(delegateItem.index)
                            }

                            Text {
                                visible: delegateItem.isSelected
                                text: "󰌑"
                                color: Config.accentColor
                                font.family: Config.font
                                font.pixelSize: Config.fontSizeSmall
                            }
                        }
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: Config.spacing
                        visible: clipList.count === 0

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: ClipboardService.query ? "󰅖" : "󰅍"
                            font.family: Config.font
                            font.pixelSize: Config.fontSizeIconLarge
                            color: Config.mutedColor
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: ClipboardService.query ? "No results" : "Clipboard is empty"
                            color: Config.subtextColor
                            font.family: Config.font
                            font.pixelSize: Config.fontSizeNormal
                        }
                    }

                    onCurrentIndexChanged: {
                        positionViewAtIndex(currentIndex, ListView.Contain);
                    }

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded

                        contentItem: Rectangle {
                            implicitWidth: 4
                            radius: 2
                            color: Config.surface2Color
                            opacity: parent.active ? 1 : 0

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: Config.animDurationShort
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    HyprlandFocusGrab {
        windows: [root]
        active: ClipboardService.visible
        onCleared: {
            if (ClipboardService.visible)
                root.hide();
        }
    }
}
