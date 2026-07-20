pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int cpuUsage: 0
    property int cpuTemp: 0
    property int gpuUsage: 0
    property int gpuTemp: 0
    property string gpuType: "unknown"
    property int ramUsage: 0
    property real ramUsed: 0
    property real ramTotal: 0
    property int diskUsage: 0
    property real diskUsed: 0
    property real diskTotal: 0
    property string networkDown: "0 B/s"
    property string networkUp: "0 B/s"
    property string uptime: "0h"

    Process {
        id: cpuProc
        command: ["sh", "-c", "grep '^cpu ' /proc/stat | awk '{print $2,$3,$4,$5,$6,$7,$8}'"]
        running: true
        property var prevIdle: 0
        property var prevTotal: 0

        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(" ");
                const idle = parseInt(parts[3]) + parseInt(parts[4]);
                const total = parts.reduce((sum, v) => sum + parseInt(v), 0);

                if (cpuProc.prevTotal > 0) {
                    const diffIdle = idle - cpuProc.prevIdle;
                    const diffTotal = total - cpuProc.prevTotal;
                    root.cpuUsage = Math.round(100 * (1 - diffIdle / diffTotal));
                }

                cpuProc.prevIdle = idle;
                cpuProc.prevTotal = total;
            }
        }
    }

    Process {
        id: tempProc
        command: ["sh", "-c", "cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo 0"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.cpuTemp = Math.round(parseInt(text.trim()) / 1000);
            }
        }
    }

    Process {
        id: ramProc
        command: ["sh", "-c", "awk '/^MemTotal:/ {t=$2} /^MemAvailable:/ {a=$2} END {printf \"%d %d %d\", t, t-a, (t-a)*100/t}' /proc/meminfo"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(" ");
                if (parts.length >= 3) {
                    root.ramTotal = Math.round(parseInt(parts[0]) / 1048576 * 10) / 10;
                    root.ramUsed = Math.round(parseInt(parts[1]) / 1048576 * 10) / 10;
                    root.ramUsage = parseInt(parts[2]);
                }
            }
        }
    }

    Process {
        id: diskProc
        command: ["sh", "-c", "df / --output=size,used,pcent | tail -1 | awk '{print $1,$2,$3}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(" ");
                if (parts.length >= 3) {
                    root.diskTotal = Math.round(parseInt(parts[0]) / 1048576 * 10) / 10;
                    root.diskUsed = Math.round(parseInt(parts[1]) / 1048576 * 10) / 10;
                    root.diskUsage = parseInt(parts[2].replace('%', ''));
                }
            }
        }
    }

    property var prevNetRx: 0
    property var prevNetTx: 0

    Process {
        id: netProc
        command: ["sh", "-c", "awk '/^[[:space:]]*[a-z]*:/ {rx+=$2; tx+=$10} END {print rx,tx}' /proc/net/dev"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(" ");
                if (parts.length >= 2) {
                    const rx = parseInt(parts[0]);
                    const tx = parseInt(parts[1]);

                    if (root.prevNetRx > 0) {
                        const drx = rx - root.prevNetRx;
                        const dtx = tx - root.prevNetTx;
                        root.networkDown = root.formatSpeed(drx);
                        root.networkUp = root.formatSpeed(dtx);
                    }

                    root.prevNetRx = rx;
                    root.prevNetTx = tx;
                }
            }
        }
    }

    Process {
        id: uptimeProc
        command: ["sh", "-c", "awk '{print int($1/3600)}' /proc/uptime"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const hours = parseInt(text.trim());
                root.uptime = hours + "h";
            }
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: {
            cpuProc.running = true;
            tempProc.running = true;
            netProc.running = true;
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: {
            ramProc.running = true;
            diskProc.running = true;
            uptimeProc.running = true;
        }
    }

    function formatSpeed(bytes) {
        if (bytes < 1024) return bytes + " B/s";
        if (bytes < 1048576) return (bytes / 1024).toFixed(1) + " KB/s";
        return (bytes / 1048576).toFixed(1) + " MB/s";
    }
}
