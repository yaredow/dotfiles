pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.config

PanelWindow {
    id: root

    property bool revealed: false
    property real _reveal: revealed ? 1 : 0

    property int monthOffset: 0
    property int selectedDay: 0
    property int tick: 0

    visible: revealed || _reveal > 0.001
    color: "transparent"
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs_modules"
    WlrLayershell.keyboardFocus: revealed ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Behavior on _reveal {
        NumberAnimation {
            duration: root.revealed ? 220 : 140
            easing.type: root.revealed ? Easing.OutCubic : Easing.InCubic
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.3)
        opacity: root._reveal
        Behavior on opacity {
            NumberAnimation {
                duration: root.revealed ? 220 : 140
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.revealed = false
    }

    Rectangle {
        id: card
        width: 322
        height: bodyCol.implicitHeight + 34
        radius: Config.radiusLarge
        color: Config.backgroundTransparentColor
        border.color: Config.surface2Color
        border.width: 1

        anchors.centerIn: parent

        transform: Scale {
            origin.x: card.width / 2
            origin.y: card.height / 2
            xScale: root._reveal
            yScale: root._reveal
        }

        MouseArea {
            anchors.fill: parent
        }

        focus: root.revealed
        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                root.revealed = false;
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_Q) {
                root.revealed = false;
                event.accepted = true;
                return;
            }
        }

        Column {
            id: bodyCol
            anchors.fill: parent
            anchors.margins: 17
            spacing: 12

            Item {
                width: parent.width
                height: 43

                Column {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        text: root.monthName
                        color: Config.textColor
                        font.family: Config.monoFont
                        font.pixelSize: 19
                        font.letterSpacing: 4
                        font.weight: Font.Medium
                    }

                    Text {
                        text: root.year
                        color: Config.subtextColor
                        font.family: Config.monoFont
                        font.pixelSize: 11
                        font.letterSpacing: 2
                    }
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12

                    CalendarChevron {
                        text: "\u2039"
                        restColor: Config.subtextColor
                        onTriggered: {
                            root.monthOffset--;
                            root.tick++;
                            root.selectedDay = 0;
                        }
                    }

                    CalendarChevron {
                        text: "\u2022"
                        restColor: Config.subtextColor
                        font.pixelSize: 19
                        onTriggered: {
                            root.monthOffset = 0;
                            root.tick++;
                            root.selectedDay = (new Date()).getDate();
                        }
                    }

                    CalendarChevron {
                        text: "\u203A"
                        restColor: Config.subtextColor
                        onTriggered: {
                            root.monthOffset++;
                            root.tick++;
                            root.selectedDay = 0;
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Config.surface1Color
            }

            Row {
                width: parent.width
                spacing: 0

                Repeater {
                    model: ["MO", "TU", "WE", "TH", "FR", "SA", "SU"]

                    delegate: Item {
                        required property string modelData
                        required property int index

                        width: parent.width / 7
                        height: 22

                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            color: index >= 5 ? Config.accentColor : Config.subtextColor
                            opacity: index >= 5 ? 0.85 : 0.7
                            font.family: Config.monoFont
                            font.pixelSize: 12
                            font.letterSpacing: 2
                        }
                    }
                }
            }

            Grid {
                columns: 7
                rowSpacing: 2
                columnSpacing: 0
                width: parent.width

                Repeater {
                    model: root.calendarCells

                    delegate: Item {
                        id: dayCell
                        required property var modelData
                        required property int index

                        width: parent.width / 7
                        height: 34

                        readonly property int dayOfWeek: index % 7
                        readonly property bool isWeekend: dayOfWeek >= 5
                        readonly property bool isCurrentMonth: modelData.day !== 0
                        readonly property bool isToday: modelData.today
                        readonly property bool isSelected: isCurrentMonth && root.selectedDay === modelData.day

                        readonly property color textColor: {
                            if (isToday)
                                return Config.textReverseColor;
                            if (!isCurrentMonth)
                                return Config.subtextColor;
                            if (isWeekend)
                                return Config.accentColor;
                            return Config.textColor;
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            width: 29
                            height: 29
                            radius: 14
                            color: Config.accentColor
                            visible: dayCell.isToday
                            antialiasing: true
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            width: 29
                            height: 29
                            radius: 14
                            color: Qt.rgba(Config.textColor.r, Config.textColor.g, Config.textColor.b, 0.08)
                            visible: dayMouse.containsMouse && !dayCell.isToday && dayCell.isCurrentMonth
                            antialiasing: true
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            width: 29
                            height: 29
                            radius: 14
                            color: "transparent"
                            border.color: Config.accentColor
                            border.width: 1
                            visible: dayCell.isSelected && !dayCell.isToday
                            antialiasing: true
                        }

                        Text {
                            anchors.centerIn: parent
                            text: dayCell.modelData.day === 0 ? "" : dayCell.modelData.day
                            color: dayCell.textColor
                            opacity: dayCell.isCurrentMonth ? 1.0 : 0.35
                            font.family: Config.monoFont
                            font.pixelSize: 15
                            font.weight: dayCell.isToday ? Font.Medium : Font.Light
                        }

                        MouseArea {
                            id: dayMouse
                            anchors.fill: parent
                            hoverEnabled: dayCell.isCurrentMonth
                            enabled: dayCell.isCurrentMonth
                            cursorShape: dayCell.isCurrentMonth ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: root.selectedDay = dayCell.modelData.day
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Config.surface1Color
                visible: root.selectedDay > 0
            }

            Text {
                width: parent.width
                visible: root.selectedDay > 0
                text: root.selectedDayDetail
                color: Config.textColor
                font.family: Config.monoFont
                font.pixelSize: 11
                font.letterSpacing: 2
            }
        }
    }

    readonly property var calendarCells: {
        root.tick;
        const offset = root.monthOffset;
        const now = new Date();
        const first = new Date(now.getFullYear(), now.getMonth() + offset, 1);
        const year = first.getFullYear();
        const month = first.getMonth();
        const lastDay = new Date(year, month + 1, 0).getDate();
        const startDay = (first.getDay() + 6) % 7;
        const today = new Date();
        const isCurrentMonth = year === today.getFullYear() && month === today.getMonth();
        const cells = [];
        for (let i = 0; i < startDay; i++)
            cells.push({day: 0, today: false});
        for (let d = 1; d <= lastDay; d++)
            cells.push({day: d, today: isCurrentMonth && d === today.getDate()});
        while (cells.length < 42)
            cells.push({day: 0, today: false});
        return cells;
    }

    readonly property string monthName: {
        const months = ["JANUARY","FEBRUARY","MARCH","APRIL","MAY","JUNE",
                        "JULY","AUGUST","SEPTEMBER","OCTOBER","NOVEMBER","DECEMBER"];
        const now = new Date();
        return months[(now.getMonth() + root.monthOffset + 12000) % 12];
    }

    readonly property string year: {
        const now = new Date();
        const d = new Date(now.getFullYear(), now.getMonth() + root.monthOffset, 1);
        return String(d.getFullYear());
    }

    readonly property string selectedDayDetail: {
        if (root.selectedDay <= 0)
            return "";
        const days = ["SUNDAY","MONDAY","TUESDAY","WEDNESDAY","THURSDAY","FRIDAY","SATURDAY"];
        const months = ["JAN","FEB","MAR","APR","MAY","JUN",
                        "JUL","AUG","SEP","OCT","NOV","DEC"];
        const now = new Date();
        const d = new Date(now.getFullYear(), now.getMonth() + root.monthOffset, root.selectedDay);
        return days[d.getDay()] + " \u00B7 " + root.selectedDay + " " + months[d.getMonth()] + " " + d.getFullYear();
    }

    onRevealedChanged: {
        if (revealed) {
            root.monthOffset = 0;
            root.tick++;
            root.selectedDay = (new Date()).getDate();
        }
    }
}
