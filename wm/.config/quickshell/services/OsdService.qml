pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root

    property bool visible: false
    property string type: "volume"
    property real value: 0
    property bool muted: false

    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: root.visible = false
    }

    function showVolume(vol: real, isMuted: bool) {
        root.type = "volume";
        root.value = vol;
        root.muted = isMuted;
        root.visible = true;
        hideTimer.restart();
    }

    function showBrightness(brightness: real) {
        root.type = "brightness";
        root.value = brightness;
        root.muted = false;
        root.visible = true;
        hideTimer.restart();
    }

    function hide() {
        root.visible = false;
    }
}
