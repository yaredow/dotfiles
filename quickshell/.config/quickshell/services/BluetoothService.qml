pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool isPowered: false
    property var connectedDevicesList: []

    readonly property var connectedDevices: connectedDevicesList
    readonly property int connectedDevicesCount: connectedDevices.length
    readonly property bool isDiscovering: false
    readonly property bool isDiscoverable: false

    readonly property string systemIcon: {
        if (!isPowered)
            return String.fromCodePoint(0xF00B2);

        if (connectedDevices.some(dev => dev.connected))
            return String.fromCodePoint(0xF00B1);

        return String.fromCodePoint(0xF0293);
    }

    readonly property string statusText: {
        if (!isPowered)
            return "Off";

        const count = connectedDevices.length;

        if (count === 0)
            return "On";

        if (count === 1) {
            const dev = connectedDevices[0];
            return dev.alias || dev.name || "Unknown";
        }

        return count + " devices";
    }

    function refresh() {
        checkPowered.running = true;
        checkConnected.running = true;
    }

    function togglePower() {
        togglePowerProc.running = true;
    }

    function toggleScan() {}
    function toggleConnection(device) {}
    function toggleDiscoverable() {}
    function getIsConnecting(device) { return false; }
    function forgetDevice(device) {}
    function getDeviceIcon(device) { return String.fromCodePoint(0xF0293); }

    Process {
        id: togglePowerProc
        property bool targetState: !root.isPowered
        command: root.targetState
            ? ["sh", "-c", "bluetoothctl power on"]
            : ["sh", "-c", "bluetoothctl power off"]
        onExited: root.refresh()
    }

    Process {
        id: checkPowered
        running: true
        command: ["sh", "-c", "bluetoothctl show | grep 'Powered:' | awk '{print $2}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.isPowered = text.trim() === "yes";
            }
        }
    }

    Process {
        id: checkConnected
        running: true
        command: ["sh", "-c", "bluetoothctl devices Connected | sed 's/^Device [^ ]* //'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const names = text.trim();
                const list = names.length > 0 ? names.split('\n') : [];
                root.connectedDevicesList = list.map(name => ({
                    connected: true,
                    alias: name,
                    name: name
                }));
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    // --- BACKWARD COMPATIBILITY ---
    readonly property bool powered: isPowered
    readonly property var connectedNames: connectedDevices.map(d => d.alias || d.name || "Unknown")
}
