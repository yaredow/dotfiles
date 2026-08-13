pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string wifiInterface: ""
    property string activeSsid: ""
    property int activeSignal: 0
    property bool wifiEnabled: false
    property bool ethernetActive: false

    readonly property var _wifiIcons: ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"]

    readonly property string connectionKind: {
        if (ethernetActive) return "ethernet"
        if (wifiEnabled && activeSsid) return "wifi"
        return "disconnected"
    }

    function wifiIconFor(strength) {
        if (strength > 80) return _wifiIcons[4]
        if (strength > 60) return _wifiIcons[3]
        if (strength > 40) return _wifiIcons[2]
        if (strength > 20) return _wifiIcons[1]
        return _wifiIcons[0]
    }

    readonly property string systemIcon: {
        if (connectionKind === "ethernet") return "󰈀"
        if (connectionKind === "wifi") return wifiIconFor(activeSignal)
        if (!wifiEnabled) return "󰤮"
        return "󰤮"
    }

    readonly property string statusText: {
        if (!wifiEnabled)
            return "Off";
        if (activeSsid)
            return activeSsid;
        return "Disconnected";
    }

    function toggleWifi() {
        toggleProc.running = true;
    }

    function launchImpala() {
        impalaProc.running = true;
    }

    Process {
        id: impalaProc
        command: ["kitty", "--title", "impala", "-e", "impala"]
        running: false
    }

    Process {
        id: toggleProc
        command: root.wifiEnabled
            ? ["sh", "-c", "rfkill block wifi"]
            : ["sh", "-c", "rfkill unblock wifi"]
        onExited: statusRefresh.running = true
    }

    Process {
        id: interfaceProc
        command: ["sh", "-c", "iw dev 2>/dev/null | awk '/Interface/{print $2}' | head -1"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                const iface = data.trim();
                if (iface) {
                    root.wifiInterface = iface;
                    linkProc.running = true;
                    rfkillProc.running = true;
                }
            }
        }
    }

    Process {
        id: rfkillProc
        command: ["sh", "-c", "rfkill list wifi 2>/dev/null | grep -q 'Soft blocked: no' && echo enabled || echo disabled"]
        stdout: SplitParser {
            onRead: data => {
                root.wifiEnabled = (data.trim() === "enabled");
            }
        }
    }

    Process {
        id: linkProc
        command: ["sh", "-c", "iw dev " + root.wifiInterface + " link 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const output = text.trim();
                if (output.includes("Not connected")) {
                    root.activeSsid = "";
                    root.activeSignal = 0;
                } else {
                    const lines = output.split("\n");
                    var ssid = "";
                    var signal = 0;
                    for (var i = 0; i < lines.length; i++) {
                        const line = lines[i];
                        if (line.includes("SSID:"))
                            ssid = line.split("SSID:")[1].trim();
                        if (line.includes("signal:")) {
                            const match = line.match(/signal:\s*(-?\d+)/);
                            if (match)
                                signal = Math.min(100, Math.max(0, parseInt(match[1]) + 100));
                        }
                    }
                    root.activeSsid = ssid;
                    root.activeSignal = signal;
                }
            }
        }
    }

    Process {
        id: ethernetProc
        command: ["sh", "-c", "ip -4 route show default 2>/dev/null | head -1 | grep -qE 'dev (en|eth)' && echo yes || echo no"]
        stdout: SplitParser {
            onRead: data => {
                root.ethernetActive = (data.trim() === "yes");
            }
        }
    }

    Timer {
        id: statusRefresh
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            rfkillProc.running = true;
            ethernetProc.running = true;
            if (root.wifiInterface && root.wifiEnabled)
                linkProc.running = true;
        }
    }
}
