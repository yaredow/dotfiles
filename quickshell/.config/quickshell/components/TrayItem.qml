import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.services

Item {
    id: root
    required property var host
    required property var trayItem

    Layout.alignment: root.host.isHorizontal ? Qt.AlignVCenter : Qt.AlignHCenter
    Layout.preferredWidth: 24
    Layout.preferredHeight: root.host.isHorizontal ? Config.barHeight : 24

    Rectangle {
        anchors.fill: parent
        anchors.margins: 3
        radius: width / 2
        color: mouseArea.containsMouse ? Qt.rgba(Config.textColor.r, Config.textColor.g, Config.textColor.b, 0.07) : "transparent"
        Behavior on color {
            ColorAnimation { duration: 180 }
        }
    }

    Image {
        id: trayIcon
        anchors.centerIn: parent
        width: 18
        height: 18
        source: TrayService.getIconSource(root.trayItem.icon)
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        sourceSize: Qt.size(32, 32)
        smooth: true
        visible: status === Image.Ready
    }

    Image {
        anchors.centerIn: parent
        width: 18
        height: 18
        source: "image://icon/image-missing"
        fillMode: Image.PreserveAspectFit
        sourceSize: Qt.size(32, 32)
        smooth: true
        visible: trayIcon.status === Image.Error
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
                    root.trayItem.display(root, e.x, e.y)
                else
                    root.trayItem.secondaryActivate()
            } else {
                root.trayItem.activate()
            }
        }
    }
}
