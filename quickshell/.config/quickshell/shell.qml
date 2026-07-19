import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

ShellRoot {
    PanelWindow {
        anchors {
            top: true
            left: true
            right: true
        }
        implicitHeight: 30

        Rectangle {
            anchors.fill: parent
            color: "#1a1b26"
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14

            Workspaces {}

            Item {
                Layout.fillWidth: true
            }

            RowLayout {
                spacing: 10
                Volume {}
                Network {}
                Bluetooth {}
                Battery {}
            }
        }

        Clock {
            anchors.centerIn: parent
        }
    }
}
