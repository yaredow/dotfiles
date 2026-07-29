pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Singleton {
    id: root

    // ---- Core volume (pactl — reliable, battle-tested) ----
    property real volume: 0
    property bool muted: false

    readonly property string systemIcon: {
        if (muted || volume <= 0) return ""
        if (volume >= 0.67) return ""
        if (volume >= 0.34) return ""
        return ""
    }

    readonly property string volumeLabel: {
        var p = Math.round(volume * 100)
        if (muted) return "Muted"
        if (p === 0) return "Silent"
        if (p >= 100) return "Max volume"
        if (p >= 85) return "Loud"
        if (p >= 70) return "High"
        if (p >= 50) return "Medium"
        if (p >= 30) return "Low"
        if (p >= 15) return "Quiet"
        return "Whisper"
    }

    function setVolume(val) {
        sinkProc.command = ["pactl", "set-sink-volume", "@DEFAULT_SINK@", Math.round(val * 100) + "%"]
        sinkProc.running = true
        volume = val
    }

    function increaseVolume() { setVolume(Math.min(1, volume + 0.05)) }
    function decreaseVolume() { setVolume(Math.max(0, volume - 0.05)) }

    function toggleMute() {
        muteProc.command = ["pactl", "set-sink-mute", "@DEFAULT_SINK@", muted ? "0" : "1"]
        muteProc.running = true
        muted = !muted
    }

    function setDefaultSink(node) {
        if (!node || !node.name) return
        Pipewire.preferredDefaultAudioSink = node
        var id = node.serial !== undefined ? node.serial : node.id
        if (id !== undefined) {
            defSinkProc.command = ["pactl", "set-default-sink", node.name]
            defSinkProc.running = true
        }
    }

    Process { id: sinkProc }
    Process { id: muteProc }
    Process { id: defSinkProc }

    Process {
        id: getVolumeProc
        running: true
        command: ["sh", "-c", "pactl get-sink-volume @DEFAULT_SINK@ | head -1 | sed 's/.* \\([0-9]*\\)%.*/\\1/'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseInt(text.trim())
                if (!isNaN(v)) root.volume = v / 100
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
            getVolumeProc.running = true
            getMuteProc.running = true
        }
    }

    // ---- Pipewire-powered device/stream lists (for the panel) ----
    readonly property var defaultSink: Pipewire.defaultAudioSink
    readonly property var nodes: Pipewire.nodes ? Pipewire.nodes.values : []

    readonly property var sinks: {
        var list = []
        for (var i = 0; i < nodes.length; i++) {
            var n = nodes[i]
            if (n && n.isSink && !n.isStream) list.push(n)
        }
        return list
    }

    readonly property var streams: {
        var list = []
        for (var i = 0; i < nodes.length; i++) {
            var n = nodes[i]
            if (!n || !n.isStream || !n.isSink) continue
            if (!n.audio) continue
            list.push(n)
        }
        return list
    }

    function nodeLabel(node) {
        if (!node) return ""
        var desc = node.description || node.nickname || node.name || ""
        return desc.replace(/\s+Output$/i, "").replace(/^Built-in Audio\s+/i, "")
    }

    function streamLabel(node) {
        if (!node) return ""
        var p = (node.properties || {})
        return p["application.name"] || node.description || node.name || "Unknown"
    }

    function isHeadphones(node) {
        if (!node) return false
        var blob = String([node.name, node.description || ""].join(" ")).toLowerCase()
        return blob.indexOf("headphone") !== -1 || blob.indexOf("headset") !== -1
    }

    function sinkIcon(node) {
        if (!node) return "󰓃"
        if (isHeadphones(node)) return "󰋋"
        var blob = String([node.name, node.description || ""].join(" ")).toLowerCase()
        if (blob.indexOf("bluetooth") !== -1) return "󰂯"
        if (blob.indexOf("hdmi") !== -1 || blob.indexOf("display") !== -1) return "󰍹"
        return "󰓃"
    }
}
