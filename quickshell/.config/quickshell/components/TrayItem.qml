import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.config
import qs.services

Item {
    id: root
    required property var host
    required property SystemTrayItem trayItem

    Layout.alignment: root.host.isHorizontal ? Qt.AlignVCenter : Qt.AlignHCenter
    Layout.preferredWidth: root.host.isHorizontal ? 24 : Config.barHeight
    Layout.preferredHeight: root.host.isHorizontal ? Config.barHeight : 24

    Rectangle {
        anchors.fill: parent
        anchors.margins: 3
        radius: Config.radiusSmall
        color: mouseArea.containsMouse ? Qt.rgba(Config.textColor.r, Config.textColor.g, Config.textColor.b, 0.07) : "transparent"
        Behavior on color {
            ColorAnimation { duration: 180 }
        }
    }

    IconImage {
        anchors.centerIn: parent
        source: root.trayItem ? TrayService.getIconSource(root.trayItem.icon) : ""
        implicitSize: 18
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: e => {
            if (e.button === Qt.RightButton) {
                if (root.trayItem.hasMenu)
                    root.trayItem.display(root, mouseX, mouseY)
                else
                    root.trayItem.secondaryActivate()
            } else {
                root.trayItem.activate()
            }
        }
    }
}
