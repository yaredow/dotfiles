pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.config
import qs.services

Item {
    id: root

    signal paletteToggleRequested

    readonly property int barHeight: Config.barHeight

    // ---------- Edge ----------
    property string barEdge: "top"
    readonly property bool isHorizontal: barEdge === "top" || barEdge === "bottom"

    function cycleBarEdge() {
        const edges = ["top", "right", "bottom", "left"];
        root.barEdge = edges[(edges.indexOf(root.barEdge) + 1) % 4];
    }

    function edgeArrow() {
        return ({
                top: "↑",
                right: "→",
                bottom: "↓",
                left: "←"
            })[root.barEdge] || "?";
    }

    // ---------- Tooltips ----------
    property string tooltipText: ""
    property real tooltipBarX: 0
    property real tooltipBarY: 0
    property bool tooltipShown: false

    function showTooltip(text, x, y) {
        if (!text)
            return;
        root.tooltipText = text;
        root.tooltipBarX = x;
        root.tooltipBarY = y;
        root.tooltipShown = true;
    }

    function hideTooltip(text) {
        if (!text || root.tooltipText === text)
            root.tooltipShown = false;
    }



}
