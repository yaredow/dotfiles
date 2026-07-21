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

    // ========================================================================
    // PROPERTIES
    // ========================================================================

    property bool pickerVisible: false
    property string currentWallpaper: getState("wallpaper.current", "")
    property var wallpapers: []
    property var selectedWallpapers: []
    property bool confirmDelete: false
    property bool dynamicWallpaper: getState("wallpaper.dynamic", true)

    property string searchQuery: ""
    property string currentCategory: "all"
    property string themeFilter: ""
    property var favorites: getState("wallpaper.favorites", [])
    property var themeWallpapers: []

    readonly property string wallpaperDir: Quickshell.env("HOME") + "/.local/wallpapers"
    readonly property string themeWallpaperDir: wallpaperDir + "/themes"
    readonly property string themesConfigDir: Quickshell.env("HOME") + "/.local/themes"
    readonly property int selectedCount: selectedWallpapers.length

    readonly property var activeThemeWallpapers: {
        const result = [];
        const themes = ThemeService.availableThemes;
        const previews = ThemeService.themePreviews;
        for (let i = 0; i < themes.length; i++) {
            const name = themes[i];
            const preview = previews[name];
            if (preview && preview.wallpaper) {
                result.push(wallpaperDir + "/" + preview.wallpaper);
            }
        }
        return result;
    }

    readonly property var filteredWallpapers: {
        let list;

        if (currentCategory === "themes" && themeFilter) {
            list = root.themeWallpapers;
        } else if (currentCategory === "themes") {
            const themes = ThemeService.availableThemes;
            const previews = ThemeService.themePreviews;
            list = [];
            for (let i = 0; i < themes.length; i++) {
                const preview = previews[themes[i]];
                if (preview && preview.wallpaper)
                    list.push(themes[i]);
            }
        } else {
            list = root.wallpapers;

            if (currentCategory === "favorites")
                list = list.filter(w => favorites.includes(relativePath(w)));
        }

        if (searchQuery) {
            const q = searchQuery.toLowerCase();
            if (currentCategory === "themes" && !themeFilter)
                list = list.filter(t => t.toLowerCase().includes(q));
            else
                list = list.filter(w => fileName(w).toLowerCase().includes(q));
        }

        return list;
    }

    readonly property var transitions: ["wipe", "wave", "grow", "center", "outer", "any"]

    // ========================================================================
    // INITIALIZATION
    // ========================================================================

    Component.onCompleted: {
        refreshWallpapers();
        getCurrentWallpaper();
    }

    Connections {
        target: StateService

        function onStateLoaded() {
            root.currentWallpaper = getState("wallpaper.current", "");
            root.dynamicWallpaper = getState("wallpaper.dynamic", true);
            root.favorites = getState("wallpaper.favorites", []);
        }
    }

    // ========================================================================
    // PUBLIC FUNCTIONS
    // ========================================================================

    function fileName(path) {
        return path.split("/").pop();
    }

    function relativePath(path) {
        return path.replace(wallpaperDir + "/", "");
    }

    function toggleFavorite(path) {
        const rel = relativePath(path);
        let favs = [...favorites];
        const idx = favs.indexOf(rel);
        if (idx >= 0)
            favs.splice(idx, 1);
        else
            favs.push(rel);
        favorites = favs;
        setState("wallpaper.favorites", favs);
    }

    function isFavorite(path) {
        return favorites.includes(relativePath(path));
    }

    function isThemeWallpaper(path) {
        return fileName(path).startsWith("theme-");
    }

    function themeNameFromPath(path) {
        const name = fileName(path);
        const match = name.match(/^theme-(.+)\.\w+$/);
        return match ? match[1] : "";
    }

    function addToTheme(sourcePath, themeName) {
        const dest = themeWallpaperDir + "/" + themeName + "/";
        addToThemeProc.command = ["bash", "-c", "mkdir -p '" + dest + "' && cp '" + sourcePath + "' '" + dest + "'"];
        addToThemeProc._themeName = themeName;
        addToThemeProc.running = true;
    }

    function setActiveThemeWallpaper(wallpaperPath, themeName) {
        const relativePath = wallpaperPath.replace(wallpaperDir + "/", "");
        const jsonPath = themesConfigDir + "/" + themeName + ".json";
        setActiveThemeProc.command = ["bash", "-c", "jq '.wallpaper = \"" + relativePath + "\"' '" + jsonPath + "' > '" + jsonPath + ".tmp' && mv '" + jsonPath + ".tmp' '" + jsonPath + "'"];
        setActiveThemeProc._wallpaperPath = wallpaperPath;
        setActiveThemeProc.running = true;
    }

    function refreshThemeWallpapers(themeName) {
        if (!themeName) {
            themeWallpapers = [];
            return;
        }
        listThemeWallpapersProc._themeName = themeName;
        listThemeWallpapersProc.command = ["bash", "-c", "mkdir -p '" + themeWallpaperDir + "/" + themeName + "' && " + "ls -1 '" + themeWallpaperDir + "/" + themeName + "'/*.{png,jpg,jpeg,webp,gif} 2>/dev/null | sort"];
        listThemeWallpapersProc.running = true;
    }

    function themeForActiveWallpaper(wallpaperPath) {
        const relativePath = wallpaperPath.replace(wallpaperDir + "/", "");
        const themes = ThemeService.availableThemes;
        const previews = ThemeService.themePreviews;
        for (let i = 0; i < themes.length; i++) {
            const preview = previews[themes[i]];
            if (preview && preview.wallpaper === relativePath)
                return themes[i];
        }
        return "";
    }

    function getThemeActiveWallpaper(themeName) {
        const preview = ThemeService.themePreviews[themeName];
        if (preview && preview.wallpaper)
            return preview.wallpaper;
        return "";
    }

    function themeWallpaperPath(themeName) {
        const rel = getThemeActiveWallpaper(themeName);
        return rel ? wallpaperDir + "/" + rel : "";
    }

    function isActiveThemeWallpaper(wallpaperPath, themeName) {
        const relativePath = wallpaperPath.replace(wallpaperDir + "/", "");
        const activeWallpaper = getThemeActiveWallpaper(themeName);
        return relativePath === activeWallpaper;
    }

    function toggleDynamicWallpaper() {
        dynamicWallpaper = !dynamicWallpaper;
        setState("wallpaper.dynamic", dynamicWallpaper);
    }

    function show() {
        refreshWallpapers();
        selectedWallpapers = [];
        confirmDelete = false;
        searchQuery = "";
        currentCategory = "all";
        themeFilter = "";
        themeWallpapers = [];
        pickerVisible = true;
    }

    function hide() {
        pickerVisible = false;
        selectedWallpapers = [];
        confirmDelete = false;
    }

    function toggle() {
        if (pickerVisible)
            hide();
        else
            show();
    }

    function isSelected(path) {
        return selectedWallpapers.includes(path);
    }

    function toggleSelection(path) {
        if (isSelected(path)) {
            selectedWallpapers = selectedWallpapers.filter(w => w !== path);
        } else {
            selectedWallpapers = [...selectedWallpapers, path];
        }
        confirmDelete = false;
    }

    function selectOnly(path) {
        selectedWallpapers = [path];
        confirmDelete = false;
    }

    function clearSelection() {
        selectedWallpapers = [];
        confirmDelete = false;
    }

    function setWallpaper(path) {
        setWallpaperProc.command = ["hyprctl", "hyprpaper", "wallpaper", "," + path + ",cover"];
        setWallpaperProc.running = true;

        currentWallpaper = path;

        root.setState("wallpaper.current", path);

        writeCurrentProc.command = ["sh", "-c", "echo '" + path + "' > '" + wallpaperDir + "/.current'"];
        writeCurrentProc.running = true;

        if (ThemeService.isAutoMode) {
            ThemeService.runMatugen(path);
        }

        hide();
    }

    function applySelected() {
        if (selectedWallpapers.length === 1) {
            setWallpaper(selectedWallpapers[0]);
        }
    }

    function setRandomWallpaper() {
        if (wallpapers.length === 0)
            return;

        const available = wallpapers.filter(w => w !== currentWallpaper);
        if (available.length === 0)
            return;

        const randomIndex = Math.floor(Math.random() * available.length);
        setWallpaper(available[randomIndex]);
    }

    function requestDelete() {
        if (selectedWallpapers.length === 0)
            return;

        if (selectedWallpapers.length === 1) {
            deleteSelected();
        } else {
            confirmDelete = true;
        }
    }

    function deleteSelected() {
        if (selectedWallpapers.length === 0)
            return;

        let rmPaths = [];
        for (let i = 0; i < selectedWallpapers.length; i++) {
            const path = selectedWallpapers[i];
            rmPaths.push("'" + path + "'");
            root.wallpapers = root.wallpapers.filter(w => w !== path);
            root.themeWallpapers = root.themeWallpapers.filter(w => w !== path);
            if (currentWallpaper === path)
                currentWallpaper = "";
        }
        deleteWallpaperProc.command = ["sh", "-c", "rm " + rmPaths.join(" ")];
        deleteWallpaperProc.running = true;

        selectedWallpapers = [];
        confirmDelete = false;
    }

    function cancelDelete() {
        confirmDelete = false;
    }

    function addWallpapers() {
        hide();
        addWallpapersProc.running = true;
    }

    function refreshWallpapers() {
        listWallpapersProc.running = true;
    }

    function getCurrentWallpaper() {
        getCurrentProc.running = true;
    }

    // ========================================================================
    // WATCHERS
    // ========================================================================

    onThemeFilterChanged: {
        if (themeFilter) {
            refreshThemeWallpapers(themeFilter);
        } else {
            themeWallpapers = [];
        }
        clearSelection();
    }

    // ========================================================================
    // PROCESSES
    // ========================================================================

    Process {
        id: listWallpapersProc
        property var _buffer: []
        command: ["bash", "-c", "ls -1 '" + root.wallpaperDir + "'/*.{png,jpg,jpeg,webp,gif} 2>/dev/null | sort"]
        stdout: SplitParser {
            onRead: data => {
                const trimmed = data.trim();
                if (trimmed && !trimmed.includes("*"))
                    listWallpapersProc._buffer.push(trimmed);
            }
        }
        onStarted: listWallpapersProc._buffer = []
        onExited: root.wallpapers = listWallpapersProc._buffer
    }

    Process {
        id: listThemeWallpapersProc
        property string _themeName: ""
        property var _buffer: []

        stdout: SplitParser {
            onRead: data => {
                const trimmed = data.trim();
                if (trimmed && !trimmed.includes("*"))
                    listThemeWallpapersProc._buffer.push(trimmed);
            }
        }
        onStarted: listThemeWallpapersProc._buffer = []
        onExited: root.themeWallpapers = listThemeWallpapersProc._buffer
    }

    Process {
        id: setWallpaperProc
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                console.log("[Wallpaper] Wallpaper changed successfully");
            } else {
                console.error("[Wallpaper] Failed to change wallpaper");
            }
        }
    }

    Process {
        id: getCurrentProc
        command: ["bash", "-c", "cat '" + root.wallpaperDir + "/.current' 2>/dev/null || echo ''"]
        stdout: SplitParser {
            onRead: data => {
                const trimmed = data.trim();
                if (trimmed) {
                    root.currentWallpaper = trimmed;
                    root.setState("wallpaper.current", root.currentWallpaper);
                }
            }
        }
    }

    Process {
        id: addWallpapersProc
        command: ["bash", "-c", `
            files=$(kdialog --multiple --getopenfilename ~ "Image Files (*.png *.jpg *.jpeg *.webp *.gif)")
            if [ -n "$files" ]; then
                mkdir -p "${root.wallpaperDir}"
                echo "$files" | while read -r file; do
                    if [ -f "$file" ]; then
                        cp "$file" "${root.wallpaperDir}/"
                    fi
                done
                echo "done"
            else
                echo "cancelled"
            fi
        `]
        stdout: SplitParser {
            onRead: data => {
                const result = data.trim();
                if (result === "done" || result === "cancelled") {
                    root.refreshWallpapers();
                    root.show();
                }
            }
        }
    }

    Process {
        id: addToThemeProc
        property string _themeName: ""

        onExited: exitCode => {
            if (exitCode === 0) {
                console.log("[Wallpaper] Added wallpaper to theme:", _themeName);
                if (root.themeFilter === _themeName)
                    root.refreshThemeWallpapers(_themeName);
            } else {
                console.error("[Wallpaper] Failed to add wallpaper to theme");
            }
        }
    }

    Process {
        id: setActiveThemeProc
        property string _wallpaperPath: ""

        onExited: exitCode => {
            if (exitCode === 0) {
                console.log("[Wallpaper] Theme wallpaper config updated");
                ThemeService.loadPreviews();
            } else {
                console.error("[Wallpaper] Failed to update theme config");
            }
        }
    }

    Process {
        id: writeCurrentProc
    }

    Process {
        id: deleteWallpaperProc
    }
}
