pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Singleton {
    id: root

    property bool caffeineEnabled: false

    readonly property bool displayInhibited: caffeineEnabled

    function toggleCaffeine() {
        caffeineEnabled = !caffeineEnabled
        if (caffeineEnabled) {
            inhibitorProc.command = [
                "systemd-inhibit",
                "--what=handle-lid-switch:sleep:idle",
                "--who=ydot",
                "--why=Keep awake",
                "--mode=block",
                "sleep", "infinity"
            ]
            inhibitorProc.running = true
        }
    }

    onCaffeineEnabledChanged: {
        if (!caffeineEnabled) {
            if (inhibitorProc.running) {
                killInhibitor.running = true
            }
            inhibitorProc.running = false
        }
    }

    Process {
        id: inhibitorProc
        running: false
    }

    Process {
        id: killInhibitor
        command: ["pkill", "-f", "systemd-inhibit.*ydot"]
        running: false
    }

    PanelWindow {
        id: inhibitorWindow
        visible: root.caffeineEnabled
        implicitWidth: 0
        implicitHeight: 0
        color: "transparent"
        mask: Region {}

        IdleInhibitor {
            enabled: root.caffeineEnabled
            window: inhibitorWindow
        }
    }
}
