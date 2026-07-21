pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.config

Singleton {
    id: root

    function getState(path, fallback) {
        return StateService.get ? StateService.get(path, fallback) : fallback
    }
    function setState(path, value) {
        if (StateService.set) StateService.set(path, value)
    }

    // ========================================================================
    // PROPERTIES
    // ========================================================================

    readonly property string themesDir: Quickshell.env("HOME") + "/.local/themes"
    readonly property string wallpaperDir: Quickshell.env("HOME") + "/.local/wallpapers"

    property string currentThemeName: getState("theme.name", "tokyonight")
    property string themeMode: getState("theme.mode", "preset")
    property string colorScheme: getState("theme.scheme", "dark")
    readonly property bool isAutoMode: themeMode === "auto"
    readonly property bool isDarkMode: colorScheme === "dark"
    property var availableThemes: []

    readonly property var displayThemes: {
        var result = [];
        var themes = availableThemes;
        var previews = themePreviews;
        var scheme = colorScheme;
        for (var i = 0; i < themes.length; i++) {
            var name = themes[i];
            var preview = previews[name];
            var variant = (preview && preview.variant) ? preview.variant : "dark";
            if (variant === scheme)
                result.push(name);
        }
        if (result.length === 0)
            return themes;
        return result;
    }

    property var themePreviews: ({})

    property var palette: ({
        "background": "#1a1b26",
        "surface0": "#24283b",
        "surface1": "#292e42",
        "surface2": "#414868",
        "surface3": "#565f89",
        "text": "#c0caf5",
        "textReverse": "#1a1b26",
        "subtext": "#a9b1d6",
        "subtextReverse": "#565f89",
        "accent": "#7aa2f7",
        "success": "#9ece6a",
        "warning": "#e0af68",
        "error": "#f7768e",
        "muted": "#545c7e",
        "greyBlue": "#283457",
        "blueDark": "#16161e"
    })

    function color(key, fallback) { return palette[key] ?? fallback }

    // ========================================================================
    // INITIALIZATION
    // ========================================================================

    Component.onCompleted: { listThemes() }

    Connections {
        target: StateService
        function onStateLoaded() {
            root.themeMode = root.getState("theme.mode", "preset");
            root.colorScheme = root.getState("theme.scheme", "dark");
            root.currentThemeName = root.getState("theme.name", "tokyonight");
            if (root.isAutoMode) {
                const wallpaper = root.getState("wallpaper.current", "");
                if (wallpaper)
                    root.runMatugen(wallpaper);
                else
                    root.applyTheme(root.currentThemeName);
            } else {
                root.applyTheme(root.currentThemeName);
            }
        }
    }

    // ========================================================================
    // PUBLIC API
    // ========================================================================

    function applyTheme(themeName) {
        console.log("[Theme] Loading theme:", themeName);
        loadThemeProc._themeName = themeName;
        loadThemeProc._buffer = "";
        loadThemeProc.command = ["cat", themesDir + "/" + themeName + ".json"];
        loadThemeProc.running = true;
    }

    function setPresetMode(themeName) {
        console.log("[Theme] Switching to preset mode:", themeName);
        themeMode = "preset";
        setState("theme.mode", "preset");
        applyTheme(themeName);
    }

    function setAutoMode() {
        console.log("[Theme] Switching to auto mode");
        themeMode = "auto";
        setState("theme.mode", "auto");
        const wallpaper = getState("wallpaper.current", "");
        if (wallpaper) {
            runMatugen(wallpaper);
        }
    }

    function setColorScheme(scheme) {
        console.log("[Theme] Switching color scheme to:", scheme);
        colorScheme = scheme;
        setState("theme.scheme", scheme);
        if (isAutoMode) {
            const wallpaper = getState("wallpaper.current", "");
            if (wallpaper)
                runMatugen(wallpaper);
        } else {
            _schemeSwitchProc._targetScheme = scheme;
            _schemeSwitchProc._buffer = "";
            _schemeSwitchProc.command = ["cat", themesDir + "/" + currentThemeName + ".json"];
            _schemeSwitchProc.running = true;
        }
    }

    function runMatugen(wallpaperPath) {
        console.log("[Theme] Running matugen on:", wallpaperPath);
        matugenProc._buffer = "";
        matugenProc.command = ["matugen", "image", wallpaperPath, "-m", colorScheme, "--prefer", "saturation"];
        matugenProc.running = true;
    }

    function listThemes() {
        listThemesProc._collected = [];
        listThemesProc.running = true;
    }

    function loadPreviews() {
        previewProc._buffer = "";
        previewProc.running = true;
    }

    // ========================================================================
    // INTERNAL
    // ========================================================================

    function _applyThemeData(themeName, data) {
        if (data.palette) {
            root.palette = data.palette;
        }

        currentThemeName = themeName;
        setState("theme.name", themeName);

        if (data.wallpaper && WallpaperService.dynamicWallpaper) {
            const path = wallpaperDir + "/" + data.wallpaper;
            wallpaperProc.command = ["bash", "-c", "[ -f '" + path + "' ] && hyprctl hyprpaper wallpaper '," + path + ",cover' || echo '[ThemeService] Wallpaper not found: " + data.wallpaper + "' >&2"];
            wallpaperProc.running = true;
        }

        console.log("[Theme] Theme applied:", data.name || themeName);
    }

    // ========================================================================
    // PROCESSES
    // ========================================================================

    Process {
        id: loadThemeProc
        property string _themeName: ""
        property string _buffer: ""

        stdout: SplitParser {
            onRead: data => loadThemeProc._buffer += data + "\n"
        }

        stderr: SplitParser {
            onRead: data => console.error("[Theme] " + data)
        }

        onExited: exitCode => {
            if (exitCode === 0) {
                try {
                    const data = JSON.parse(_buffer.trim());
                    root._applyThemeData(_themeName, data);
                } catch (e) {
                    console.error("[Theme] Failed to parse theme:", e);
                }
            } else {
                console.error("[Theme] Theme file not found:", _themeName);
            }
            _buffer = "";
        }
    }

    Process {
        id: _schemeSwitchProc
        property string _targetScheme: ""
        property string _buffer: ""

        stdout: SplitParser {
            onRead: data => _schemeSwitchProc._buffer += data + "\n"
        }

        stderr: SplitParser {
            onRead: data => console.error("[Theme:SchemeSwitch] " + data)
        }

        onExited: exitCode => {
            if (exitCode === 0) {
                try {
                    const data = JSON.parse(_buffer.trim());
                    var pairName = "";
                    if (_targetScheme === "light" && data.lightPair)
                        pairName = data.lightPair;
                    else if (_targetScheme === "dark" && data.darkPair)
                        pairName = data.darkPair;

                    if (pairName) {
                        console.log("[Theme] Switching to pair theme:", pairName);
                        root.applyTheme(pairName);
                    } else {
                        root.applyTheme(root.currentThemeName);
                    }
                } catch (e) {
                    console.error("[Theme] Failed to read pair:", e);
                    root.applyTheme(root.currentThemeName);
                }
            } else {
                root.applyTheme(root.currentThemeName);
            }
            _buffer = "";
        }
    }

    Process {
        id: listThemesProc
        command: ["bash", "-c", "ls -1 '" + root.themesDir + "'/*.json 2>/dev/null | sed 's|.*/||;s|\\.json$||' | sort"]
        property var _collected: []

        stdout: SplitParser {
            onRead: data => {
                const name = data.trim();
                if (name)
                    listThemesProc._collected.push(name);
            }
        }

        onExited: {
            root.availableThemes = listThemesProc._collected;
            console.log("[Theme] Available themes:", root.availableThemes.join(", "));
            root.loadPreviews();
        }
    }

    Process {
        id: previewProc
        command: ["bash", "-c", "shopt -s nullglob; for f in '" + root.themesDir + "'/*.json; do echo \"---THEME_NAME:$(basename \"$f\" .json)---\"; cat \"$f\"; echo '---THEME_SEP---'; done"]
        property string _buffer: ""

        stdout: SplitParser {
            onRead: data => previewProc._buffer += data + "\n"
        }

        onExited: exitCode => {
            if (exitCode !== 0)
                return;

            const chunks = _buffer.split("---THEME_SEP---");
            var previews = {};

            for (var i = 0; i < chunks.length; i++) {
                var chunk = chunks[i].trim();
                if (!chunk)
                    continue;

                var nameMatch = chunk.indexOf("---THEME_NAME:");
                if (nameMatch === -1)
                    continue;
                var nameEnd = chunk.indexOf("---", nameMatch + 14);
                if (nameEnd === -1)
                    continue;
                var themeName = chunk.substring(nameMatch + 14, nameEnd).trim();
                var jsonStr = chunk.substring(nameEnd + 3).trim();

                try {
                    var data = JSON.parse(jsonStr);
                    previews[themeName] = {
                        name: data.name || themeName,
                        palette: data.palette || {},
                        wallpaper: data.wallpaper || "",
                        variant: data.variant || "dark",
                        lightPair: data.lightPair || "",
                        darkPair: data.darkPair || ""
                    };
                } catch (e) {
                    console.error("[Theme] Preview parse error for " + themeName + ":", e);
                }
            }

            root.themePreviews = previews;
            console.log("[Theme] Loaded previews for", Object.keys(previews).length, "themes");
            _buffer = "";
        }
    }

    Process {
        id: wallpaperProc
        stderr: SplitParser {
            onRead: data => console.error("[Theme:Wallpaper] " + data)
        }
        onExited: exitCode => {
            if (exitCode === 0) {
                console.log("[Theme] Theme wallpaper applied");
                WallpaperService.getCurrentWallpaper();
            }
        }
    }

    Process {
        id: matugenProc
        property string _buffer: ""

        stdout: SplitParser {
            onRead: data => matugenProc._buffer += data + "\n"
        }

        stderr: SplitParser {
            onRead: data => console.log("[Theme:Matugen] " + data)
        }

        onExited: exitCode => {
            if (exitCode === 0) {
                console.log("[Theme] Matugen finished, loading palette...");
                loadMatugenPaletteProc._buffer = "";
                loadMatugenPaletteProc.command = ["cat", Quickshell.env("HOME") + "/.cache/matugen/quickshell-palette.json"];
                loadMatugenPaletteProc.running = true;
            } else {
                console.error("[Theme] Matugen failed with exit code:", exitCode);
            }
            _buffer = "";
        }
    }

    Process {
        id: loadMatugenPaletteProc
        property string _buffer: ""

        stdout: SplitParser {
            onRead: data => loadMatugenPaletteProc._buffer += data + "\n"
        }

        stderr: SplitParser {
            onRead: data => console.error("[Theme:MatugenPalette] " + data)
        }

        onExited: exitCode => {
            if (exitCode === 0) {
                try {
                    const pal = JSON.parse(_buffer.trim());
                    root.palette = pal;
                    console.log("[Theme] Auto palette applied");
                } catch (e) {
                    console.error("[Theme] Failed to parse matugen palette:", e);
                }
            }
            _buffer = "";
        }
    }
}
