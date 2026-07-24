import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.config
import "./modules/bar/"
import "./modules/notifications/"
import "./components/"
import "./modules/screenshot/"
import "./modules/power/"
import "./modules/osd/"

ShellRoot {
    id: root

    property bool screenshotActive: false

    BarHost {
        id: host
    }

    Bar {
        host: host
    }

    TooltipOverlay {
        host: host
    }

    NotificationOverlay {}

    IpcHandler {
        target: "launcher"
        function toggle(): void {
            LauncherService.toggle();
        }
    }

    Loader {
        id: launcherLoader

        property bool _shown: LauncherService.visible
        property bool _keepAlive: false

        active: _shown || _keepAlive
        source: "./modules/launcher/Launcher.qml"

        on_ShownChanged: {
            if (!_shown) {
                _keepAlive = true;
                launcherExitTimer.restart();
            }
        }

        Timer {
            id: launcherExitTimer
            interval: Config.animDurationLong
            onTriggered: launcherLoader._keepAlive = false
        }
    }

    Loader {
        id: settingsLoader

        property bool _shown: SettingsService.panelVisible
        property bool _keepAlive: false

        active: _shown || _keepAlive
        source: "./modules/settings/SettingsPanel.qml"

        on_ShownChanged: {
            if (!_shown) {
                _keepAlive = true;
                settingsExitTimer.restart();
            }
        }

        Timer {
            id: settingsExitTimer
            interval: Config.animDurationLong
            onTriggered: settingsLoader._keepAlive = false
        }
    }

    Loader {
        id: lockLoader
        active: LockService.locked
        source: "./modules/lock/LockScreen.qml"
    }

    Loader {
        id: keybindsLoader

        property bool _shown: false
        property bool _keepAlive: false

        active: _shown || _keepAlive
        source: "./modules/keybinds/KeybindsOverlay.qml"

        on_ShownChanged: {
            if (!_shown) {
                _keepAlive = true;
                keybindsExitTimer.restart();
            }
        }

        onStatusChanged: {
            if (status === Loader.Ready && _shown)
                item.showing = true;
        }

        Connections {
            target: keybindsLoader.item
            enabled: keybindsLoader.status === Loader.Ready

            function onShowingChanged() {
                if (keybindsLoader.item && !keybindsLoader.item.showing)
                    keybindsLoader._shown = false;
            }
        }

        Timer {
            id: keybindsExitTimer
            interval: Config.animDurationLong
            onTriggered: keybindsLoader._keepAlive = false
        }
    }

    IpcHandler {
        target: "settings"
        function toggle(): void {
            SettingsService.toggle();
        }
    }

    IpcHandler {
        target: "keybinds"
        function toggle(): void {
            keybindsLoader._shown = !keybindsLoader._shown;
        }
    }

    IpcHandler {
        target: "power"
        function open(): void {
            PowerService.showOverlay();
        }
        function action(actionId: string): void {
            PowerService.executeAction(actionId);
        }
    }

    IpcHandler {
        target: "osd"
        function volumeUp(): void {
            AudioService.increaseVolume();
            OsdService.showVolume(AudioService.volume, AudioService.muted);
        }
        function volumeDown(): void {
            AudioService.decreaseVolume();
            OsdService.showVolume(AudioService.volume, AudioService.muted);
        }
        function volumeMute(): void {
            AudioService.toggleMute();
            OsdService.showVolume(AudioService.volume, AudioService.muted);
        }
        function brightnessUp(): void {
            BrightnessService.increaseBrightness();
            OsdService.showBrightness(BrightnessService.brightness);
        }
        function brightnessDown(): void {
            BrightnessService.decreaseBrightness();
            OsdService.showBrightness(BrightnessService.brightness);
        }
    }

    Loader {
        id: powerLoader
        active: PowerService.overlayVisible
        source: "./modules/power/PowerOverlay.qml"
    }

    Loader {
        id: osdLoader
        active: OsdService.visible
        source: "./modules/osd/OsdOverlay.qml"
    }

    Loader {
        id: screenshotLoader
        active: root.screenshotActive
        source: "./modules/screenshot/ScreenshotManager.qml"

        onStatusChanged: {
            if (status === Loader.Ready) {
                screenshotLoader.item.startCapture();
            }
        }

        Connections {
            target: screenshotLoader.item
            enabled: screenshotLoader.status === Loader.Ready

            function onActiveChanged() {
                if (screenshotLoader.item && !screenshotLoader.item.active) {
                    root.screenshotActive = false;
                }
            }
        }
    }

    IpcHandler {
        target: "screenshot"
        function start(): void {
            root.screenshotActive = true;
        }
        function cancel(): void {
            if (screenshotLoader.item) screenshotLoader.item.cancelCapture();
        }
        function confirm(): void {
            if (screenshotLoader.item) screenshotLoader.item.confirmSelection();
        }
        function edit(): void {
            if (screenshotLoader.item) screenshotLoader.item.editSelection();
        }
    }

    Loader {
        id: clipboardLoader

        property bool _shown: ClipboardService.visible
        property bool _keepAlive: false

        active: _shown || _keepAlive
        source: "./modules/clipboard/ClipboardHistory.qml"

        on_ShownChanged: {
            if (!_shown) {
                _keepAlive = true;
                clipboardExitTimer.restart();
            }
        }

        Timer {
            id: clipboardExitTimer
            interval: Config.animDurationLong
            onTriggered: clipboardLoader._keepAlive = false
        }
    }

    IpcHandler {
        target: "clipboard"
        function toggle(): void {
            ClipboardService.toggle();
        }
    }
}
