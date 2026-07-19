import Quickshell
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root
    spacing: 6

    property var battery: UPower.displayDevice
    property bool charging: battery.state === UPowerDeviceState.Charging
    readonly property int level: Math.round(battery.percentage * 100)
    readonly property string icon: {
        if (charging)
            return String.fromCodePoint(0xF0084);
        if (level >= 100)
            return String.fromCodePoint(0xF0079);
        if (level < 10)
            return String.fromCodePoint(0xF0083);

        return String.fromCodePoint(0xF007A + (Math.floor(level / 10) - 1));
    }

    Text {
        text: root.icon
        color: root.charging ? "#7aa2f7" : (root.level <= 30 ? "#e0af68" : "#c0caf5")
        font {
            family: "JetBrainsMono Nerd Font Propo"
            pixelSize: 13
        }
    }

    Text {
        text: root.level + "%"
        color: root.charging ? "#7aa2f7" : (root.level <= 30 ? "#e0af68" : "#c0caf5")
        font {
            family: "SF Pro Display"
            pixelSize: 13
            weight: 500
        }
    }
}
