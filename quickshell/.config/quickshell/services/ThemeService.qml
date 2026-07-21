pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string colorsPath: Quickshell.env("HOME") + "/.config/quickshell/state/colors.json"

    property var palette: ({})
    property string currentThemeName: ""

    function color(key, fallback) { return palette[key] ?? fallback }

    FileView {
        path: root.colorsPath
        watchChanges: true
        onFileChanged: _loadTimer.restart()
    }

    Timer {
        id: _loadTimer
        interval: 150
        onTriggered: _loadProc.running = true
    }

    Process {
        id: _loadProc
        property string _buffer: ""
        command: ["cat", root.colorsPath]

        stdout: SplitParser {
            onRead: data => _loadProc._buffer += data
        }

        stderr: SplitParser {
            onRead: data => console.error("[Theme] " + data)
        }

        onExited: exitCode => {
            if (exitCode === 0) {
                try {
                    const data = JSON.parse(_loadProc._buffer.trim());
                    const changed = JSON.stringify(root.palette) !== JSON.stringify(data);
                    if (changed) {
                        root.palette = data;
                        root.currentThemeName = data.name ?? "";
                        console.log("[Theme] Loaded theme:", root.currentThemeName);
                    }
                } catch (e) {
                    console.error("[Theme] Failed to parse colors.json:", e);
                }
            }
            _loadProc._buffer = "";
        }
    }

    Component.onCompleted: { _loadProc.running = true }
}
