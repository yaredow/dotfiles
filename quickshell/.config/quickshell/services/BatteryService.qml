pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.UPower

Singleton {
    id: root

    readonly property bool hasBattery: mainBattery !== null
    readonly property int percentage: mainBattery ? Math.round(mainBattery.percentage * 100) : 0
    readonly property int state: mainBattery ? mainBattery.state : UPowerDeviceState.Unknown
    readonly property bool isCharging: state === UPowerDeviceState.Charging

    property var mainBattery: null

    // Notification flags — reset once per discharge cycle
    property bool _notifiedLow: false
    property bool _notifiedCritical: false

    Instantiator {
        model: UPower.devices
        delegate: QtObject {
            required property var modelData
            Component.onCompleted: checkDevice()
            function checkDevice() {
                if (modelData && modelData.isLaptopBattery) root.mainBattery = modelData
            }
        }
    }

    function checkBattery() {
        if (!root.hasBattery || root.isCharging || root.state !== UPowerDeviceState.Discharging) {
            _notifiedLow = false;
            _notifiedCritical = false;
            return;
        }

        const p = root.percentage;

        if (p <= 10 && !_notifiedCritical) {
            _notifiedCritical = true;
            root.sendNotification("Critical Battery", "Battery at " + p + "% — plug in now!");
        }

        if (p <= 20 && !_notifiedLow) {
            _notifiedLow = true;
            root.sendNotification("Low Battery", "Battery at " + p + "% — time to charge.");
        }
    }

    function sendNotification(summary, body) {
        Quickshell.execDetached(["notify-send", "-u", "critical", "-t", "10000", summary, body]);
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.checkBattery()
    }

    Connections {
        target: UPower
        function onOnBatteryChanged() {
            root.checkBattery();
        }
    }

    function getBatteryIcon() {
        if (state === UPowerDeviceState.Charging) return "󰂄"
        const p = percentage
        if (p >= 90) return "󰁹"
        if (p >= 60) return "󰂀"
        if (p >= 40) return "󰁾"
        if (p >= 10) return "󰁼"
        return "󰁺"
    }
}
