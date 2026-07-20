pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.config
import qs.services

Item {
    id: root

    signal paletteToggleRequested()

    readonly property int barHeight: Config.barHeight

    // ---------- Edge ----------
    property string barEdge: "top"
    readonly property bool isHorizontal: barEdge === "top" || barEdge === "bottom"

    function cycleBarEdge() {
        const edges = ["top", "right", "bottom", "left"];
        root.barEdge = edges[(edges.indexOf(root.barEdge) + 1) % 4];
    }

    function edgeArrow() {
        return ({top: "↑", right: "→", bottom: "↓", left: "←"})[root.barEdge] || "?";
    }

    // ---------- Tooltips ----------
    property string tooltipText: ""
    property real tooltipBarX: 0
    property real tooltipBarY: 0
    property bool tooltipShown: false

    function showTooltip(text, x, y) {
        if (!text) return;
        root.tooltipText = text;
        root.tooltipBarX = x;
        root.tooltipBarY = y;
        root.tooltipShown = true;
    }

    function hideTooltip(text) {
        if (!text || root.tooltipText === text)
            root.tooltipShown = false;
    }

    // ---------- Idle dim ----------
    IdleMonitor {
        id: idleMonitor
        enabled: true
        timeout: 60
        respectInhibitors: true
    }
    readonly property bool isIdle: idleMonitor.isIdle

    // ---------- Workspace ----------
    property int activeWs: 1
    property var existingWs: [1, 2, 3, 4, 5]
    property int lastDirection: 0

    function refreshExistingWs() {
        Hyprland.refreshWorkspaces();
        const wsList = Hyprland.workspaces;
        const have = [];
        for (let i = 0; i < wsList.values.length; i++) {
            const id = wsList.values[i].id;
            if (id >= 1 && id <= 9) have.push(id);
        }
        const set = new Set([...have, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
        root.existingWs = [...set].sort((a, b) => a - b).slice(0, 9);
    }

    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() {
            const ws = Hyprland.focusedWorkspace;
            if (!ws) return;
            const next = ws.id;
            if (next > root.activeWs) root.lastDirection = 1;
            else if (next < root.activeWs) root.lastDirection = -1;
            root.activeWs = next;
            Qt.callLater(refreshExistingWs);
        }

        function onRawEvent(event) {
            if (event.name === "workspace" || event.name === "createworkspace" || event.name === "destroyworkspace") {
                Qt.callLater(refreshExistingWs);
            }
        }
    }

    Component.onCompleted: {
        const ws = Hyprland.focusedWorkspace;
        if (ws) root.activeWs = ws.id;
        refreshExistingWs();
    }
}
