pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var accessPoints: []
    property var savedSsids: []
    property bool wifiEnabled: true
    property string wifiInterface: ""
    property string connectingSsid: ""
    property string connectivity: "unknown"
    property string activeSsid: ""
    property int activeSignal: 0
    property bool _portalNotified: false
    readonly property bool scanning: rescanProc.running
    readonly property bool hasCaptivePortal: {
        const activeNetwork = accessPoints.find(ap => ap.active === true);
        return !!activeNetwork && connectivity === "portal";
    }

    onConnectivityChanged: {
        if (connectivity === "portal" && !_portalNotified) {
            _portalNotified = true;
            openPortalProc.running = true;
        } else if (connectivity !== "portal") {
            _portalNotified = false;
        }
    }
    readonly property string systemIcon: {
        if (!wifiEnabled)
            return String.fromCodePoint(0xF092E);
        const activeNetwork = accessPoints.find(ap => ap.active === true);
        const signal = activeNetwork ? activeNetwork.signal : (activeSsid ? activeSignal : 0);
        if (activeNetwork || activeSsid) {
            if (hasCaptivePortal)
                return String.fromCodePoint(0xF092C);
            return getWifiIcon(signal);
        }
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
        const activeNetwork = accessPoints.find(ap => ap.active === true) || (activeSsid ? { ssid: activeSsid, signal: activeSignal } : null);
        if (activeNetwork) {
            if (hasCaptivePortal)
                return (activeNetwork.ssid || "Hidden Network") + " \u00B7 Portal";
            return activeNetwork.ssid || "Hidden Network";
        }
        return "On";
    }

    function openPortalBrowser() {
        openPortalProc.running = true;
    }

    function toggleWifi() {
        const cmd = wifiEnabled ? "off" : "on";
        toggleWifiProc.command = ["nmcli", "radio", "wifi", cmd];
        toggleWifiProc.running = true;
    }

    function scan() {
        if (!scanning)
            rescanProc.running = true;
    }

    function disconnect() {
        if (wifiInterface !== "") {
            console.log("Disconnecting interface: " + wifiInterface);
            disconnectProc.command = ["nmcli", "dev", "disconnect", wifiInterface];
            disconnectProc.running = true;
        }
    }

    function connect(ssid, password) {
        console.log("Attempting to connect to:", ssid);
        root.connectingSsid = ssid;

        if (password && password.length > 0) {
            connectProc.command = ["nmcli", "dev", "wifi", "connect", ssid, "password", password];
        } else {
            connectProc.command = ["nmcli", "dev", "wifi", "connect", ssid];
        }
        connectProc.running = true;
    }

    function forget(ssid) {
        console.log("Forgetting network: " + ssid);
        forgetProc.command = ["nmcli", "connection", "delete", "id", ssid];
        forgetProc.running = true;
    }

    function cleanUpBadConnection(ssid) {
        console.warn("Connection failed. Removing invalid profile for: " + ssid);
        forget(ssid);
    }

    Process {
        id: connectProc

        stdout: SplitParser {
            onRead: data => console.log("[Wifi] " + data)
        }
        stderr: SplitParser {
            onRead: data => console.error("[Wifi Error] " + data)
        }

        onExited: code => {
            if (code !== 0) {
                console.error("Connect command exited with code: " + code);
                portalCheckProc._failedSsid = root.connectingSsid;
                portalCheckProc.running = true;
            } else {
                console.log("Connected successfully!");
                root.connectingSsid = "";
                getSavedProc.running = true;
                getNetworksProc.running = true;
                connectivityProc.running = true;
            }
        }
    }

    Process {
        id: findInterfaceProc
        command: ["nmcli", "-g", "DEVICE,TYPE", "device"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                const lines = data.trim().split("\n");
                lines.forEach(line => {
                    const parts = line.split(":");
                    if (parts.length >= 2 && parts[1] === "wifi") {
                        root.wifiInterface = parts[0];
                    }
                });
            }
        }
    }

    Process {
        id: getActiveSsidProc
        command: ["sh", "-c", "nmcli -t -f ACTIVE,SIGNAL,SSID dev wifi | grep '^yes:' | head -1"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const line = text.trim();
                if (line.length > 0) {
                    const parts = line.split(":");
                    if (parts.length >= 3) {
                        root.activeSignal = parseInt(parts[1]) || 0;
                        root.activeSsid = parts[2] || "";
                    }
                }
            }
        }
    }

    Process {
        id: statusProc
        command: ["nmcli", "radio", "wifi"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                root.wifiEnabled = (data.trim() === "enabled");
                if (root.wifiEnabled)
                    getSavedProc.running = true;
                getNetworksProc.running = true;
            }
        }
    }

    Process {
        id: toggleWifiProc
        onExited: statusProc.running = true
    }

    Process {
        id: rescanProc
        command: ["nmcli", "dev", "wifi", "list", "--rescan", "yes"]
        onExited: getNetworksProc.running = true
    }

    Process {
        id: disconnectProc
        onExited: getNetworksProc.running = true
    }

    Process {
        id: forgetProc
        onExited: {
            getSavedProc.running = true;
            getNetworksProc.running = true;
        }
    }

    Timer {
        interval: 10000
        running: root.wifiEnabled
        repeat: true
        onTriggered: {
            getActiveSsidProc.running = true;
            getSavedProc.running = true;
            getNetworksProc.running = true;
            connectivityProc.running = true;
        }
    }

    Process {
        id: connectivityProc
        command: ["nmcli", "-g", "CONNECTIVITY", "general"]
        running: true
        stdout: SplitParser {
            onRead: data => root.connectivity = data.trim().toLowerCase()
        }
    }

    Process {
        id: openPortalProc
        command: ["xdg-open", "http://detectportal.firefox.com/"]
        stderr: SplitParser {
            onRead: data => console.error("[Wifi:Portal] " + data)
        }
    }

    Process {
        id: portalCheckProc
        property string _failedSsid: ""
        command: ["nmcli", "-g", "CONNECTIVITY", "general"]

        stdout: SplitParser {
            onRead: data => {
                const conn = data.trim().toLowerCase();
                root.connectivity = conn;
                if (conn === "none" || conn === "unknown") {
                    if (portalCheckProc._failedSsid !== "")
                        root.cleanUpBadConnection(portalCheckProc._failedSsid);
                } else {
                    console.log("[Wifi] Captive portal detected (" + conn + "), keeping profile");
                }
            }
        }

        onExited: {
            portalCheckProc._failedSsid = "";
            root.connectingSsid = "";
            getSavedProc.running = true;
            getNetworksProc.running = true;
        }
    }

    Process {
        id: getSavedProc
        command: ["nmcli", "-g", "NAME,TYPE", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                var savedList = [];
                lines.forEach(line => {
                    const parts = line.split(":");
                    if (parts.length >= 2 && parts[1] === "802-11-wireless") {
                        savedList.push(parts[0]);
                    }
                });
                root.savedSsids = savedList;
            }
        }
    }

    Process {
        id: getNetworksProc
        command: ["nmcli", "-g", "IN-USE,SIGNAL,SSID,SECURITY,BSSID,CHAN,RATE", "dev", "wifi", "list", "--rescan", "yes"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                var tempParams = [];
                const seen = new Set();

                lines.forEach(line => {
                    if (line.length < 5)
                        return;
                    const parts = line.split(":");
                    if (parts.length < 7)
                        return;

                    const inUse = parts[0] === "*";
                    const signal = parseInt(parts[1]) || 0;
                    const ssid = parts[2];
                    const security = parts[3];
                    const bssid = parts[4];
                    const channel = parts[5];
                    const rate = parts[6];

                    if (!ssid)
                        return;
                    if (seen.has(ssid))
                        return;
                    seen.add(ssid);

                    const isSaved = root.savedSsids.includes(ssid);

                    tempParams.push({
                        ssid: ssid,
                        signal: signal,
                        active: inUse,
                        secure: security.length > 0,
                        securityType: security || "Open",
                        saved: isSaved,
                        bssid: bssid,
                        channel: channel,
                        rate: rate
                    });
                });

                tempParams.sort((a, b) => {
                    if (a.active)
                        return -1;
                    if (b.active)
                        return 1;
                    if (a.saved && !b.saved)
                        return -1;
                    if (!a.saved && b.saved)
                        return 1;
                    return b.signal - a.signal;
                });

                root.accessPoints = tempParams;
            }
        }
    }
}
