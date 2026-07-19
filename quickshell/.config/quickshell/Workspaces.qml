import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

RowLayout {
    spacing: 6

    Repeater {
        model: Hyprland.workspaces.values

        Rectangle {
            id: wsButton
            required property var modelData

            property bool isActive: Hyprland.focusedWorkspace?.id === modelData.id
            implicitWidth: label.implicitWidth + 10
            implicitHeight: 20
            radius: 5

            color: isActive ? "#7aa2f7" : "#283457"

            Behavior on color {
                ColorAnimation {
                    duration: 150
                }
            }

            Text {
                id: label
                anchors.centerIn: parent
                text: wsButton.modelData.id
                color: wsButton.isActive ? "#1a1b26" : "#c0caf5"

                font {
                    family: "SF Mono"
                    pixelSize: 13
                    weight: 500
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: Hyprland.dispatch(`hl.dsp.focus({ workspace = ${wsButton.modelData.id} })`)
            }
        }
    }
}
