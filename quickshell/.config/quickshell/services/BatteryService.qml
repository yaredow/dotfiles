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
