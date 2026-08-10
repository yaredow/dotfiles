pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.config

Item {
    id: root

    readonly property var parentWindow: QsWindow.window
    readonly property var parentScreen: parentWindow?.screen ?? null

    property var currentMonitor: {
        if (!Hyprland) return null
        return (parentScreen ? Hyprland.monitorFor(parentScreen) : null)
            ?? Hyprland.focusedMonitor ?? null
    }

    property var activeWorkspace: currentMonitor?.activeWorkspace ?? null
    property int activeId: (activeWorkspace && activeWorkspace.id > 0) ? activeWorkspace.id : 1

    property var windowCounts: ({})
    property var workspaceList: [1, 2, 3, 4, 5]
    property string manualSpecialName: ""
    readonly property bool isSpecialWorkspace: manualSpecialName !== ""

    readonly property string specialWorkspaceName: {
        if (!isSpecialWorkspace) return ""
        return manualSpecialName.startsWith("special:") ? manualSpecialName.substring(8) : manualSpecialName
    }

    function updateWindowCounts() {
        if (!Hyprland || !Hyprland.workspaces) return
        var counts = {}
        for (var ws of Hyprland.workspaces.values) {
            if (!ws || ws.id <= 0) continue
            counts[ws.id] = (ws.windows || 0)
        }
        root.windowCounts = counts
    }

    Component.onCompleted: updateWindowCounts()

    Timer { id: refreshTimer; interval: 30; onTriggered: root.updateWindowCounts() }
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (!event) return
            if (event.name === "activespecial") {
                var parts = event.data.split(",")
                var wsName = parts[0] || ""
                var targetMonitor = parts[1] || ""
                if (targetMonitor === "" || targetMonitor === root.currentMonitor?.name)
                    root.manualSpecialName = wsName
            }
            if (event.name === "workspace") root.manualSpecialName = ""
            var refresh = ["createworkspace","destroyworkspace","movewindow","openwindow","closewindow","workspace","monitoradded","monitorremoved"]
            if (refresh.includes(event.name)) refreshTimer.restart()
        }
    }

    readonly property int numSize: 12
    readonly property int numGap: 14

    implicitWidth: isSpecialWorkspace ? specialLabel.implicitWidth
        : (numSize * workspaceList.length) + (numGap * Math.max(0, workspaceList.length - 1))
    implicitHeight: 16

    // ---- Scratchpad ----
    Text {
        id: specialLabel
        visible: root.isSpecialWorkspace
        anchors.centerIn: parent
        text: "󰀘  " + root.specialWorkspaceName
        color: Config.accentColor
        font.family: Config.monoFont
        font.pixelSize: root.numSize
        font.weight: Font.Medium
        TapHandler { onTapped: { if (root.specialWorkspaceName) Hyprland.dispatch("togglespecialworkspace " + root.specialWorkspaceName) } }
        HoverHandler { cursorShape: Qt.PointingHandCursor }
    }

    // ---- Number row ----
    Row {
        visible: !root.isSpecialWorkspace
        spacing: root.numGap
        anchors.centerIn: parent

        Repeater {
            model: root.workspaceList

            delegate: Text {
                required property int modelData
                required property int index

                readonly property int wsId: modelData
                readonly property bool isActive: wsId === root.activeId
                readonly property bool hasWindows: (root.windowCounts[wsId] || 0) > 0

                anchors.verticalCenter: parent.verticalCenter
                text: String(wsId)
                font.family: Config.monoFont
                font.pixelSize: root.numSize
                font.weight: isActive ? Font.Bold : Font.Medium
                color: isActive ? Config.accentColor : Config.textColor

                Behavior on color { ColorAnimation { duration: Config.animDuration } }

                TapHandler {
                    onTapped: {
                        if (wsId !== root.activeId)
                            Hyprland.dispatch("workspace " + wsId)
                    }
                }
                HoverHandler {
                    cursorShape: wsId !== root.activeId ? Qt.PointingHandCursor : Qt.ArrowCursor
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.ArrowCursor
        enabled: !root.isSpecialWorkspace
        onWheel: function(event) {
            if (event.angleDelta.y > 0)
                Hyprland.dispatch("workspace e-1")
            else if (event.angleDelta.y < 0)
                Hyprland.dispatch("workspace e+1")
        }
    }
}
