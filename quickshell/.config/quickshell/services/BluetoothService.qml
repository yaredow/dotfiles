pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Bluetooth

Singleton {
    id: root

    property var adapter: Bluetooth?.defaultAdapter

    readonly property bool isPowered: (adapter && adapter.enabled) === true
    readonly property bool isDiscovering: (adapter && adapter.discovering) === true
    readonly property bool isDiscoverable: (adapter && adapter.discoverable) === true

    readonly property string systemIcon: {
        if (!isPowered) return "󰂲"
        if (devicesList.some(dev => dev.connected)) return "󰂱"
        return ""
    }

    readonly property var connectedDevices: devicesList.filter(dev => dev.connected)
    readonly property int connectedDevicesCount: connectedDevices.length

    readonly property string statusText: {
        if (!isPowered) return "Off"
        const count = connectedDevices.length
        if (count === 0) return "On"
        if (count === 1) {
            const dev = connectedDevices[0]
            return dev.alias || dev.name || "Unknown"
        }
        return count + " devices"
    }

    readonly property var devicesList: {
        if (!adapter || !adapter.devices) return []
        let list = Array.from(adapter.devices.values)
        return list.sort((a, b) => {
            if (a.connected && !b.connected) return -1
            if (!a.connected && b.connected) return 1
            const aKnown = a.paired || a.trusted
            const bKnown = b.paired || b.trusted
            if (aKnown && !bKnown) return -1
            if (!aKnown && bKnown) return 1
            const nameA = (a.alias || a.name || "").toLowerCase()
            const nameB = (b.alias || b.name || "").toLowerCase()
            return nameA.localeCompare(nameB)
        })
    }

    function togglePower() { if (adapter) adapter.enabled = !adapter.enabled }
    function toggleScan() {
        if (!adapter) return
        if (adapter.discovering) { adapter.discovering = false; scanTimer.stop() }
        else { adapter.discovering = true; scanTimer.restart() }
    }

    Timer {
        id: scanTimer
        interval: 10000
        repeat: false
        onTriggered: { if (root.adapter && root.adapter.discovering) root.adapter.discovering = false }
    }

    function toggleConnection(device) {
        if (!device) return
        if (device.connected) { device.disconnect(); return }
        if (device.state === BluetoothDeviceState.Connecting) return
        try { device.trusted = true } catch (e) {}
        if (!device.paired) { try { device.pair() } catch (e) {}; return }
        device.connect()
    }

    function toggleDiscoverable() { if (adapter) adapter.discoverable = !adapter.discoverable }
    function getIsConnecting(device) { return device && device.state === BluetoothDeviceState.Connecting }
    function forgetDevice(device) { if (device) device.forget() }

    function getDeviceIcon(device) {
        if (!device) return ""
        const iconProp = (device.icon || "").toLowerCase()
        const name = (device.name || device.alias || "").toLowerCase()
        const safeName = name || ""
        const audioKeywords = ["headset", "headphone", "airpod", "buds", "freebuds", "wh-", "wf-", "jbl", "audio", "soundcore"]
        if (iconProp.includes("headset") || iconProp.includes("audio") || audioKeywords.some(k => name.includes(k))) return ""
        if (iconProp.includes("mouse") || safeName.includes("mouse")) return "󰍽"
        if (iconProp.includes("keyboard") || safeName.includes("keyboard")) return ""
        if (iconProp.includes("phone") || safeName.includes("phone") || name.includes("android") || name.includes("iphone")) return ""
        if (iconProp.includes("gamepad") || iconProp.includes("joystick") || name.includes("controller")) return ""
        if (iconProp.includes("computer") || iconProp.includes("laptop") || name.includes("pc")) return " "
        if (iconProp.includes("tv") || safeName.includes("tv")) return " "
        return ""
    }

    // Backward compat aliases
    readonly property bool powered: isPowered
    readonly property var connectedNames: connectedDevices.map(d => d.alias || d.name || "Unknown")
    readonly property var adapter_obj: adapter
}
