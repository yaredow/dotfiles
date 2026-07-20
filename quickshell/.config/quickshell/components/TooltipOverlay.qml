import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config

PanelWindow {
    id: tooltipOverlay
    required property var host

    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-tooltip"
    mask: Region {}

    property real reveal: host.tooltipShown ? 1 : 0
    Behavior on reveal {
        NumberAnimation {
            duration: host.tooltipShown ? 160 : 120
            easing.type: host.tooltipShown ? Easing.OutCubic : Easing.InCubic
        }
    }
    visible: reveal > 0.001

    Rectangle {
        id: tip
        readonly property int gap: 6
        readonly property int padH: 8
        readonly property int padV: 3

        width: tipLabel.implicitWidth + padH * 2
        height: tipLabel.implicitHeight + padV * 2

        x: {
            const r = host;
            if (r.barEdge === "left")  return Config.barHeight + gap;
            if (r.barEdge === "right") return parent.width - Config.barHeight - width - gap;
            const center = r.tooltipBarX;
            return Math.max(4, Math.min(parent.width - width - 4, center - width / 2));
        }
        y: {
            const r = host;
            if (r.barEdge === "top")    return Config.barHeight + gap;
            if (r.barEdge === "bottom") return parent.height - Config.barHeight - height - gap;
            const center = r.tooltipBarY;
            return Math.max(4, Math.min(parent.height - height - 4, center - height / 2));
        }

        color: Config.backgroundColor
        border.color: Config.sepColor
        border.width: 1
        radius: Config.radiusSmall
        opacity: tooltipOverlay.reveal

        Text {
            id: tipLabel
            anchors.centerIn: parent
            text: host.tooltipText
            color: Config.textColor
            font.family: Config.monoFont
            font.pixelSize: 12
            font.letterSpacing: 1
        }
    }
}
