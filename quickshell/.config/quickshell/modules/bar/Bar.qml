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
        top: true
        bottom: host.barEdge === "bottom"
        left: true
        right: true
    }

    implicitHeight: Config.barHeight
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
            PropertyChanges { target: slabBg; opacity: 0.7 }
        }
        transitions: [
            Transition {
                to: "idle"
                NumberAnimation { property: "opacity"; duration: 6000; easing.type: Easing.OutQuart }
            },
            Transition {
                from: "idle"
                NumberAnimation { property: "opacity"; duration: 6000; easing.type: Easing.OutQuad }
            }
        ]

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: Config.sepColor
        }

        Item {
            id: clockItem
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            z: 10

            implicitWidth: clockOneLine.implicitWidth + 14
            implicitHeight: clockOneLine.implicitHeight + 8

            Bloom { id: clockBloom; }

            Text {
                id: clockOneLine
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -1
                text: TimeService.format("hh:mm")
                color: clockMouse.containsMouse ? Config.accentColor : Config.textColor
                font.family: Config.monoFont
                font.pixelSize: 14
                font.letterSpacing: 2
                font.weight: Config.fontWeight
                Behavior on color { ColorAnimation { duration: 180 } }
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
                onEntered: { clockBloom.fire(mouseX, mouseY); clockTipDelay.restart(); }
                onExited: { clockTipDelay.stop(); host.hideTooltip("Calendar"); }
                onClicked: {
                    clockTipDelay.stop();
                    host.hideTooltip("Calendar");
                    calendarWindow.visible = !calendarWindow.visible;
                }
            }
        }

        Item {
            id: musicItem
            readonly property bool present: MprisService.anyPlaying && MprisService.title !== "Unknown"
            readonly property real contentW: musicRow.width + 12
            property real openW: present ? contentW + 8 : 0
            Behavior on openW { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

            visible: present || openW > 0.5
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -1
            height: 16
            width: openW
            z: 10

            readonly property string tipText: MprisService.artist !== "Unknown"
                ? MprisService.title + " - " + MprisService.artist
                : MprisService.title

            Rectangle {
                id: musicPill
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(0, parent.width - 8)
                height: parent.height
                radius: height / 2
                color: Config.accentColor
                clip: true
                opacity: musicMouse.containsMouse ? 1.0 : 0.9
                Behavior on opacity { NumberAnimation { duration: 180 } }

                Row {
                    id: musicRow
                    anchors.centerIn: parent
                    spacing: 5

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: String.fromCodePoint(0xF001)
                        color: Config.textReverseColor
                        font.family: Config.font
                        font.pixelSize: 11
                    }

                    Text {
                        id: musicLabel
                        anchors.verticalCenter: parent.verticalCenter
                        readonly property int maxChars: 20
                        readonly property bool truncated: MprisService.title.length > maxChars
                        text: truncated
                            ? MprisService.title.slice(0, maxChars - 2) + ".."
                            : MprisService.title
                        color: Config.textReverseColor
                        font.family: Config.monoFont
                        font.pixelSize: 11
                        font.weight: Config.fontWeight
                    }
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: parent.height
                    width: 40
                    radius: parent.radius
                    visible: musicLabel.truncated
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: Qt.rgba(Config.accentColor.r, Config.accentColor.g, Config.accentColor.b, 0) }
                        GradientStop { position: 0.6; color: Config.accentColor }
                        GradientStop { position: 1.0; color: Config.accentColor }
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
                onExited: { musicTipDelay.stop(); host.hideTooltip(musicItem.tipText); }
                onClicked: (e) => {
                    musicTipDelay.stop();
                    host.hideTooltip(musicItem.tipText);
                    if (e.button === Qt.RightButton) MprisService.next();
                    else if (e.button === Qt.MiddleButton) MprisService.previous();
                    else MprisService.playPause();
                }
            }
        }

        GridLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10 + musicItem.openW
            flow: GridLayout.LeftToRight
            rowSpacing: 4
            columnSpacing: 4
            columns: -1
            rows: 1

            Module {
                host: bar.host
                glyph: String.fromCodePoint(0xF0349)
                tooltip: "Search apps"
                color: Config.accentColor
                fontFamily: Config.font
                onActivated: LauncherService.show()
            }

            Separator {}

            Repeater {
                model: 10
                delegate: Item {
                    required property int index
                    readonly property bool isLast: index === 9

                    Layout.preferredWidth: 20
                    Layout.preferredHeight: Config.barHeight
                    Layout.alignment: Qt.AlignVCenter

                    Workspace {
                        anchors.centerIn: parent
                        visible: !isLast
                        host: bar.host
                        wsId: index + 1
                        active: host.activeWs === (index + 1)
                        present: host.existingWs.indexOf(index + 1) !== -1
                        onActivated: Hyprland.executeCommand("workspace " + (index + 1));
                    }

                    Item {
                        anchors.centerIn: parent
                        visible: isLast
                        implicitWidth: 20
                        implicitHeight: Config.barHeight

                        Bloom { id: plusBloom }

                        Text {
                            anchors.centerIn: parent
                            anchors.verticalCenterOffset: -1
                            text: String.fromCodePoint(0xF0415)
                            color: plusMouse.containsMouse ? Config.accentColor : Qt.alpha(Config.textColor, 0.5)
                            font.family: Config.font
                            font.pixelSize: 16
                            font.weight: Font.Bold
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        MouseArea {
                            id: plusMouse
                            anchors.fill: parent
                            anchors.margins: -2
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: plusBloom.fire(mouseX, mouseY)
                            onClicked: Hyprland.executeCommand("workspace 10")
                        }
                    }
                }
            }

            Separator {}

            Item {
                Layout.fillWidth: true
            }

            Separator {}

            Module {
                host: bar.host
                glyph: "󰍛"
                tooltip: "CPU " + SystemMonitorService.cpuUsage + "%"
                color: SystemMonitorService.cpuUsage > 80 ? Config.accentColor : Config.textColor
                onActivated: monitorWindow.visible = !monitorWindow.visible
            }

            Module {
                host: bar.host
                glyph: BluetoothService.systemIcon
                tooltip: {
                    if (!BluetoothService.isPowered) return "Bluetooth off";
                    return BluetoothService.connectedDevicesCount > 0
                        ? "Bluetooth · " + BluetoothService.connectedDevicesCount + " connected"
                        : "Bluetooth on";
                }
                color: BluetoothService.isPowered ? Config.textColor : Qt.alpha(Config.textColor, 0.35)
            }

            Module {
                host: bar.host
                glyph: NetworkService.systemIcon
                tooltip: NetworkService.statusText
            }

            Module {
                host: bar.host
                glyph: AudioService.systemIcon
                tooltip: AudioService.muted
                    ? "Audio muted · " + Math.round(AudioService.volume * 100) + "%"
                    : "Audio " + Math.round(AudioService.volume * 100) + "%"
                onRightActivated: AudioService.toggleMute()
            }

            Module {
                host: bar.host
                glyph: BatteryService.getBatteryIcon()
                tooltip: {
                    let s = "Battery " + BatteryService.percentage + "%";
                    if (BatteryService.isCharging) s += " (charging)";
                    return s;
                }
                color: BatteryService.percentage <= 10 ? Config.errorColor : Config.textColor
            }

            Separator {}

            Module {
                host: bar.host
                glyph: NotificationService.dndEnabled
                    ? String.fromCodePoint(0xF009B)
                    : NotificationService.count > 0
                        ? String.fromCodePoint(0xF009A)
                        : String.fromCodePoint(0xF009C)
                tooltip: {
                    if (NotificationService.dndEnabled) return "Do Not Disturb";
                    return NotificationService.count > 0
                        ? NotificationService.count + " notifications"
                        : "No notifications";
                }
                color: NotificationService.dndEnabled
                    ? Qt.alpha(Config.textColor, 0.5)
                    : Config.textColor
                onActivated: notifWindow.visible = !notifWindow.visible
                onRightActivated: NotificationService.toggleDnd()
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
