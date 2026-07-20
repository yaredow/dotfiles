pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config
import qs.services
import "../../components/"
import "../notifications/"
import "../systemMonitor/"
import "../calendar/"

Scope {
    id: root

    readonly property int gapIn: 5
    readonly property int gapOut: 15

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData

            property bool enableAutoHide: Config.barAutoHide

            WlrLayershell.namespace: "qs_modules"

            implicitHeight: StateService.get("bar.height", 30)
            color: "transparent"
            screen: modelData

            exclusionMode: enableAutoHide ? ExclusionMode.Ignore : ExclusionMode.Normal

            exclusiveZone: enableAutoHide ? 0 : height

            anchors {
                top: true
                left: true
                right: true
            }

            margins.top: {
                if (WindowManagerService.anyModuleOpen || !enableAutoHide || mouseSensor.hovered)
                    return 0;

                return (-1 * (height - 1));
            }

            Behavior on margins.top {
                NumberAnimation {
                    duration: Config.animDuration
                    easing.type: Easing.OutExpo
                }
            }

            HoverHandler {
                id: mouseSensor
            }

            Rectangle {
                id: barContent
                anchors.fill: parent
                color: Config.backgroundTransparentColor

                RowLayout {
                    anchors.left: parent.left
                    anchors.leftMargin: root.gapOut
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: root.gapIn

                    CalendarButton {}
                    SystemMonitorButton {}
                    ActiveWindow {}
                }

                RowLayout {
                    anchors.centerIn: parent
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: root.gapIn

                    Workspaces {}
                }

                RowLayout {
                    anchors.right: parent.right
                    anchors.rightMargin: root.gapOut
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: root.gapIn

                    TrayWidget {}

                    Row {
                        spacing: 10
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: NetworkService.systemIcon
                            font.family: Config.font
                            font.pixelSize: Config.fontSizeNormal
                            font.weight: Config.fontWeight
                            color: Config.textColor
                            ToolTip.visible: hovered
                            ToolTip.text: NetworkService.statusText
                            ToolTip.delay: 300
                            HoverHandler {}
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: BluetoothService.systemIcon
                            font.family: Config.font
                            font.pixelSize: Config.fontSizeNormal
                            font.weight: Config.fontWeight
                            color: Config.textColor
                            ToolTip.visible: hovered
                            ToolTip.text: BluetoothService.statusText
                            ToolTip.delay: 300
                            HoverHandler {}
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: BatteryService.hasBattery
                            text: BatteryService.getBatteryIcon()
                            font.family: Config.font
                            font.pixelSize: Config.fontSizeNormal
                            font.weight: Config.fontWeight
                            color: BatteryService.isCharging ? Config.successColor : (BatteryService.percentage < 20 ? Config.warningColor : Config.textColor)
                            ToolTip.visible: hovered
                            ToolTip.text: BatteryService.percentage + "%" + (BatteryService.isCharging ? " (charging)" : "")
                            ToolTip.delay: 300
                            HoverHandler {}
                        }
                    }

                    NotificationButton {}
                }
            }
        }
    }
}
