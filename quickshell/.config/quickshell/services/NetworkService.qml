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

    readonly property string systemIcon: {
        if (!wifiEnabled)
            return String.fromCodePoint(0xF092E);
        if (activeSsid)
            return getWifiIcon(activeSignal);
        return String.fromCodePoint(0xF092B);
    }

    function getWifiIcon(signal) {
        if (signal > 80)
            return String.fromCodePoint(0xF0928);
        if (signal > 60)
            return String.fromCodePoint(0xF0925);
        if (signal > 40)
            return String.fromCodePoint(0xF0922);
        if (signal > 20)
            return String.fromCodePoint(0xF091F);
        return String.fromCodePoint(0xF092B);
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
        command: ["kitty", "-e", "impala"]
        running: false
    }

    Process {
        id: toggleProc
        property bool _targetState: false
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
        property string _lastIface: ""
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

    Timer {
        id: statusRefresh
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            rfkillProc.running = true;
            if (root.wifiInterface && root.wifiEnabled)
                linkProc.running = true;
        }
    }
}
