pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

Singleton {
    id: root

    function getState(path, fallback) {
        return StateService.get ? StateService.get(path, fallback) : fallback;
    }
    function setState(path, value) {
        if (StateService.set)
            StateService.set(path, value);
    }

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
    readonly property string themeWallpaperDir: wallpaperDir
    readonly property int selectedCount: selectedWallpapers.length
    readonly property string binDir: Quickshell.env("HOME") + "/.local/bin"

    readonly property var activeThemeWallpapers: {
        const result = [];
        const themes = ThemeService.availableThemes;
        for (let i = 0; i < themes.length; i++) {
            const p = ThemeService.themeWallpaperPath(themes[i]);
            if (p)
                result.push(p);
        }
        return result;
    }

    readonly property var filteredWallpapers: {
        let list;

        if (currentCategory === "themes" && themeFilter) {
            list = root.themeWallpapers;
        } else if (currentCategory === "themes") {
            list = ThemeService.availableThemes.slice();
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
        const rel = relativePath(path);
        return rel.indexOf("/") >= 0 && !rel.startsWith("extras/");
    }

    function themeNameFromPath(path) {
        const rel = relativePath(path);
        const i = rel.indexOf("/");
        return i > 0 ? rel.substring(0, i) : "";
    }

    function addToTheme(sourcePath, themeName) {
        const dest = wallpaperDir + "/" + themeName + "/";
        addToThemeProc.command = ["bash", "-c", "mkdir -p '" + dest + "' && cp '" + sourcePath + "' '" + dest + "'"];
        addToThemeProc._themeName = themeName;
        addToThemeProc.running = true;
    }

    // "Active" wallpaper for a theme = currently set if under that theme, else first
    function setActiveThemeWallpaper(wallpaperPath, themeName) {
        setWallpaper(wallpaperPath);
    }

    function refreshThemeWallpapers(themeName) {
        if (!themeName) {
            themeWallpapers = [];
            return;
        }
        listThemeWallpapersProc.command = ["bash", "-c", "mkdir -p '" + wallpaperDir + "/" + themeName + "' && find '" + wallpaperDir + "/" + themeName + "' -maxdepth 1 -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.gif' \\) | sort"];
        listThemeWallpapersProc.running = true;
    }

    function themeForActiveWallpaper(wallpaperPath) {
        return themeNameFromPath(wallpaperPath);
    }

    function getThemeActiveWallpaper(themeName) {
        if (currentWallpaper && themeNameFromPath(currentWallpaper) === themeName)
            return relativePath(currentWallpaper);
        const p = ThemeService.themeWallpaperPath(themeName);
        return p ? relativePath(p) : "";
    }

    function themeWallpaperPath(themeName) {
        return ThemeService.themeWallpaperPath(themeName);
    }

    function isActiveThemeWallpaper(wallpaperPath, themeName) {
        return wallpaperPath === currentWallpaper && themeNameFromPath(wallpaperPath) === themeName;
    }

    function toggleDynamicWallpaper() {
        dynamicWallpaper = !dynamicWallpaper;
        setState("wallpaper.dynamic", dynamicWallpaper);
    }

    function show() {
        refreshWallpapers();
        ThemeService.refreshThemes();
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
        if (isSelected(path))
            selectedWallpapers = selectedWallpapers.filter(w => w !== path);
        else
            selectedWallpapers = [...selectedWallpapers, path];
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
        if (!path)
            return;
        setWallpaperProc.command = [binDir + "/wallpaper-set.sh", path];
        setWallpaperProc.running = true;
        currentWallpaper = path;
        root.setState("wallpaper.current", path);
        hide();
    }

    function applySelected() {
        if (selectedWallpapers.length === 1)
            setWallpaper(selectedWallpapers[0]);
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
        if (selectedWallpapers.length === 1)
            deleteSelected();
        else
            confirmDelete = true;
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
        deleteWallpaperProc.command = ["sh", "-c", "rm -f " + rmPaths.join(" ")];
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

    onThemeFilterChanged: {
        if (themeFilter)
            refreshThemeWallpapers(themeFilter);
        else
            themeWallpapers = [];
        clearSelection();
    }

    Process {
        id: listWallpapersProc
        property var _buffer: []
        command: ["bash", "-c", "find '" + root.wallpaperDir + "' -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.gif' \\) ! -path '*/.git/*' 2>/dev/null | sort"]
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
        onExited: exitCode => {
            if (exitCode === 0)
                console.log("[Wallpaper] set ok");
            else
                console.error("[Wallpaper] set failed");
        }
    }

    Process {
        id: getCurrentProc
        command: ["bash", "-c", `
            s="$HOME/.config/quickshell/state.json"
            cur=""
            if [ -f "$s" ]; then
              cur=$(jq -r '.wallpaper.current // empty' "$s" 2>/dev/null)
            fi
            if [ -z "$cur" ] && [ -f "${root.wallpaperDir}/.current" ]; then
              cur=$(cat "${root.wallpaperDir}/.current" 2>/dev/null)
            fi
            echo "$cur"
        `]
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
            picker=""
            if command -v kdialog >/dev/null; then
              files=$(kdialog --multiple --getopenfilename ~ "Image Files (*.png *.jpg *.jpeg *.webp *.gif)")
            elif command -v zenity >/dev/null; then
              files=$(zenity --file-selection --multiple --separator=$'\\n' --file-filter='Images | *.png *.jpg *.jpeg *.webp *.gif')
            else
              notify-send "Wallpaper" "Install kdialog or zenity to add images" -t 3000
              echo cancelled
              exit 0
            fi
            if [ -n "$files" ]; then
              mkdir -p "${root.wallpaperDir}/extras"
              echo "$files" | tr '|' '\\n' | while read -r file; do
                [ -f "$file" ] && cp "$file" "${root.wallpaperDir}/extras/"
              done
              echo done
            else
              echo cancelled
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
                ThemeService.loadPreviews();
                if (root.themeFilter === _themeName)
                    root.refreshThemeWallpapers(_themeName);
                root.refreshWallpapers();
            }
        }
    }

    Process {
        id: deleteWallpaperProc
        onExited: {
            root.refreshWallpapers();
            ThemeService.loadPreviews();
        }
    }
}
