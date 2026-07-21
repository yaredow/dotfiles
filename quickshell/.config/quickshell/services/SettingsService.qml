pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

Singleton {
    id: root

    function getState(path, fallback) {
        return StateService.get ? StateService.get(path, fallback) : fallback
    }
    function setState(path, value) {
        if (StateService.set) StateService.set(path, value)
    }

    readonly property string wallpaperDir: Quickshell.env("HOME") + "/.local/wallpapers"
    readonly property string themesDir: Quickshell.env("HOME") + "/.config/theme/themes"

    property bool panelVisible: false
    property string currentWallpaper: getState("wallpaper.current", "")
    property string currentTheme: getState("theme.name", "tokyonight")
    property string currentFont: getState("fonts.mono", "JetBrainsMono Nerd Font")
    property var wallpapers: []
    property string searchQuery: ""
    property string currentSection: "wallpaper"

    readonly property var sections: [
        { name: "wallpaper", icon: "󰸉", label: "Wallpaper" },
        { name: "theme", icon: "", label: "Theme" },
        { name: "font", icon: "", label: "Font" },
    ]

    readonly property var availableThemes: ["tokyonight", "catppuccin", "rosepine"]
    readonly property var availableFonts: [
        "JetBrainsMono Nerd Font",
        "FiraCode Nerd Font",
        "CaskaydiaCove Nerd Font",
        "Meslo Nerd Font",
    ]

    readonly property var filteredWallpapers: {
        var list = root.wallpapers;
        if (root.searchQuery) {
            var q = root.searchQuery.toLowerCase();
            list = list.filter(function(w) {
                return w.split("/").pop().toLowerCase().includes(q);
            });
        }
        return list;
    }

    Component.onCompleted: refreshWallpapers()

    function show() {
        refreshWallpapers();
        panelVisible = true;
    }

    function hide() {
        panelVisible = false;
        searchQuery = "";
    }

    function toggle() {
        if (panelVisible) hide();
        else show();
    }

    function setWallpaper(path) {
        currentWallpaper = path;
        setState("wallpaper.current", path);
        setWallpaperProc.command = ["hyprctl", "hyprpaper", "wallpaper", "," + path + ",cover"];
        setWallpaperProc.running = true;
        hide();
    }

    function setTheme(name) {
        currentTheme = name;
        setState("theme.name", name);
        applyThemeProc.command = [
            "bash", "-c",
            Quickshell.env("HOME") + "/.local/bin/theme-set.sh " + name
        ];
        applyThemeProc.running = true;
    }

    function setFont(name) {
        currentFont = name;
        setState("fonts.mono", name);
        var themeColors = Quickshell.env("HOME") + "/.config/theme/themes/" + currentTheme + "/colors.json";
        updateFontProc.command = [
            "bash", "-c",
            "jq '.fonts.mono = \"" + name + "\"' " + themeColors +
            " > " + themeColors + ".tmp && mv " + themeColors + ".tmp " + themeColors +
            " && " + Quickshell.env("HOME") + "/.local/bin/theme-set.sh " + currentTheme
        ];
        updateFontProc.running = true;
    }

    function refreshWallpapers() {
        listWallpapersProc.running = true;
    }

    Process {
        id: listWallpapersProc
        property var _buffer: []
        command: ["bash", "-c", "ls -1 '" + root.wallpaperDir + "'/*.{png,jpg,jpeg,webp,gif} 2>/dev/null | sort"]
        stdout: SplitParser {
            onRead: data => {
                var trimmed = data.trim();
                if (trimmed && !trimmed.includes("*"))
                    listWallpapersProc._buffer.push(trimmed);
            }
        }
        onStarted: listWallpapersProc._buffer = []
        onExited: root.wallpapers = listWallpapersProc._buffer
    }

    Process {
        id: setWallpaperProc
    }

    Process {
        id: applyThemeProc
        stdout: SplitParser {
            onRead: data => console.log("[Settings] Theme output:", data.trim())
        }
        stderr: SplitParser {
            onRead: data => console.error("[Settings] Theme error:", data)
        }
        onExited: exitCode => {
            if (exitCode === 0)
                console.log("[Settings] Theme switched to:", root.currentTheme);
        }
    }

    Process {
        id: updateFontProc
        stdout: SplitParser {
            onRead: data => console.log("[Settings] Font output:", data.trim())
        }
        stderr: SplitParser {
            onRead: data => console.error("[Settings] Font error:", data)
        }
    }
}
