import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    implicitWidth: clockText.implicitWidth
    implicitHeight: clockText.implicitHeight

    SystemClock {
        id: sysClock
        precision: SystemClock.Minutes
    }

    Text {
        id: clockText
        text: Qt.formatDateTime(sysClock.date, "hh:mm")
        color: "#c0caf5"
        Layout.rightMargin: 12

        font {
            family: "SF Mono"
            letterSpacing: (-1)
            pixelSize: 14
            weight: 600
        }
    }
}
