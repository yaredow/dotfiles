pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services
import qs.config

PanelWindow {
    id: root

    visible: LauncherService.visible || root.reveal > 0.001

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.namespace: "qs_modules"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: LauncherService.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    color: "transparent"

    property real reveal: LauncherService.visible ? 1 : 0

    function hide() {
        LauncherService.hide();
    }

    Behavior on reveal {
        NumberAnimation {
            duration: Config.animDuration
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha("#000000", 0.5 * root.reveal)
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.hide()
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: 600
        height: Math.min(cardCol.implicitHeight + 28, parent.height * 0.75)
        color: Config.backgroundColor
        border.color: Config.sepColor
        border.width: 1
        radius: Config.radiusLarge
        scale: root.reveal
        transformOrigin: Item.Center

    Behavior on scale {
        NumberAnimation {
            duration: Config.animDuration
            easing.type: Easing.OutCubic
        }
    }

        MouseArea { anchors.fill: parent }

        focus: LauncherService.visible

        Column {
            id: cardCol
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            Item {
                width: parent.width
                height: 28

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "LAUNCHER"
                    color: Config.textColor
                    font.family: Config.font
                    font.pixelSize: 16
                    font.letterSpacing: 4
                    font.weight: Font.Medium
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: Config.sepColor
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !LauncherService.query && LauncherService.filteredApps.length > 0
                    text: LauncherService.filteredApps.length + " APPS"
                    color: Config.subtextColor
                    font.family: Config.font
                    font.pixelSize: 10
                    font.letterSpacing: 2
                    opacity: 0.7
                }
            }

            Item {
                width: parent.width
                height: 28
                visible: LauncherService.visible

                Text {
                    id: searchIcon
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰍉"
                    color: Config.accentColor
                    font.family: Config.font
                    font.pixelSize: 14
                    font.letterSpacing: 1
                }

                Text {
                    id: queryText
                    anchors.left: searchIcon.right
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: LauncherService.query.length > 0 ? LauncherService.query : "Type to search apps…"
                    color: LauncherService.query.length > 0 ? Config.textColor : Config.subtextColor
                    opacity: LauncherService.query.length > 0 ? 1 : 0.5
                    font.family: Config.font
                    font.pixelSize: 13
                    font.letterSpacing: 1
                }

                Rectangle {
                    id: caret
                    width: 2
                    height: 14
                    color: Config.accentColor
                    anchors.verticalCenter: parent.verticalCenter
                    x: LauncherService.query.length === 0
                       ? searchIcon.x + searchIcon.width + 8
                       : queryText.x + queryText.contentWidth + 2
                    visible: LauncherService.visible

                    SequentialAnimation on opacity {
                        running: LauncherService.visible
                        loops: Animation.Infinite
                        NumberAnimation { from: 1; to: 0.2; duration: 600; easing.type: Easing.InOutSine }
                        NumberAnimation { from: 0.2; to: 1; duration: 600; easing.type: Easing.InOutSine }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Config.sepColor
            }

            Item {
                id: listArea
                width: parent.width
                height: Math.max(60, card.height - 28 - 28 - 10 * 4 - 14)

                ListView {
                    id: resultList
                    anchors.fill: parent
                    model: LauncherService.filteredApps
                    currentIndex: LauncherService.selectedIndex
                    highlightFollowsCurrentItem: false
                    boundsBehavior: Flickable.StopAtBounds
                    clip: true
                    pixelAligned: true
                    spacing: 0

                    delegate: Item {
                        id: row
                        required property var modelData
                        required property int index
                        width: ListView.view.width
                        height: 40

                        readonly property bool isSelected: LauncherService.selectedIndex === index

                        Rectangle {
                            anchors.fill: parent
                            radius: Config.radiusSmall
                            color: row.isSelected ? Config.greyBlueColor
                                                  : rowMouse.containsMouse ? Qt.alpha(Config.surface2Color, 0.5)
                                                                           : "transparent"

                            Behavior on color {
                                ColorAnimation { duration: 40 }
                            }
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: 2
                            radius: 1
                            color: Config.accentColor
                            visible: row.isSelected
                        }

                        Item {
                            id: iconText
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            width: 22
                            height: 22

                            readonly property string iconUrl: {
                                const raw = row.modelData?.icon ?? "";
                                if (!raw) return "";
                                if (raw.charAt(0) === "/") return "file://" + raw;
                                return "image://icon/" + raw;
                            }

                            readonly property bool hasImage: appImg.status === Image.Ready

                            Text {
                                anchors.centerIn: parent
                                visible: !iconText.hasImage
                                text: "󰘙"
                                color: row.isSelected ? Config.accentColor : Config.subtextColor
                                font.family: Config.font
                                font.pixelSize: 16
                            }

                            Image {
                                id: appImg
                                anchors.centerIn: parent
                                width: 18
                                height: 18
                                visible: iconText.hasImage
                                source: iconText.iconUrl
                                sourceSize.width: 36
                                sourceSize.height: 36
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                asynchronous: true
                                cache: true
                            }
                        }

                        Text {
                            id: titleText
                            anchors.left: iconText.right
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: row.modelData?.name ?? ""
                            color: row.isSelected ? Config.textColor : Config.fg
                            font.family: Config.font
                            font.pixelSize: 12
                            font.weight: row.isSelected ? Font.Medium : Font.Normal
                            font.letterSpacing: 1
                            elide: Text.ElideRight
                            width: row.width - iconText.width - catText.implicitWidth - 60
                        }

                        Text {
                            id: catText
                            anchors.right: parent.right
                            anchors.rightMargin: 14
                            anchors.verticalCenter: parent.verticalCenter
                            text: (row.modelData?.genericName || row.modelData?.comment || "").toUpperCase()
                            color: row.isSelected ? Config.accentColor : Config.subtextColor
                            opacity: row.isSelected ? 0.95 : 0.6
                            font.family: Config.font
                            font.pixelSize: 9
                            font.letterSpacing: 2
                            elide: Text.ElideLeft
                            horizontalAlignment: Text.AlignRight
                            width: Math.min(implicitWidth, row.width * 0.35)
                            visible: text !== ""
                        }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onPositionChanged: LauncherService.selectedIndex = row.index
                            onClicked: {
                                LauncherService.selectedIndex = row.index;
                                LauncherService.launch(row.modelData);
                                root.hide();
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: resultList.count === 0
                        text: LauncherService.query ? "NO MATCHES" : "INDEXING APPS…"
                        color: Config.subtextColor
                        font.family: Config.font
                        font.pixelSize: 10
                        font.letterSpacing: 3
                        opacity: 0.6
                    }

                    onCurrentIndexChanged: {
                        positionViewAtIndex(currentIndex, ListView.Contain);
                    }

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded

                        contentItem: Rectangle {
                            implicitWidth: 3
                            radius: 1.5
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

            Rectangle {
                width: parent.width
                height: 1
                color: Config.sepColor
            }

            Item {
                width: parent.width
                height: 18

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 4
                    elide: Text.ElideRight
                    text: {
                        const it = LauncherService.filteredApps[LauncherService.selectedIndex];
                        if (!it) return "";
                        const cmd = (it.execString || "").replace(/%[uUfFdDnNickvm]/g, "").trim();
                        return "$ " + cmd;
                    }
                    color: Config.subtextColor
                    font.family: Config.font
                    font.pixelSize: 10
                    font.letterSpacing: 1
                    opacity: 0.65
                }
            }
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                root.hide();
                event.accepted = true;
            } else if (event.key === Qt.Key_Down || (event.key === Qt.Key_Tab && !(event.modifiers & Qt.ShiftModifier))) {
                LauncherService.navigateDown();
                event.accepted = true;
            } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                LauncherService.navigateUp();
                event.accepted = true;
            } else if (event.key === Qt.Key_PageDown) {
                for (let i = 0; i < 8; i++) LauncherService.navigateDown();
                event.accepted = true;
            } else if (event.key === Qt.Key_PageUp) {
                for (let i = 0; i < 8; i++) LauncherService.navigateUp();
                event.accepted = true;
            } else if (event.key === Qt.Key_Home) {
                LauncherService.selectedIndex = 0;
                event.accepted = true;
            } else if (event.key === Qt.Key_End) {
                LauncherService.selectedIndex = Math.max(0, LauncherService.filteredApps.length - 1);
                event.accepted = true;
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                LauncherService.launchSelected();
                event.accepted = true;
            } else if (event.key === Qt.Key_Backspace) {
                if (LauncherService.query.length > 0) {
                    LauncherService.query = LauncherService.query.slice(0, -1);
                }
                event.accepted = true;
            } else if (event.text && event.text.length === 1) {
                const ch = event.text;
                if (ch.charCodeAt(0) >= 32 && ch.charCodeAt(0) !== 127) {
                    LauncherService.query += ch;
                    event.accepted = true;
                }
            }
        }
    }

    HyprlandFocusGrab {
        windows: [root]
        active: LauncherService.visible
        onCleared: {
            if (LauncherService.visible)
                root.hide();
        }
    }
}
