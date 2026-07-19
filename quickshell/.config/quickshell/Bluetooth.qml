import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root
    spacing: 6

    property bool btOn: false
    property var connectedNames: []

    readonly property string icon: {
        if (!btOn)
            return String.fromCodePoint(0xF00B2);
        if (connectedNames.length > 0)
            return String.fromCodePoint(0xF00B1);

        return String.fromCodePoint(0xF00AF);
    }

    readonly property string label: !btOn ? "Off" : connectedNames.length > 1 ? connectedNames.length.toString() : ""

    function refresh() {
        checkPowered.running = true;
        checkConnected.running = true;
    }

    Process {
        id: checkPowered
        running: true
        command: ["sh", "-c", "bluetoothctl show | grep 'Powered:' | awk '{print $2}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.btOn = text.trim() === "yes";
            }
        }
    }

    Process {
        id: checkConnected
        running: true
        command: ["sh", "-c", "bluetoothctl devices Connected | sed 's/^Device [^ ]* //'"]
        stdout: StdioCollector {
            onStreamFinished: {
                var names = text.trim();
                root.connectedNames = names.length > 0 ? names.split('\n') : [];
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Text {
        text: root.icon
        color: root.btOn ? "#c0caf5" : "#565f89"
        font {
            family: "JetBrainsMono Nerd Font Propo"
            pixelSize: 13
        }
    }

    Text {
        text: root.label
        visible: root.label !== ""
        color: root.btOn ? "#c0caf5" : "#565f89"
        font {
            family: "SF Pro Display"
            pixelSize: 13
            weight: 500
        }
    }
}
