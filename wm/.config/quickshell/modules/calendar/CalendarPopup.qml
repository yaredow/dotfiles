pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config

PanelWindow {
    id: root

    property bool revealed: false
    property bool isClosing: false
    property int monthOffset: 0
    property var today: new Date()

    visible: revealed || isClosing
    color: "transparent"

    anchors {
        top: true
        left: true
        right: true
    }
    margins.top: Config.barHeight + 8

    implicitWidth: 1920
    implicitHeight: bodyCol.implicitHeight + 44

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs_modules"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.exclusiveZone: -1

    // ---- Today tracking -----
    readonly property string todayKey: today.getFullYear() + "-"
        + pad2(today.getMonth() + 1) + "-"
        + pad2(today.getDate())

    readonly property int viewYear: {
        var d = new Date(today.getFullYear(), today.getMonth() + monthOffset, 1)
        return d.getFullYear()
    }
    readonly property int viewMonth: {
        var d = new Date(today.getFullYear(), today.getMonth() + monthOffset, 1)
        return d.getMonth()
    }
    readonly property bool viewingCurrentMonth: monthOffset === 0

    readonly property int weekStart: 1

    // ---- Year progress ----
    readonly property int dayOfYear: {
        var start = new Date(today.getFullYear(), 0, 1)
        return Math.floor((today.getTime() - start.getTime()) / 86400000) + 1
    }
    readonly property int daysInYear: {
        return dayOfYearForDate(today.getFullYear(), 11, 31)
    }
    readonly property real yearDone: {
        var d = daysInYear
        if (d <= 0) return 0
        return Math.max(0, Math.min(1, (dayOfYear - 1) / d))
    }
    readonly property int yearDonePercent: Math.round(yearDone * 100)

    function dayOfYearForDate(y, m, d) {
        var start = new Date(y, 0, 1)
        var end = new Date(y, m, d)
        return Math.floor((end.getTime() - start.getTime()) / 86400000) + 1
    }

    function pad2(n) { return n < 10 ? "0" + n : "" + n }

    // ---- ISO week (port from Omarchy Model.js) ----
    function isoWeek(y, m, d) {
        var date = new Date(Date.UTC(y, m, d))
        var weekday = date.getUTCDay() || 7
        date.setUTCDate(date.getUTCDate() + 4 - weekday)
        var yearStart = new Date(Date.UTC(date.getUTCFullYear(), 0, 1))
        return Math.ceil(((date.getTime() - yearStart.getTime()) / 86400000 + 1) / 7)
    }

    // ---- Month grid with ISO weeks (port from Omarchy) ----
    readonly property var weeks: {
        var y = viewYear, m = viewMonth, start = weekStart
        var leading = (new Date(y, m, 1).getDay() - start + 7) % 7
        var cursor = new Date(y, m, 1 - leading)
        var tkey = todayKey
        var rows = []

        for (var w = 0; w < 6; w++) {
            var days = []
            var thursday = null
            for (var d = 0; d < 7; d++) {
                var cy = cursor.getFullYear(), cm = cursor.getMonth(), cd = cursor.getDate()
                var wd = cursor.getDay()
                var key = cy + "-" + pad2(cm + 1) + "-" + pad2(cd)
                if (wd === 4) thursday = { y: cy, m: cm, d: cd }
                days.push({
                    day: cd, inMonth: cm === m && cy === y,
                    weekend: wd === 0 || wd === 6, today: key === tkey
                })
                cursor.setDate(cursor.getDate() + 1)
            }
            var anchor = thursday || days[0]
            rows.push({ week: isoWeek(anchor.y, anchor.m, anchor.d), days: days })
        }
        return rows
    }

    readonly property var weekdays: {
        var order = []
        for (var i = 0; i < 7; i++)
            order.push((weekStart + i) % 7)
        return order
    }

    function weekdayLabel(wd) {
        return Qt.locale().dayName(wd, Locale.ShortFormat).replace(/\.$/, "").toUpperCase()
    }

    function goToToday() {
        monthOffset = 0
    }

    function openCalendar() {
        root.today = new Date()
        root.monthOffset = 0
        root.revealed = true
        root.isClosing = false
        Qt.callLater(function() { card.forceActiveFocus() })
    }

    function closeCalendar() {
        if (!root.revealed || root.isClosing) return
        root.isClosing = true
        root.revealed = false
        closeTimer.restart()
    }

    Timer {
        id: closeTimer
        interval: 250
        onTriggered: root.isClosing = false
    }

    // ---- Auto-refresh ----
    Timer {
        id: dayRefresh
        interval: 30000
        running: root.revealed
        repeat: true
        onTriggered: {
            var now = new Date()
            var oldKey = root.todayKey
            root.today = now
            if (oldKey !== root.todayKey && root.viewingCurrentMonth)
                root.goToToday()
        }
    }

    // ---- Focus / escape ----
    onVisibleChanged: {
        if (visible) {
            card.forceActiveFocus()
        }
    }

    // Click outside → close
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: root.closeCalendar()
    }

    // ---- Centered card ----
    Rectangle {
        id: card
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: 360
        height: bodyCol.implicitHeight + 32
        radius: Config.radius
        color: Config.backgroundTransparentColor
        border.color: Config.surface3Color
        border.width: 2
        clip: true

        opacity: root.isClosing ? 0 : (root.revealed ? 1 : 0)
        Behavior on opacity { NumberAnimation { duration: 200 } }

        transform: Scale {
            origin.x: card.width / 2; origin.y: 0
            xScale: root.isClosing ? 0.95 : (root.revealed ? 1 : 0.95)
            yScale: root.isClosing ? 0.95 : (root.revealed ? 1 : 0.95)
        }
        Behavior on transform { NumberAnimation { duration: 200; easing.type: Easing.OutExpo } }

        Keys.onEscapePressed: root.closeCalendar()
        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_T) { root.goToToday(); event.accepted = true }
            else if (event.key === Qt.Key_Left) { root.monthOffset--; event.accepted = true }
            else if (event.key === Qt.Key_Right) { root.monthOffset++; event.accepted = true }
            else if (event.key === Qt.Key_Up) { root.monthOffset -= 12; event.accepted = true }
            else if (event.key === Qt.Key_Down) { root.monthOffset += 12; event.accepted = true }
        }

        // ---- Scroll wheel ----
        MouseArea {
            anchors.fill: parent
            onWheel: function(event) {
                if (event.angleDelta.y > 0) root.monthOffset--
                else if (event.angleDelta.y < 0) root.monthOffset++
            }
        }

        Column {
            id: bodyCol
            anchors.fill: parent
            anchors.margins: 16
            spacing: 8

            // ---------- Hero: calendar icon + "July 29" ----------
            Item {
                width: parent.width
                height: Math.max(heroRow.implicitHeight, 56)

                Row {
                    id: heroRow
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 14

                    Text {
                        anchors.baseline: heroDate.baseline
                        text: "󰃭"
                        color: heroMouse.containsMouse && !root.viewingCurrentMonth
                            ? Config.accentColor : Config.textColor
                        font.family: Config.font
                        font.pixelSize: 36
                    }

                    Text {
                        id: heroDate
                        text: Qt.formatDate(root.today, "MMMM d")
                        color: heroMouse.containsMouse && !root.viewingCurrentMonth
                            ? Config.accentColor : Config.textColor
                        font.family: Config.font
                        font.pixelSize: 38
                        font.weight: Font.Bold
                    }
                }

                MouseArea {
                    id: heroMouse
                    x: heroRow.x; y: heroRow.y
                    width: heroRow.width; height: heroRow.height
                    enabled: !root.viewingCurrentMonth
                    hoverEnabled: enabled
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: root.goToToday()
                }
            }

            // ---------- Year progress bar ----------
            Item {
                width: parent.width
                height: 20

                Text {
                    id: yearLabel
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.today.getFullYear()
                    color: Qt.darker(Config.textColor, 1.5)
                    font.family: Config.monoFont
                    font.pixelSize: Config.fontSizeSmall
                    font.letterSpacing: 1
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.yearDonePercent + "%"
                    color: Config.textColor
                    font.family: Config.monoFont
                    font.pixelSize: Config.fontSizeSmall
                }

                Rectangle {
                    anchors.left: yearLabel.right
                    anchors.right: parent.right
                    anchors.leftMargin: 10
                    anchors.rightMargin: 32
                    anchors.verticalCenter: parent.verticalCenter
                    height: 5
                    radius: 2
                    color: Qt.rgba(Config.textColor.r, Config.textColor.g, Config.textColor.b, 0.12)

                    Rectangle {
                        width: Math.round(parent.width * root.yearDone)
                        height: parent.height
                        radius: parent.radius
                        color: Config.accentColor
                        Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Qt.alpha(Config.textColor, 0.1)
            }

            // ---------- Weekday header ----------
            Row {
                width: parent.width
                spacing: 0

                Item { width: 32; height: 16 }

                Repeater {
                    model: root.weekdays

                    Item {
                        required property var modelData
                        width: (parent.width - 32) / 7
                        height: 16

                        Text {
                            anchors.centerIn: parent
                            text: root.weekdayLabel(modelData)
                            color: Qt.darker(Config.textColor, 1.5)
                            font.family: Config.monoFont
                            font.pixelSize: Config.fontSizeSmall - 1
                            font.letterSpacing: 1
                            font.weight: Font.Bold
                        }
                    }
                }
            }

            // ---------- Month grid (6 rows of 7 + week numbers) ----------
            Column {
                width: parent.width
                spacing: 2

                Repeater {
                    model: root.weeks

                    delegate: Row {
                        required property var modelData
                        width: parent.width
                        spacing: 0

                        Item {
                            width: 32
                            height: 26
                            Text {
                                anchors.centerIn: parent
                                text: modelData.week
                                color: Qt.darker(Config.textColor, 1.9)
                                font.family: Config.monoFont
                                font.pixelSize: Config.fontSizeSmall - 1
                            }
                        }

                        Repeater {
                            model: modelData.days

                            delegate: Item {
                                required property var modelData
                                property bool dayToday: modelData.today
                                property bool dayInMonth: modelData.inMonth
                                property bool dayWeekend: modelData.weekend

                                width: (parent.width - 32) / 7
                                height: 26

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 24; height: 24
                                    radius: 12
                                    color: "transparent"
                                    border.width: dayToday ? 1 : 0
                                    border.color: Config.accentColor
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.day
                                    color: dayInMonth
                                        ? (dayWeekend ? Qt.darker(Config.textColor, 1.45) : Config.textColor)
                                        : Qt.darker(Config.textColor, 2.2)
                                    opacity: dayInMonth ? 1.0 : 0.35
                                    font.family: Config.monoFont
                                    font.pixelSize: Config.fontSizeSmall + 1
                                    font.weight: dayToday ? Font.Bold : Font.Normal
                                }
                            }
                        }
                    }
                }
            }

            // ---------- Separator line after grid ----------
            Rectangle {
                width: parent.width
                height: 1
                color: Qt.alpha(Config.textColor, 0.1)
            }

            // ---------- Month navigation ----------
            Item {
                width: parent.width
                height: monthLabel.implicitHeight + 8

                Text {
                    id: monthLabel
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: 130
                    horizontalAlignment: Text.AlignHCenter
                    text: Qt.formatDate(new Date(root.viewYear, root.viewMonth, 1), "MMMM yyyy").toUpperCase()
                    color: Qt.darker(Config.textColor, 1.4)
                    font.family: Config.monoFont
                    font.pixelSize: Config.fontSizeSmall + 1
                    font.letterSpacing: 1
                }

                Chevron {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    glyph: "󰅁"
                    onTriggered: root.monthOffset--
                }

                Chevron {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    glyph: "󰅂"
                    onTriggered: root.monthOffset++
                }
            }
        }
    }

    // ---- Inline chevron component ----
    component Chevron: Item {
        property string glyph: ""
        signal triggered

        width: 28; height: 28
        scale: chevronMouse.containsMouse ? 1.1 : 1.0

        Behavior on scale { NumberAnimation { duration: 120 } }

        Text {
            anchors.centerIn: parent
            text: glyph
            color: chevronMouse.containsMouse ? Config.accentColor : Config.subtextColor
            font.family: Config.font
            font.pixelSize: 20

            Behavior on color { ColorAnimation { duration: 120 } }
        }

        MouseArea {
            id: chevronMouse
            anchors.fill: parent
            anchors.margins: -6
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.triggered()
        }
    }
}
