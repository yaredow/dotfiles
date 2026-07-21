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

    IpcHandler {
        target: "settings"
        function toggle(): void {
            SettingsService.toggle();
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

    Loader {
        id: powerLoader
        active: PowerService.overlayVisible
        source: "./modules/power/PowerOverlay.qml"
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
}
