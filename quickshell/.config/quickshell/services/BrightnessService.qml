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

    property bool nightLightEnabled: getState("nightLight.enabled", false)
    property int nightLightTemperature: 4000
    property real nightLightIntensity: getState("nightLight.intensity", 0.5)
    readonly property string nightLightIcon: nightLightEnabled ? String.fromCodePoint(0xF0B4D) : String.fromCodePoint(0xF0B4E)

    Component.onCompleted: {
        detectBacklight.running = true
        ensureHyprsunsetRunning.running = true
    }

    Connections {
        target: StateService
        function onStateLoaded() {
            root.nightLightEnabled = root.getState("nightLight.enabled", false)
            root.nightLightIntensity = root.getState("nightLight.intensity", 0.5)
            root.updateTemperatureFromIntensity()
            applyStateTimer.restart()
        }
    }

    Timer {
        id: applyStateTimer
        interval: 1000
        onTriggered: {
            if (root.nightLightEnabled) {
                root.applyNightLight()
                return
            }
            root.disableNightLight()
        }
    }

    function updateTemperatureFromIntensity() {
        nightLightTemperature = Math.round(2500 + (nightLightIntensity * 3000))
    }

    function updateIntensityFromTemperature() {
        nightLightIntensity = (nightLightTemperature - 2500) / 3000
    }

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

    function toggleNightLight() {
        if (nightLightEnabled) disableNightLight()
        else enableNightLight()
    }

    function enableNightLight() {
        nightLightEnabled = true
        setState("nightLight.enabled", true)
        applyNightLight()
    }

    function disableNightLight() {
        nightLightEnabled = false
        setState("nightLight.enabled", false)
        disableNightLightProc.running = true
    }

    function setNightLightIntensity(intensity) {
        nightLightIntensity = Math.max(0.0, Math.min(1.0, intensity))
        updateTemperatureFromIntensity()
        setState("nightLight.intensity", nightLightIntensity)
        if (nightLightEnabled) applyNightLight()
    }

    function setNightLightTemperature(temp) {
        nightLightTemperature = Math.max(2500, Math.min(5500, temp))
        updateIntensityFromTemperature()
        setState("nightLight.intensity", nightLightIntensity)
        if (nightLightEnabled) applyNightLight()
    }

    function applyNightLight() {
        enableNightLightProc.command = ["hyprctl", "hyprsunset", "temperature", nightLightTemperature.toString()]
        enableNightLightProc.running = true
    }

    Process { id: setBrightnessProc }

    Process {
        id: ensureHyprsunsetRunning
        command: ["bash", "-c",
            "if ! pgrep -x hyprsunset >/dev/null 2>&1; then hyprsunset & disown; sleep 0.5; fi"]
        onExited: {
            if (!StateService.isLoading && root.nightLightEnabled) {
                root.applyNightLight()
            }
        }
    }

    Process {
        id: enableNightLightProc
        stdout: SplitParser {
            onRead: data => console.log("[Brightness] Enable night light response:", data)
        }
        stderr: SplitParser {
            onRead: data => {
                if (data.includes("error") || data.includes("failed")) {
                    restartAndEnableProc.running = true
                }
            }
        }
    }

    Process {
        id: restartAndEnableProc
        command: ["bash", "-c",
            "pkill -x hyprsunset 2>/dev/null; sleep 0.2; hyprsunset & disown; sleep 0.5; hyprctl hyprsunset temperature " + root.nightLightTemperature]
    }

    Process {
        id: disableNightLightProc
        command: ["hyprctl", "hyprsunset", "identity"]
    }
}
