pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

Singleton {
    id: root

    function getState(path, fallback) {
        return StateService.get(path, fallback)
    }
    function setState(path, value) {
        StateService.set(path, value)
    }

    property real brightness: 1.0
    property int maxBrightness: 100
    property int currentBrightness: 100
    readonly property bool available: backlightDevice !== ""
    property string backlightDevice: ""
    readonly property int percentage: Math.round(brightness * 100)

    readonly property string icon: {
        if (brightness <= 0.1) return String.fromCodePoint(0xF00DE)
        if (brightness <= 0.3) return String.fromCodePoint(0xF00DF)
        if (brightness <= 0.6) return String.fromCodePoint(0xF00DD)
        return String.fromCodePoint(0xF00E0)
    }

    Component.onCompleted: { detectBacklight.running = true }

    Process {
        id: detectBacklight
        command: ["bash", "-c", "ls /sys/class/backlight/ 2>/dev/null | head -1"]
        stdout: SplitParser {
            onRead: data => {
                const device = data.trim()
                if (device !== "") {
                    root.backlightDevice = device
                    getMaxBrightness.running = true
                }
            }
        }
    }

    Process {
        id: getMaxBrightness
        command: ["bash", "-c", "cat /sys/class/backlight/" + root.backlightDevice + "/max_brightness 2>/dev/null"]
        stdout: SplitParser {
            onRead: data => {
                const max = parseInt(data.trim())
                if (!isNaN(max) && max > 0) {
                    root.maxBrightness = max
                    getCurrentBrightness.running = true
                }
            }
        }
    }

    Process {
        id: getCurrentBrightness
        command: ["bash", "-c", "cat /sys/class/backlight/" + root.backlightDevice + "/brightness 2>/dev/null"]
        stdout: SplitParser {
            onRead: data => {
                const current = parseInt(data.trim())
                if (!isNaN(current)) {
                    root.currentBrightness = current
                    root.brightness = current / root.maxBrightness
                }
            }
        }
    }

    Timer {
        interval: 2000
        running: root.available
        repeat: true
        onTriggered: getCurrentBrightness.running = true
    }

    function setBrightness(value) {
        const clamped = Math.max(0.05, Math.min(1.0, value))
        const absoluteValue = Math.round(clamped * maxBrightness)
        root.brightness = clamped
        root.currentBrightness = absoluteValue
        setBrightnessProc.command = ["brightnessctl", "set", absoluteValue.toString()]
        setBrightnessProc.running = true
    }

    function increaseBrightness() { setBrightness(brightness + 0.05) }
    function decreaseBrightness() { setBrightness(brightness - 0.05) }

    property real lastBrightness: 1.0

    function toggleBrightness() {
        if (brightness > 0.1) {
            lastBrightness = brightness
            setBrightness(0.05)
        } else {
            setBrightness(lastBrightness)
        }
    }

    Process { id: setBrightnessProc }
}
