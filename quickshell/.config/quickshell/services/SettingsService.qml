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

    property bool panelVisible: false
    property string currentTheme: "tokyonight"
    property string currentFont: "CaskaydiaCove Nerd Font Mono"   // mono
    property string currentUiFont: "CaskaydiaCove Nerd Font"      // UI

    property string section: "theme"
    property int selectedIndex: 0
    property string query: ""

    readonly property var sections: [
        { name: "theme", label: "Theme" },
        { name: "font", label: "Font" },
    ]

    // Pairs match fc-list families on this machine. `name` is display-only.
    readonly property var fonts: [
        {
            type: "font",
            name: "CaskaydiaCove",
            font: "CaskaydiaCove Nerd Font",
            monoFont: "CaskaydiaCove Nerd Font Mono"
        },
        {
            type: "font",
            name: "FiraCode",
            font: "FiraCode Nerd Font",
            monoFont: "FiraCode Nerd Font Mono"
        },
        {
            type: "font",
            name: "JetBrainsMono",
            font: "JetBrainsMono Nerd Font",
            monoFont: "JetBrainsMono Nerd Font Mono"
        },
        {
            type: "font",
            name: "SF Mono",
            font: "SFMono Nerd Font Mono",
            monoFont: "SFMono Nerd Font Mono"
        },
    ]

    readonly property var themes: {
        const names = ThemeService.availableThemes;
        const out = [];
        for (let i = 0; i < names.length; i++)
            out.push({ type: "theme", name: names[i] });
        return out;
    }

    readonly property var currentItems: section === "theme" ? themes : fonts

    readonly property var filteredItems: {
        if (!query)
            return currentItems;
        const q = query.toLowerCase();
        return currentItems.filter(item => {
            const hay = [
                item.name || "",
                item.font || "",
                item.monoFont || ""
            ].join(" ").toLowerCase();
            return hay.indexOf(q) >= 0;
        });
    }

    readonly property int maxVisibleItems: 8

    Component.onCompleted: {
        refreshFromState();
        ThemeService.refreshThemes();
    }

    Connections {
        target: StateService
        function onStateLoaded() {
            root.refreshFromState();
        }
    }

    function refreshFromState() {
        currentTheme = getState("theme.name", "tokyonight");
        currentFont = getState("typography.monoFont", "CaskaydiaCove Nerd Font Mono");
        currentUiFont = getState("typography.font", "CaskaydiaCove Nerd Font");
        healFontState();
    }

    // Fix legacy bug: monoFont was set to the UI family (no "Mono").
    function healFontState() {
        for (let i = 0; i < fonts.length; i++) {
            const f = fonts[i];
            if (currentFont === f.font && f.font !== f.monoFont) {
                currentFont = f.monoFont;
                setState("typography.monoFont", f.monoFont);
                if (currentUiFont !== f.font) {
                    currentUiFont = f.font;
                    setState("typography.font", f.font);
                }
                setState("fonts.mono", f.monoFont);
                reapplyTheme();
                return;
            }
        }
    }

    function isItemActive(item) {
        if (!item)
            return false;
        if (item.type === "theme")
            return item.name === currentTheme;
        return item.monoFont === currentFont || item.font === currentUiFont || item.font === currentFont;
    }

    function show() {
        ThemeService.refreshThemes();
        refreshFromState();
        query = "";
        selectedIndex = 0;
        section = "theme";
        panelVisible = true;
    }

    function hide() {
        panelVisible = false;
        query = "";
        selectedIndex = 0;
    }

    function toggle() {
        if (panelVisible)
            hide();
        else
            show();
    }

    function setSection(name) {
        if (section === name)
            return;
        section = name;
        query = "";
        selectedIndex = 0;
    }

    function cycleSection(delta) {
        const idx = sections.findIndex(s => s.name === section);
        if (idx < 0)
            return;
        const next = Math.max(0, Math.min(sections.length - 1, idx + delta));
        setSection(sections[next].name);
    }

    function navigateBy(delta) {
        const max = filteredItems.length - 1;
        if (max < 0)
            return;
        selectedIndex = Math.max(0, Math.min(max, selectedIndex + delta));
    }

    function navigateUp() { navigateBy(-1); }
    function navigateDown() { navigateBy(1); }

    function activate(index) {
        const item = filteredItems[index];
        if (!item)
            return;

        if (item.type === "theme") {
            currentTheme = item.name;
            setState("theme.name", item.name);
            reapplyTheme();
        } else {
            currentUiFont = item.font;
            currentFont = item.monoFont;
            setState("typography.font", item.font);
            setState("typography.monoFont", item.monoFont);
            setState("fonts.mono", item.monoFont);
            reapplyTheme();
        }
        hide();
    }

    function activateSelected() {
        activate(selectedIndex);
    }

    function reapplyTheme() {
        const theme = currentTheme || getState("theme.name", "tokyonight");
        applyProc.command = ["bash", "-c", Quickshell.env("HOME") + "/.local/bin/theme-set.sh " + theme];
        applyProc.running = true;
    }

    onQueryChanged: selectedIndex = 0

    Process {
        id: applyProc
    }
}
