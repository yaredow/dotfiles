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

    readonly property bool isCharging: state === UPowerDeviceState.Charging || state === UPowerDeviceState.FullyCharged

    property var mainBattery: null

    Instantiator {
        model: UPower.devices

        delegate: QtObject {
            required property var modelData

            Component.onCompleted: checkDevice()

            function checkDevice() {
                if (modelData && modelData.isLaptopBattery) {
                    root.mainBattery = modelData
                }
            }
        }
    }

    function getBatteryIcon() {
        if (state === UPowerDeviceState.Charging || state === UPowerDeviceState.FullyCharged) return String.fromCodePoint(0xF0084)

        const p = percentage
        if (p >= 90) return String.fromCodePoint(0xF0079)
        if (p >= 60) return String.fromCodePoint(0xF0080)
        if (p >= 40) return String.fromCodePoint(0xF007E)
        if (p >= 10) return String.fromCodePoint(0xF007C)
        return String.fromCodePoint(0xF007A)
    }
}
