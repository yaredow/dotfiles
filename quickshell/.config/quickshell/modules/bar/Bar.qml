pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import qs.config
import qs.services
import "../../components/"
import "../notifications/"
import "../calendar/"

PanelWindow {
    id: bar
    required property var host

    color: "transparent"
    anchors {
        top: host.barEdge !== "bottom"
        bottom: host.barEdge !== "top"
        left: host.barEdge !== "right"
        right: host.barEdge !== "left"
    }

    implicitHeight: host.isHorizontal ? Config.barHeight : 0
    implicitWidth: host.isHorizontal ? 0 : Config.barHeight
    exclusiveZone: Config.barHeight

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "qs_modules"

    Rectangle {
        id: slabBg
        anchors.fill: parent
        color: Config.backgroundTransparentColor

        opacity: 1.0
        states: State {
            name: "idle"
            when: host.isIdle
            PropertyChanges {
                target: slabBg
                opacity: 0.7
            }
        }
        transitions: [
            Transition {
                to: "idle"
                NumberAnimation {
                    property: "opacity"
                    duration: 6000
                    easing.type: Easing.OutQuart
                }
            },
            Transition {
                from: "idle"
                NumberAnimation {
                    property: "opacity"
                    duration: 6000
                    easing.type: Easing.OutQuad
                }
            }
        ]

        Rectangle {
            visible: host.isHorizontal
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: host.barEdge === "bottom" ? parent.top : undefined
            anchors.bottom: host.barEdge === "top" ? parent.bottom : undefined
            height: 1
            color: Config.sepColor
        }

        Rectangle {
            visible: !host.isHorizontal
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: host.barEdge === "right" ? parent.left : undefined
            anchors.right: host.barEdge === "left" ? parent.right : undefined
            width: 1
            color: Config.sepColor
        }

        Item {
            id: clockItem
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            z: 10

            implicitWidth: clockOneLine.implicitWidth + 14
            implicitHeight: clockOneLine.implicitHeight + 8

            property string clockText: TimeService.format("hh:mm")

            Timer {
                interval: 30000
                running: true
                repeat: true
                onTriggered: clockItem.clockText = TimeService.format("hh:mm")
            }

            Bloom {
                id: clockBloom
            }

            Text {
                id: clockOneLine
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -1
                text: clockItem.clockText
                color: clockMouse.containsMouse ? Config.accentColor : Config.textColor
                font.family: Config.monoFont
                font.pixelSize: 12
                font.letterSpacing: 2
                font.weight: Font.Medium
                Behavior on color {
                    ColorAnimation {
                        duration: 180
                    }
                }
            }

            Timer {
                id: clockTipDelay
                interval: 320
                onTriggered: {
                    const p = clockItem.mapToItem(null, clockItem.width / 2, clockItem.height / 2);
                    host.showTooltip("Calendar", p.x, p.y);
                }
            }

            MouseArea {
                id: clockMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: {
                    clockBloom.fire(mouseX, mouseY);
                    clockTipDelay.restart();
                }
                onExited: {
                    clockTipDelay.stop();
                    host.hideTooltip("Calendar");
                }
                onClicked: {
                    clockTipDelay.stop();
                    host.hideTooltip("Calendar");
                    calendarWindow.visible = !calendarWindow.visible;
                }
            }
        }

        GridLayout {
            anchors.fill: parent
            anchors.leftMargin: host.isHorizontal ? 8 : 0
            anchors.rightMargin: host.isHorizontal ? 8 : 0
            anchors.topMargin: host.isHorizontal ? 0 : 8
            anchors.bottomMargin: host.isHorizontal ? 0 : 8
            flow: host.isHorizontal ? GridLayout.LeftToRight : GridLayout.TopToBottom
            rowSpacing: 2
            columnSpacing: 2
            columns: host.isHorizontal ? -1 : 1
            rows: host.isHorizontal ? 1 : -1

            Module {
                host: bar.host
                imageSource: "file://" + Quickshell.env("HOME") + "/.config/quickshell/assets/ydot.svg"
                tooltip: "Menu"
                onActivated: LauncherService.show()
            }

            Separator {
                host: bar.host
            }

            Repeater {
                model: host.existingWs.length
                delegate: Workspace {
                    required property int index
                    host: bar.host
                    wsId: host.existingWs[index]
                    label: host.existingWs[index]
                    active: host.activeWs === host.existingWs[index]
                    present: true
                    onActivated: Hyprland.executeCommand("workspace " + host.existingWs[index])
                }
            }

            Separator {
                host: bar.host
            }

            Item {
                id: musicItem
                readonly property bool present: host.isHorizontal && MprisService.anyPlaying && MprisService.title !== "Unknown"
                visible: present || musicAnimW > 0.5
                Layout.preferredWidth: musicAnimW
                Layout.preferredHeight: 20
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 2

                property real musicAnimW: present ? musicContent.width + 24 : 0
                Behavior on musicAnimW {
                    NumberAnimation {
                        duration: 220
                        easing.type: Easing.OutCubic
                    }
                }

                readonly property string tipText: MprisService.artist !== "Unknown" ? MprisService.title + " - " + MprisService.artist : MprisService.title

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: Config.accentColor
                    clip: true
                    opacity: musicMouse.containsMouse ? 1.0 : 0.9
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 180
                        }
                    }

                    Row {
                        id: musicContent
                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: String.fromCodePoint(0xF001)
                            color: Config.textReverseColor
                            font.family: Config.font
                            font.pixelSize: 9
                            font.weight: Font.Medium
                        }

                        Text {
                            id: musicLabel
                            anchors.verticalCenter: parent.verticalCenter
                            readonly property int maxChars: 20
                            readonly property bool isTitleTruncated: MprisService.title.length > maxChars
                            text: isTitleTruncated ? MprisService.title.slice(0, maxChars - 2) + ".." : MprisService.title
                            color: Config.textReverseColor
                            font.family: Config.monoFont
                            font.pixelSize: 10
                            font.weight: Font.Medium
                        }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        height: parent.height
                        width: 40
                        radius: parent.radius
                        visible: musicLabel.isTitleTruncated
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop {
                                position: 0.0
                                color: Qt.rgba(Config.accentColor.r, Config.accentColor.g, Config.accentColor.b, 0)
                            }
                            GradientStop {
                                position: 0.6
                                color: Config.accentColor
                            }
                            GradientStop {
                                position: 1.0
                                color: Config.accentColor
                            }
                        }
                    }
                }

                Timer {
                    id: musicTipDelay
                    interval: 320
                    onTriggered: {
                        const p = musicItem.mapToItem(null, musicItem.width / 2, musicItem.height / 2);
                        host.showTooltip(musicItem.tipText, p.x, p.y);
                    }
                }

                MouseArea {
                    id: musicMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    cursorShape: Qt.PointingHandCursor
                    onEntered: musicTipDelay.restart()
                    onExited: {
                        musicTipDelay.stop();
                        host.hideTooltip(musicItem.tipText);
                    }
                    onClicked: e => {
                        musicTipDelay.stop();
                        host.hideTooltip(musicItem.tipText);
                        if (e.button === Qt.RightButton)
                            MprisService.next();
                        else if (e.button === Qt.MiddleButton)
                            MprisService.previous();
                        else
                            MprisService.playPause();
                    }
                }
            }

            Item {
                Layout.fillWidth: host.isHorizontal
                Layout.fillHeight: !host.isHorizontal
            }

            Item {
                id: trayArea
                Layout.preferredWidth: drawer.width + 28
                Layout.preferredHeight: 28
                Layout.alignment: Qt.AlignVCenter

                property bool isOpen: false
                property bool hasItems: TrayService.hasItems

                TrayMenu {
                    id: sharedMenu
                    visible: false
                }

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 0

                    Row {
                        id: drawer
                        clip: true
                        width: trayArea.isOpen ? drawer.implicitWidth : 0
                        height: 24
                        opacity: trayArea.isOpen ? 1 : 0
                        visible: trayArea.hasItems
                        spacing: 0

                        Behavior on width {
                            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                        }
                        Behavior on opacity {
                            NumberAnimation { duration: 150 }
                        }

                        Repeater {
                            model: TrayService.items

                            delegate: Item {
                                required property var modelData
                                implicitWidth: 24
                                implicitHeight: 24

                                Image {
                                    anchors.centerIn: parent
                                    width: 14; height: 14
                                    source: modelData.icon
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                    sourceSize: Qt.size(32, 32)
                                    smooth: true
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: e => {
                                        if (e.button === Qt.RightButton && modelData.hasMenu) {
                                            var g = parent.mapToGlobal(0, parent.height);
                                            sharedMenu.rootMenuHandle = modelData.menu;
                                            sharedMenu.anchorX = g.x;
                                            sharedMenu.anchorY = g.y + 5;
                                            sharedMenu.open();
                                        } else if (e.button === Qt.RightButton) {
                                            modelData.secondaryActivate()
                                        } else {
                                            modelData.activate()
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        implicitWidth: 28
                        implicitHeight: 28

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 3
                            radius: width / 2
                            color: mouse.containsMouse ? Qt.rgba(Config.textColor.r, Config.textColor.g, Config.textColor.b, 0.07) : "transparent"
                            Behavior on color { ColorAnimation { duration: 180 } }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "󰅁"
                            color: Config.textColor
                            font.family: Config.font
                            font.pixelSize: 18
                            visible: trayArea.hasItems
                            scale: trayArea.isOpen ? -1 : 1
                            Behavior on scale {
                                NumberAnimation { duration: 200; easing.type: Easing.OutBack }
                            }
                        }

                        MouseArea {
                            id: mouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: trayArea.isOpen = !trayArea.isOpen
                        }
                    }
                }
            }

            Module {
                host: bar.host
                glyph: "󰍛"
                tooltip: "System Monitor"
                fontWeight: Font.Medium
                onActivated: btopProc.running = true
            }

            Module {
                host: bar.host
                glyph: BluetoothService.systemIcon
                tooltip: {
                    if (!BluetoothService.isPowered)
                        return "Bluetooth off";
                    return BluetoothService.connectedDevicesCount > 0 ? "Bluetooth · " + BluetoothService.connectedDevicesCount + " connected" : "Bluetooth on";
                }
                color: BluetoothService.isPowered ? Config.textColor : Qt.alpha(Config.textColor, 0.35)
                fontWeight: Font.Medium
                onActivated: BluetoothService.launchBluetoothTui()
            }

            Module {
                host: bar.host
                glyph: NetworkService.systemIcon
                tooltip: NetworkService.statusText
                fontWeight: Font.Medium
                onActivated: NetworkService.launchImpala()
            }

            Module {
                host: bar.host
                glyph: AudioService.systemIcon
                tooltip: AudioService.muted ? "Audio muted · " + Math.round(AudioService.volume * 100) + "%" : "Audio " + Math.round(AudioService.volume * 100) + "%"
                color: AudioService.muted ? Qt.alpha(Config.textColor, 0.45) : Config.textColor
                fontWeight: Font.Medium
                onRightActivated: AudioService.toggleMute()
            }

            Module {
                host: bar.host
                glyph: BatteryService.getBatteryIcon()
                tooltip: {
                    let s = "Battery " + BatteryService.percentage + "%";
                    if (BatteryService.isCharging)
                        s += " (charging)";
                    return s;
                }
                color: BatteryService.percentage <= 10 ? Config.errorColor : BatteryService.percentage <= 20 ? Config.accentColor : Config.textColor
                fontWeight: Font.Medium
            }

            Module {
                host: bar.host
                glyph: "󰛊"
                tooltip: IdleService.caffeineEnabled ? "Keep awake (on)" : "Keep awake (off)"
                color: IdleService.caffeineEnabled ? Config.accentColor : Config.textColor
                onActivated: IdleService.toggleCaffeine()
            }

            Separator {
                host: bar.host
            }

            Module {
                host: bar.host
                glyph: NotificationService.dndEnabled ? String.fromCodePoint(0xF009B) : NotificationService.count > 0 ? String.fromCodePoint(0xF009A) : String.fromCodePoint(0xF009C)
                tooltip: {
                    if (NotificationService.dndEnabled)
                        return "Do Not Disturb";
                    return NotificationService.count > 0 ? NotificationService.count + " notifications" : "No notifications";
                }
                color: NotificationService.dndEnabled ? Qt.alpha(Config.textColor, 0.45) : Config.textColor
                fontWeight: Font.Medium
                onActivated: notifWindow.visible = !notifWindow.visible
                onRightActivated: NotificationService.toggleDnd()
            }

            Module {
                host: bar.host
                glyph: host.edgeArrow()
                tooltip: "Move bar"
                color: Config.subtextColor
                fontWeight: Font.Medium
                onActivated: host.cycleBarEdge()
            }
        }
    }

    CalendarWindow {
        id: calendarWindow
        visible: false
    }

    NotificationWindow {
        id: notifWindow
        visible: false
    }

    Process {
        id: btopProc
        command: ["kitty", "--title", "btop", "-e", "btop"]
        running: false
    }
}
