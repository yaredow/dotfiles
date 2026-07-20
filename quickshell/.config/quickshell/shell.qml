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

ShellRoot {
    id: root

    BarHost { id: host }

    Bar {
        host: host
    }

    TooltipOverlay {
        host: host
    }

    NotificationOverlay {}

    IpcHandler {
        target: "launcher"
        function toggle(): void { LauncherService.toggle(); }
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

    GlobalShortcut {
        name: "app_launcher"
        description: "App Launcher"
        onPressed: LauncherService.toggle()
    }
}
