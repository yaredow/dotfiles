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
    WlrLayershell.keyboardFocus: LauncherService.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    color: "transparent"

    function hide() {
        launcherPanel.forceActiveFocus();
        LauncherService.hide();
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.hide()
    }

    AnimatedPopup {
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.12
        anchors.horizontalCenter: parent.horizontalCenter
        width: 520
        height: launcherPanel.height
        shown: LauncherService.visible

        Rectangle {
            id: launcherPanel
            width: 520

            property int listHeight: Math.min(420, appList.contentHeight + 12)
            property int totalHeight: appList.count > 0 ? listHeight + 52 + 24 : 52 + 24

            height: totalHeight
            radius: Config.radiusLarge
            color: Config.backgroundTransparentColor
            border.color: Qt.alpha(Config.accentColor, 0.6)
            border.width: 2

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

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    color: "transparent"

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
                            font.family: Config.monoFont
                            font.pixelSize: Config.fontSizeNormal
                            verticalAlignment: TextInput.AlignVCenter
                            selectByMouse: true
                            placeholderText: LauncherService.mode === "files" ? "Search videos…" : "Search apps…"
                            placeholderTextColor: Config.mutedColor
                            background: null

                            onTextChanged: LauncherService.query = text

                            Keys.onEscapePressed: root.hide()

                            Keys.onReturnPressed: {
                                launcherPanel.forceActiveFocus();
                                LauncherService.launchSelected();
                            }

                            Keys.onUpPressed: {
                                if (LauncherService.selectedIndex > 0)
                                    LauncherService.selectedIndex--;
                            }

                            Keys.onDownPressed: {
                                if (LauncherService.selectedIndex < LauncherService.filteredApps.length - 1)
                                    LauncherService.selectedIndex++;
                            }

                            Keys.onTabPressed: event => {
                                if (LauncherService.selectedIndex < LauncherService.filteredApps.length - 1)
                                    LauncherService.selectedIndex++;
                                event.accepted = true;
                            }

                            Keys.onPressed: event => {
                                const isBacktab = event.key === Qt.Key_Backtab;
                                const isShiftTab = event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier);

                                if (isBacktab || isShiftTab) {
                                    if (LauncherService.selectedIndex > 0)
                                        LauncherService.selectedIndex--;
                                    event.accepted = true;
                                }
                            }

                            Component.onCompleted: {
                                LauncherService.query = "";
                                LauncherService.selectedIndex = 0;
                                Qt.callLater(() => {
                                    if (LauncherService.visible) {
                                        forceActiveFocus();
                                    }
                                });
                            }
                        }

                        Rectangle {
                            visible: LauncherService.filteredApps.length > 0
                            Layout.preferredWidth: countText.implicitWidth + 12
                            Layout.preferredHeight: 22
                            radius: height / 2
                            color: Config.surface1Color

                            Text {
                                id: countText
                                anchors.centerIn: parent
                                text: LauncherService.filteredApps.length
                                font.family: Config.monoFont
                                font.pixelSize: Config.fontSizeSmall
                                color: Config.subtextColor
                            }
                        }

                        Rectangle {
                            visible: LauncherService.mode === "files"
                            Layout.preferredWidth: modeLabel.implicitWidth + 12
                            Layout.preferredHeight: 22
                            radius: height / 2
                            color: Config.accentColor

                            Text {
                                id: modeLabel
                                anchors.centerIn: parent
                                text: "Videos"
                                font.family: Config.monoFont
                                font.pixelSize: Config.fontSizeSmall
                                color: Config.textColor
                            }
                        }

                        Rectangle {
                            visible: searchInput.text
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 28
                            radius: height / 2
                            color: clearMouse.containsMouse ? Config.surface2Color : "transparent"

                            Behavior on color {
                                ColorAnimation {
                                    duration: Config.animDurationShort
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "󰅖"
                                font.family: Config.monoFont
                                font.pixelSize: Config.fontSizeSmall
                                color: Config.subtextColor
                            }

                            MouseArea {
                                id: clearMouse
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

                ListView {
                    id: appList
                    Layout.fillWidth: true
                    Layout.fillHeight: appList.count > 0
                    visible: appList.count > 0

                    clip: true
                    spacing: 4
                    model: LauncherService.filteredApps
                    currentIndex: LauncherService.selectedIndex

                    add: Transition {
                        NumberAnimation {
                            property: "opacity"
                            from: 0
                            to: 1
                            duration: Config.animDurationShort
                        }
                        NumberAnimation {
                            property: "scale"
                            from: 0.8
                            to: 1
                            duration: Config.animDurationShort
                            easing.type: Easing.OutBack
                        }
                    }

                    remove: Transition {
                        NumberAnimation {
                            property: "opacity"
                            to: 0
                            duration: Config.animDurationShort
                        }
                        NumberAnimation {
                            property: "scale"
                            to: 0.8
                            duration: Config.animDurationShort
                        }
                    }

                    displaced: Transition {
                        NumberAnimation {
                            property: "y"
                            duration: Config.animDuration
                            easing.type: Easing.OutCubic
                        }
                    }

                    highlightFollowsCurrentItem: false
                    highlight: Rectangle {
                        width: appList.width
                        height: 56
                        radius: Config.radius
                        color: Config.surface2Color

                        y: appList.currentItem ? appList.currentItem.y : 0

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

                        width: appList.width
                        height: 56

                        property bool isSelected: index === LauncherService.selectedIndex

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 14

                            Rectangle {
                                Layout.preferredWidth: 40
                                Layout.preferredHeight: 40
                                radius: Config.radiusSmall
                    color: "transparent"

                                Image {
                                    anchors.centerIn: parent
                                    width: 32
                                    height: 32
                                    source: {
                                        if (delegateItem.modelData?._type === "file")
                                            return Qt.resolvedUrl("cinema.svg");
                                        const icon = delegateItem.modelData?.icon ?? "";
                                        return icon ? "image://icon/" + icon : "image://icon/application-x-executable";
                                    }
                                    sourceSize: Qt.size(32, 32)
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    Layout.fillWidth: true
                                    text: delegateItem.modelData?.name ?? ""
                                    color: Config.textColor
                                    font.family: Config.monoFont
                                    font.pixelSize: Config.fontSizeSmall
                                    font.weight: delegateItem.isSelected ? Font.DemiBold : Font.Normal
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: delegateItem.modelData?.comment || delegateItem.modelData?.genericName || ""
                                    color: Config.subtextColor
                                    font.family: Config.monoFont
                                    font.pixelSize: Config.fontSizeSmall
                                    elide: Text.ElideRight
                                    visible: text !== ""
                                }
                            }

                            Text {
                                visible: delegateItem.isSelected
                                text: "󰌑"
                                color: Config.accentColor
                                font.family: Config.monoFont
                                font.pixelSize: Config.fontSizeSmall
                            }
                        }

                        MouseArea {
                            id: delegateMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (delegateItem.isSelected) {
                                    launcherPanel.forceActiveFocus();
                                    LauncherService.launch(delegateItem.modelData);
                                } else {
                                    LauncherService.selectedIndex = delegateItem.index;
                                }
                            }
                        }
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: Config.spacing
                        visible: appList.count === 0
                        opacity: visible ? 1 : 0

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Config.animDurationShort
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: LauncherService.query ? "󰅖" : "󰑓"
                            font.family: Config.monoFont
                            font.pixelSize: Config.fontSizeIcon
                            color: Config.mutedColor

                            RotationAnimator on rotation {
                                from: 0
                                to: 360
                                duration: 1000
                                loops: Animation.Infinite
                                running: LauncherService.query && appList.count === 0
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: LauncherService.query ? "No results" : "Type to search"
                            color: Config.subtextColor
                            font.family: Config.monoFont
                            font.pixelSize: Config.fontSizeSmall
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

    Shortcut {
        sequence: "Ctrl+F"
        context: Qt.ApplicationShortcut
        onActivated: {
            if (LauncherService.visible)
                LauncherService.toggleFileMode();
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
