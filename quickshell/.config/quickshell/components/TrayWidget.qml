pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config

RowLayout {
    id: root
    spacing: 5

    property bool isOpen: false

    Item {
        id: drawer
        clip: true
        Layout.preferredHeight: 30
        Layout.preferredWidth: root.isOpen ? 30 : 0

        Behavior on Layout.preferredWidth {
            NumberAnimation { duration: Config.animDurationLong; easing.type: Easing.OutExpo }
        }

        opacity: root.isOpen ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: Config.animDuration }
        }
    }

    Rectangle {
        id: toggleBtn
        Layout.preferredWidth: 24
        Layout.preferredHeight: 24
        radius: width / 2
        color: toggleMouse.containsMouse ? Config.surface1Color : "transparent"

        Behavior on color {
            ColorAnimation { duration: Config.animDuration }
        }

        Text {
            anchors.centerIn: parent
            text: String.fromCodePoint(0xF0141)
            font.family: Config.font
            font.pixelSize: Config.fontSizeIconSmall
            color: Config.textColor
            scale: root.isOpen ? -1 : 1
            Behavior on scale {
                NumberAnimation { duration: Config.animDuration; easing.type: Easing.OutBack }
            }
        }

        MouseArea {
            id: toggleMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.isOpen = !root.isOpen
        }
    }
}
