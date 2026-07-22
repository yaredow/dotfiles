pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.config
import qs.services
import "../../components/"
import "../notifications/"
import "../systemMonitor/"
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

            Bloom {
                id: clockBloom
            }

            Text {
                id: clockOneLine
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -1
                text: TimeService.format("hh:mm")
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
            anchors.leftMargin: host.isHorizontal ? 10 : 0
            anchors.rightMargin: host.isHorizontal ? 10 : 0
            anchors.topMargin: host.isHorizontal ? 0 : 10
            anchors.bottomMargin: host.isHorizontal ? 0 : 10
            flow: host.isHorizontal ? GridLayout.LeftToRight : GridLayout.TopToBottom
            rowSpacing: 4
            columnSpacing: 4
            columns: host.isHorizontal ? -1 : 1
            rows: host.isHorizontal ? 1 : -1

            Module {
                host: bar.host
                glyph: "󰣇"
                tooltip: "Menu"
                color: Config.accentColor
                fontFamily: Config.font
                fontSize: 14
                fontWeight: Font.Medium
                onActivated: LauncherService.show()
            }

            Separator {
                host: bar.host
            }

            Repeater {
                model: 10
                delegate: Workspace {
                    required property int index
                    host: bar.host
                    wsId: index + 1
                    label: host.indexKanji(index + 1)
                    active: host.activeWs === (index + 1)
                    present: host.existingWs.indexOf(index + 1) !== -1
                    onActivated: Hyprland.executeCommand("workspace " + (index + 1))
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
                id: trayItem
                visible: TrayService.hasItems
                Layout.preferredWidth: childrenRect.width || 24
                Layout.preferredHeight: 20
                Layout.alignment: Qt.AlignVCenter

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Repeater {
                        model: TrayService.items

                        delegate: TrayItem {
                            required property var modelData
                            host: bar.host
                            trayItem: modelData
                        }
                    }
                }
            }

            Module {
                host: bar.host
                glyph: "󰍛"
                tooltip: "CPU " + SystemMonitorService.cpuUsage + "%"
                color: SystemMonitorService.cpuUsage > 80 ? Config.accentColor : Config.textColor
                fontSize: 12
                fontWeight: Font.Medium
                onActivated: monitorWindow.visible = !monitorWindow.visible
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
                fontSize: 12
                fontWeight: Font.Medium
            }

            Module {
                host: bar.host
                glyph: NetworkService.systemIcon
                tooltip: NetworkService.statusText
                fontSize: 12
                fontWeight: Font.Medium
            }

            Module {
                host: bar.host
                glyph: AudioService.systemIcon
                tooltip: AudioService.muted ? "Audio muted · " + Math.round(AudioService.volume * 100) + "%" : "Audio " + Math.round(AudioService.volume * 100) + "%"
                color: AudioService.muted ? Qt.alpha(Config.textColor, 0.45) : Config.textColor
                fontSize: 12
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
                fontSize: 12
                fontWeight: Font.Medium
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
                fontSize: 12
                fontWeight: Font.Medium
                onActivated: notifWindow.visible = !notifWindow.visible
                onRightActivated: NotificationService.toggleDnd()
            }

            Module {
                host: bar.host
                glyph: host.edgeArrow()
                tooltip: "Move bar"
                color: Config.subtextColor
                fontFamily: Config.font
                fontSize: 12
                fontWeight: Font.Medium
                onActivated: host.cycleBarEdge()
            }
        }
    }

    CalendarWindow {
        id: calendarWindow
        visible: false
    }

    SystemMonitorWindow {
        id: monitorWindow
        visible: false
    }

    NotificationWindow {
        id: notifWindow
        visible: false
    }
}
