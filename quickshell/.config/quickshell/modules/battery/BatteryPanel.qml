pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.config
import qs.components
import qs.services

QsPopupWindow {
    id: root

    popupWidth: 360
    anchorSide: "right"
    moduleName: "battery"
    contentImplicitHeight: mainColumn.childrenRect.height

    readonly property string binDir: "/home/yada/.local/bin"

    // ---- Data from shell scripts ----
    property int batPercent: 0
    property string batState: "unknown"
    property string batRate: ""
    property string batSize: ""
    property string batTime: ""
    property string batCycles: ""
    property string batThreshold: ""

    property var profiles: []
    property string activeProfile: ""

    // ---- Profile cursor ----
    property int profileIndex: 0
    property bool cursorActive: false
    property int phraseIndex: 0

    // ---- State checks ----
    readonly property bool isCharging: batState === "charging" || batState === "pending-charge"
    readonly property bool isDischarging: batState === "discharging"
    readonly property bool isFullyCharged: batState === "fully-charged"
    readonly property bool isBatteryFlowIdle: isFullyCharged || batThreshold !== ""

    // ---- Colour-coded hero fill ----
    readonly property color heroColor: {
        if (batPercent <= 10) return Config.errorColor
        if (batPercent <= 20) return Config.warningColor
        return Config.textColor
    }

    // ---- Hero icon (10-level, ported from Omarchy) ----
    readonly property string heroIcon: batteryIcon()

    function batteryIcon() {
        const chargingIcons = ["󰢜", "󰂆", "󰂇", "󰂈", "󰢝", "󰂉", "󰢞", "󰂊", "󰂋", "󰂅"]
        const defaultIcons  = ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
        const idx = Math.max(0, Math.min(9, Math.floor(batPercent / 10)))

        if (batThreshold !== "" || batState === "threshold")
            return defaultIcons[idx]
        if (batState === "fully-charged")
            return "󰂅"
        if (batState === "charging" || batState === "pending-charge")
            return chargingIcons[idx]
        return defaultIcons[idx]
    }

    // ---- Rotating status phrases (ported from Omarchy) ----
    readonly property var chargingPhrases: [
        "Pumping power", "Injecting electrons", "Pouring juice",
        "Amassing watts", "Hoarding joules", "Sucking volts",
        "Topping reserves", "Soaking amps", "Inhaling kilowatts"
    ]

    readonly property var onBatteryPhrases: [
        "Slurping power", "Spending joules", "Draining watts",
        "Burning electrons", "Sipping juice", "Spending coulombs",
        "Bleeding amps", "Guzzling volts", "Munching reserves"
    ]

    readonly property var activePhrases: {
        if (isFullyCharged) return []
        if (isCharging) return chargingPhrases
        if (isDischarging) return onBatteryPhrases
        return []
    }

    readonly property bool rotatingPhrases: activePhrases.length > 0

    readonly property string heroStatusText: {
        if (isFullyCharged) return "FULLY CHARGED"
        if (rotatingPhrases) return activePhrases[phraseIndex % activePhrases.length].toUpperCase()
        if (batState === "holding") return "HOLDING CHARGE"
        if (batState === "threshold") return "CHARGE CAPPED"
        if (batState === "pending-charge") return "WAITING TO CHARGE"
        return batState.toUpperCase()
    }

    // ---- Profile helpers ----
    function profileIcon(name) {
        if (name === "power-saver") return "󰌪"
        if (name === "balanced") return "󰊚"
        if (name === "performance") return "󰓅"
        return "󰂄"
    }

    function profileLabel(name) {
        var s = name.charAt(0).toUpperCase() + name.slice(1)
        return s.replace(/-/g, " ")
    }

    function setProfile(name) {
        Quickshell.execDetached([root.binDir + "/powerprofiles-set.sh", name])
        root.activeProfile = name
        for (var i = 0; i < root.profiles.length; i++)
            root.profiles[i].active = root.profiles[i].name === name
        root.profiles = root.profiles.slice()
    }

    function fetchData() {
        batteryProcess.running = true
        profileProcess.running = true
    }

    // ---- Phrase rotation timer and fade animation ----
    Timer {
        id: phraseTimer
        interval: 2800
        running: root.visible && root.rotatingPhrases
        repeat: true
        triggeredOnStart: false
        onTriggered: phraseSwap.restart()
    }

    SequentialAnimation {
        id: phraseSwap
        PropertyAnimation {
            target: heroStatus
            property: "opacity"
            to: 0.0
            duration: 180
            easing.type: Easing.OutQuad
        }
        ScriptAction {
            script: {
                var n = root.activePhrases.length
                if (n > 0) root.phraseIndex = (root.phraseIndex + 1) % n
            }
        }
        PropertyAnimation {
            target: heroStatus
            property: "opacity"
            to: 1.0
            duration: 260
            easing.type: Easing.InQuad
        }
    }

    Connections {
        target: root
        function onRotatingPhrasesChanged() {
            if (!root.rotatingPhrases) {
                phraseSwap.stop()
                heroStatus.opacity = 1.0
            }
        }
    }

    // ---- Auto-refresh while open ----
    Timer {
        id: fetchTimer
        interval: 5000
        running: root.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: root.fetchData()
    }

    // ---- Shell processes ----
    Process {
        id: batteryProcess
        command: [root.binDir + "/battery-status.sh"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split("\t")
                    var key = parts[0]
                    var val = parts.slice(1).join("\t")
                    if (!key) continue
                    if (key === "percentage") root.batPercent = parseInt(val)
                    else if (key === "state") root.batState = val
                    else if (key === "rate") root.batRate = val
                    else if (key === "size") root.batSize = val
                    else if (key === "time") root.batTime = val
                    else if (key === "cycles") root.batCycles = val
                    else if (key === "threshold") root.batThreshold = val
                }
            }
        }
    }

    Process {
        id: profileProcess
        command: [root.binDir + "/powerprofiles-list.sh"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n")
                var p = []
                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split("\t")
                    var name = parts[0]
                    var activeStr = parts[1]
                    if (!name) continue
                    p.push({ name: name, active: activeStr === "1" })
                    if (activeStr === "1") root.activeProfile = name
                }
                root.profiles = p
            }
        }
    }

    // ---- Visibility guards ----
    onVisibleChanged: {
        if (visible) {
            if (!BatteryService.hasBattery) {
                visible = false
                return
            }
            fetchData()
            var idx = root.profiles.indexOf(root.activeProfile)
            root.profileIndex = idx >= 0 ? idx : 0
            root.cursorActive = false
        }
    }

    // ---- Keyboard navigation ----
    Shortcut {
        sequences: ["Tab", "Down", "Right"]
        enabled: root.visible
        onActivated: navigateProfiles(1)
    }

    Shortcut {
        sequences: ["Backtab", "Up", "Left"]
        enabled: root.visible
        onActivated: navigateProfiles(-1)
    }

    Shortcut {
        sequences: ["Return", "Enter", "Space"]
        enabled: root.visible
        onActivated: activateSelectedProfile()
    }

    function navigateProfiles(delta) {
        var count = root.profiles.length
        if (count === 0) return
        root.profileIndex = (root.profileIndex + delta + count) % count
        root.cursorActive = true
    }

    function activateSelectedProfile() {
        if (root.cursorActive && root.profileIndex >= 0 && root.profileIndex < root.profiles.length)
            root.setProfile(root.profiles[root.profileIndex].name)
    }

    // ---- Content ----
    content: Column {
        id: mainColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 14

        // ---------- Hero: icon · title/status · percentage ----------
        Item {
            width: parent.width
            implicitHeight: Math.max(
                heroIconText.implicitHeight,
                heroLabelsColumn.implicitHeight,
                heroPercentText.implicitHeight
            )

            Text {
                id: heroIconText
                text: root.heroIcon
                color: root.heroColor
                font.family: Config.font
                font.pixelSize: Config.fontSizeIconLarge
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter

                Behavior on color { ColorAnimation { duration: 200 } }
            }

            Column {
                id: heroLabelsColumn
                anchors.left: heroIconText.right
                anchors.leftMargin: 14
                anchors.right: heroPercentText.left
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    text: "Battery"
                    color: Config.textColor
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeLarge
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                    width: parent.width
                }

                Text {
                    id: heroStatus
                    text: root.heroStatusText
                    color: Qt.darker(Config.textColor, 1.4)
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeSmall
                    font.weight: Font.Bold
                    font.letterSpacing: 1.2
                    elide: Text.ElideRight
                    width: parent.width
                }
            }

            Text {
                id: heroPercentText
                text: root.batPercent + "%"
                color: root.heroColor
                font.family: Config.font
                font.pixelSize: 32
                font.weight: Font.Bold
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter

                Behavior on color { ColorAnimation { duration: 200 } }
            }
        }

        // ---------- Battery progress bar ----------
        Item {
            width: parent.width
            implicitHeight: 8

            Rectangle {
                id: barTrack
                anchors.fill: parent
                radius: height / 2
                color: Qt.rgba(Config.textColor.r, Config.textColor.g, Config.textColor.b, 0.12)
            }

            Rectangle {
                id: barFill
                anchors.left: barTrack.left
                anchors.verticalCenter: barTrack.verticalCenter
                height: barTrack.height
                radius: barTrack.radius
                color: root.heroColor
                width: Math.max(barTrack.height, barTrack.width * Math.min(root.batPercent / 100, 1))

                Behavior on width { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 220 } }

                SequentialAnimation on opacity {
                    running: root.isCharging && !root.isFullyCharged && root.visible
                    loops: Animation.Infinite
                    alwaysRunToEnd: true
                    NumberAnimation { from: 1.0; to: 0.55; duration: 950; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 0.55; to: 1.0; duration: 950; easing.type: Easing.InOutSine }
                }
            }
        }

        // ---------- Stats ----------
        Row {
            visible: root.batSize !== "" || root.batCycles !== ""
            width: parent.width
            spacing: 20

            Column {
                width: (parent.width - parent.spacing) / 2
                spacing: 6

                InfoPair { label: "Battery size"; value: root.batSize || "" }
                InfoPair { label: "Charge cycles"; value: root.batCycles || "—" }
            }

            Column {
                width: (parent.width - parent.spacing) / 2
                spacing: 6

                InfoPair {
                    label: root.batThreshold !== "" ? "Charge limit" : (root.isDischarging ? "Time left" : "Time to full")
                    value: root.batThreshold !== "" ? root.batThreshold : (root.isBatteryFlowIdle ? "-" : (root.batTime || "—"))
                }
                InfoPair {
                    label: root.batThreshold !== "" ? "Battery state" : (root.isDischarging ? "Discharging" : "Charging")
                    value: root.batThreshold !== "" ? "Holding" : (root.isBatteryFlowIdle ? "-" : (root.batRate || ""))
                }
            }
        }

        // ---------- Separator ----------
        Rectangle {
            width: parent.width
            height: 1
            color: Qt.alpha(Config.textColor, 0.15)
        }

        // ---------- Power profile picker ----------
        Column {
            width: parent.width
            spacing: 10

            Text {
                text: "POWER PROFILE"
                color: Config.textColor
                font.family: Config.font
                font.pixelSize: Config.fontSizeSmall
                font.weight: Font.Bold
                font.letterSpacing: 1.2
            }

            Row {
                id: profileRow
                width: parent.width
                spacing: 6

                readonly property real cellWidth: root.profiles.length > 0
                    ? (width - spacing * (root.profiles.length - 1)) / root.profiles.length
                    : 0

                Repeater {
                    model: root.profiles

                    delegate: Rectangle {
                        required property var modelData
                        required property int index

                        width: profileRow.cellWidth
                        height: 40

                        radius: Config.radiusSmall
                        color: modelData.active
                            ? Qt.alpha(Config.accentColor, 0.15)
                            : "transparent"

                        border.width: modelData.active ? 1 : 0
                        border.color: modelData.active ? Qt.alpha(Config.accentColor, 0.4) : "transparent"

                        readonly property bool hasCursor: root.cursorActive && root.profileIndex === index

                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            visible: parent.hasCursor && !modelData.active
                            color: Qt.alpha(Config.textColor, 0.07)
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: 2

                            Text {
                                text: root.profileIcon(modelData.name)
                                color: modelData.active ? Config.accentColor : Config.textColor
                                font.family: Config.font
                                font.pixelSize: Config.fontSizeLarge
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Text {
                                text: root.profileLabel(modelData.name)
                                color: modelData.active ? Config.accentColor : Config.textColor
                                font.family: Config.font
                                font.pixelSize: Config.fontSizeSmall
                                font.weight: modelData.active ? Font.Medium : Font.Normal
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 4
                            text: "✓"
                            color: Config.accentColor
                            font.pixelSize: Config.fontSizeSmall
                            font.weight: Font.Bold
                            visible: modelData.active
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onEntered: {
                                root.cursorActive = true
                                root.profileIndex = index
                            }

                            onClicked: root.setProfile(modelData.name)
                        }
                    }
                }
            }
        }
    }

    // ---- Inline components ----
    component InfoPair: Row {
        property string label: ""
        property string value: ""

        width: parent.width
        spacing: 8

        InfoLabel { text: label }
        Item {
            width: Math.max(0, parent.width - parent.children[0].implicitWidth - parent.children[2].implicitWidth - parent.spacing * 2)
            height: 1
        }
        InfoValue { text: value }
    }

    component InfoLabel: Text {
        color: Config.textColor
        opacity: 0.6
        font.family: Config.font
        font.pixelSize: Config.fontSizeSmall
    }

    component InfoValue: Text {
        color: Config.textColor
        font.family: Config.font
        font.pixelSize: Config.fontSizeSmall
    }
}
