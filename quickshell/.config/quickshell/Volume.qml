import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root
    spacing: 6

    property var sink: Pipewire.defaultAudioSink

    readonly property bool ready: sink && sink.ready
    readonly property bool muted: ready && sink.audio.muted
    readonly property int volume: ready ? Math.round(sink.audio.volume * 100) : 0

    readonly property string icon: {
        if (!ready)
            return String.fromCodePoint(0xF0581);
        if (muted)
            return "󰝟";
        if (volume === 0)
            return String.fromCodePoint(0xF0581);
        if (volume <= 34)
            return String.fromCodePoint(0xF057F);
        if (volume <= 67)
            return String.fromCodePoint(0xF0580);

        return String.fromCodePoint(0xF057E);
    }

    Text {
        text: root.icon
        color: "#c0caf5"
        font {
            family: "JetBrainsMono Nerd Font Propo"
            pixelSize: 13
        }
    }

    Text {
        text: {
            if (!root.ready)
                return "-";
            if (root.muted)
                return "Muted";

            return root.volume + "%";
        }
        color: root.muted ? "#7aa2f7" : "#c0caf5"
        font {
            family: "SF Pro Display"
            pixelSize: 13
            weight: 500
        }
    }

    PwObjectTracker {
        objects: [root.sink]
    }
}
