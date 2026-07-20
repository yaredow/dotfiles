pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Singleton {
    id: root

    property bool caffeineEnabled: false
    property bool dpmsEnabled: true

    readonly property bool mediaPlaying: false
    property bool systemInhibited: false

    function lock() { LockService.lock(); }
    function toggleCaffeine() { caffeineEnabled = !caffeineEnabled; }
    function dpmsOn() {}
    function dpmsOff() {}

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
