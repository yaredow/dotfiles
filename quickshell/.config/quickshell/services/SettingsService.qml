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

    property bool panelVisible: false
    property string currentTheme: getState("theme.name", "tokyonight")
    property string currentFont: getState("typography.monoFont", "JetBrainsMono Nerd Font")
    property int currentWallpaperIndex: getState("wallpaper.index", 0)

    property string section: "theme"
    property int selectedIndex: 0

    readonly property var sections: [
        { name: "theme", label: "Theme" },
        { name: "font",  label: "Font" },
    ]

    readonly property var themes: [
        { type: "theme", name: "tokyonight" },
        { type: "theme", name: "catppuccin" },
        { type: "theme", name: "rosepine" },
    ]

    readonly property var fonts: [
        { type: "font", name: "JetBrainsMono Nerd Font" },
        { type: "font", name: "FiraCode Nerd Font" },
        { type: "font", name: "CaskaydiaCove Nerd Font" },
        { type: "font", name: "Meslo Nerd Font" },
    ]

    readonly property var currentItems: section === "theme" ? themes : fonts

    function show() {
        selectedIndex = 0
        section = "theme"
        panelVisible = true
    }

    function hide() {
        panelVisible = false
    }

    function toggle() {
        if (panelVisible) hide()
        else show()
    }

    function activate(index) {
        var items = currentItems
        var item = items[index]
        if (!item) return

        if (item.type === "theme") {
            currentTheme = item.name
            setState("theme.name", item.name)
            applyThemeProc.command = ["bash", "-c", Quickshell.env("HOME") + "/.local/bin/theme-set.sh " + item.name]
            applyThemeProc.running = true
        } else {
            currentFont = item.name
            setState("typography.monoFont", item.name)
            setState("typography.font", item.name)
            applyFontProc.command = ["bash", "-c", Quickshell.env("HOME") + "/.local/bin/theme-set.sh " + currentTheme]
            applyFontProc.running = true
        }
        hide()
    }

    Process {
        id: applyThemeProc
    }

    Process {
        id: applyFontProc
    }
}
