pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

Singleton {
    id: root

    function getState(path, fallback) { return StateService.get ? StateService.get(path, fallback) : fallback }
    function setState(path, value) { if (StateService.set) StateService.set(path, value) }

    property string currentThemeName: "tokyonight"
    property string themeMode: "preset"
    property string colorScheme: "dark"

    readonly property bool isAutoMode: themeMode === "auto"
    readonly property bool isDarkMode: colorScheme === "dark"

    property var availableThemes: ["tokyonight"]
    property var themePreviews: ({})

    readonly property var displayThemes: availableThemes

    property var palette: ({
        "background": "#1a1b26", "surface0": "#24283b", "surface1": "#292e42",
        "surface2": "#414868", "surface3": "#565f89", "text": "#c0caf5",
        "textReverse": "#1a1b26", "subtext": "#a9b1d6", "subtextReverse": "#565f89",
        "accent": "#7aa2f7", "success": "#9ece6a", "warning": "#e0af68",
        "error": "#f7768e", "muted": "#545c7e", "greyBlue": "#283457", "blueDark": "#16161e"
    })

    function color(key, fallback) { return palette[key] ?? fallback }

    function applyTheme(themeName) { root.currentThemeName = themeName; }
    function setPresetMode(themeName) { themeMode = "preset"; applyTheme(themeName); }
    function setAutoMode() { themeMode = "auto"; }
    function setColorScheme(scheme) { colorScheme = scheme; }
    function runMatugen(wallpaperPath) {}
    function listThemes() {}
    function loadPreviews() {}
}
