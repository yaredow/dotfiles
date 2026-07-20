pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real volume: 0
    property bool muted: false

    readonly property string systemIcon: {
        if (muted || volume <= 0)
            return String.fromCodePoint(0xF0150);
        if (volume < 0.33)
            return String.fromCodePoint(0xF014F);
        if (volume < 0.67)
            return String.fromCodePoint(0xF014E);
        return String.fromCodePoint(0xF014D);
    }

    function setVolume(val) {
        sinkProc.command = ["pactl", "set-sink-volume", "@DEFAULT_SINK@", Math.round(val * 100) + "%"];
        sinkProc.running = true;
        volume = val;
    }

    function toggleMute() {
        muteProc.command = ["pactl", "set-sink-mute", "@DEFAULT_SINK@", muted ? "0" : "1"];
        muteProc.running = true;
        muted = !muted;
    }

    Process { id: sinkProc }
    Process { id: muteProc }

    Process {
        id: getVolumeProc
        running: true
        command: ["sh", "-c", "pactl get-sink-volume @DEFAULT_SINK@ | head -1 | sed 's/.* \\([0-9]*\\)%.*/\\1/'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseInt(text.trim());
                if (!isNaN(v)) root.volume = v / 100;
            }
        }
    }

    Process {
        id: getMuteProc
        command: ["sh", "-c", "pactl get-sink-mute @DEFAULT_SINK@ | awk '{print $2}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.muted = text.trim() === "yes"
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            getVolumeProc.running = true;
            getMuteProc.running = true;
        }
    }
}
