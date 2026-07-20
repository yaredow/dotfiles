pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool locked: false

    function lock() {
        console.log("[Lock] Locking screen");
        lockProc.running = true;
        locked = true;
    }

    function unlock() {
        locked = false;
    }

    Process {
        id: lockProc
        command: ["bash", "-c", "loginctl lock-session || hyprctl dispatch exit"]
    }
}
