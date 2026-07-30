pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string colorsPath: Quickshell.env("HOME") + "/.config/quickshell/state/colors.json"
    readonly property string themesDir: Quickshell.env("HOME") + "/.config/theme/themes"
    readonly property string wallpaperRoot: Quickshell.env("HOME") + "/.local/wallpapers"

    property var palette: ({})
    property string currentThemeName: ""
    property var availableThemes: []

    function color(key, fallback) {
        return palette[key] ?? fallback;
    }

    function themeWallpaperDir(name) {
        return wallpaperRoot + "/" + name;
    }

    function themeWallpaperPath(name) {
        const list = themeWallpaperCache[name];
        if (list && list.length > 0)
            return list[0];
        return "";
    }

    property var themeWallpaperCache: ({})

    function refreshThemes() {
        listThemesProc.running = true;
    }

    function loadPreviews() {
        // first wallpaper per theme for picker overview
        listThemeWallpapersProc.running = true;
    }

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

    Process {
        id: listThemesProc
        property var _buffer: []
        command: ["bash", "-c", "ls -1 '" + root.themesDir + "' 2>/dev/null | sort"]
        stdout: SplitParser {
            onRead: data => {
                const t = data.trim();
                if (t && !t.includes("*"))
                    listThemesProc._buffer.push(t);
            }
        }
        onStarted: listThemesProc._buffer = []
        onExited: {
            root.availableThemes = listThemesProc._buffer;
            root.loadPreviews();
        }
    }

    Process {
        id: listThemeWallpapersProc
        property string _buffer: ""
        command: ["bash", "-c", `
            dir="${root.wallpaperRoot}"
            themes="${root.themesDir}"
            out="{"
            first=1
            for t in $(ls -1 "$themes" 2>/dev/null | sort); do
                img=$(find "$dir/$t" -maxdepth 1 -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.gif' \\) 2>/dev/null | sort | head -1)
                [ -n "$img" ] || continue
                if [ $first -eq 0 ]; then out="$out,"; fi
                first=0
                out="$out$(printf '"%s":["%s"]' "$t" "$img")"
            done
            out="$out}"
            echo "$out"
        `]
        stdout: SplitParser {
            onRead: data => listThemeWallpapersProc._buffer += data
        }
        onStarted: listThemeWallpapersProc._buffer = ""
        onExited: {
            try {
                root.themeWallpaperCache = JSON.parse(listThemeWallpapersProc._buffer.trim() || "{}");
            } catch (e) {
                root.themeWallpaperCache = ({});
            }
        }
    }

    Component.onCompleted: {
        _loadProc.running = true;
        refreshThemes();
    }
}
