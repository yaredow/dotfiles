pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.config

Item {
    id: root

    property int maxWidth: 400

    property bool windowExists: Hyprland.activeToplevel !== null

    readonly property string windowTitle: Hyprland.activeToplevel?.title ?? ""

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activewindowv2") {
                root.windowExists = event.data !== "," && event.data !== "";
            }

            if (event.name === "workspace") {
                Qt.callLater(() => {
                    if (root)
                        root.windowExists = Hyprland.activeToplevel !== null;
                });
            }
        }
    }

    implicitWidth: windowExists ? content.implicitWidth : 0
    implicitHeight: content.implicitHeight

    visible: opacity > 0
    opacity: windowExists ? 1.0 : 0.0

    Behavior on opacity {
        NumberAnimation {
            duration: Config.animDuration
        }
    }
    Behavior on implicitWidth {
        NumberAnimation {
            duration: Config.animDuration
            easing.type: Easing.OutCubic
        }
    }

    RowLayout {
        id: content
        spacing: 6
        anchors.fill: parent

        Text {
            id: titleText
            text: root.windowTitle !== "" ? String.fromCodePoint(0xF2D0) + " " + root.windowTitle : ""
            color: Config.surface3Color
            font.family: Config.font
            font.pixelSize: Config.fontSizeNormal
            font.weight: Config.fontWeight
            elide: Text.ElideRight

            Layout.fillWidth: true
            Layout.maximumWidth: root.maxWidth
        }
    }
}
