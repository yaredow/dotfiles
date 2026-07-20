pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string currentWallpaper: ""
    property var wallpapers: []
    property bool dynamicWallpaper: false

    function setWallpaper(path) {
        setWallpaperProc.command = ["awww", "img", path, "--transition-type", "grow", "--transition-duration", "1"];
        setWallpaperProc.running = true;
        currentWallpaper = path;
    }

    function refreshWallpapers() {
        listWallpapersProc.running = true;
    }

    Process {
        id: listWallpapersProc
        property var _buffer: []
        command: ["bash", "-c", "ls -1 '" + Quickshell.env("HOME") + "/.local/wallpapers'/*.{png,jpg,jpeg,webp,gif} 2>/dev/null | sort"]
        stdout: SplitParser {
            onRead: data => { const t = data.trim(); if (t && !t.includes("*")) listWallpapersProc._buffer.push(t); }
        }
        onStarted: listWallpapersProc._buffer = []
        onExited: root.wallpapers = listWallpapersProc._buffer
    }

    Process {
        id: setWallpaperProc
    }
}
