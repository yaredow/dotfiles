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

    readonly property var _chargingIcons: ["󰢜", "󰂆", "󰂇", "󰂈", "󰢝", "󰂉", "󰢞", "󰂊", "󰂋", "󰂅"]
    readonly property var _defaultIcons:  ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]

    readonly property int _iconIndex: mainBattery
        ? Math.max(0, Math.min(9, Math.floor(mainBattery.percentage * 10)))
        : 0

    readonly property bool _batteryPresent: mainBattery && mainBattery.isPresent
    readonly property bool _isFullyCharged: state === UPowerDeviceState.FullyCharged
    readonly property bool _isPendingCharge: state === UPowerDeviceState.PendingCharge
    readonly property bool _thresholdActive: {
        if (!_batteryPresent || UPower.onBattery) return false
        if (_isPendingCharge) return true
        if (_isFullyCharged && mainBattery.percentage < 0.99) return true
        if (!isCharging || mainBattery.percentage >= 0.99) return false
        var rate = mainBattery["chargeRate"]
        var ttf = mainBattery["timeToFull"]
        if (rate !== undefined && Number(rate) <= 0.2) return true
        if (ttf !== undefined && Number(ttf) >= 8 * 60 * 60) return true
        return false
    }

    function getBatteryIcon() {
        if (!_batteryPresent) return ""
        if (_thresholdActive) return _defaultIcons[_iconIndex]
        if (_isFullyCharged) return "󰂅"
        if (!UPower.onBattery) return _chargingIcons[_iconIndex]
        return _defaultIcons[_iconIndex]
    }
}
