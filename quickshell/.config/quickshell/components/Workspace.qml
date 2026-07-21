import QtQuick
import QtQuick.Layouts
import qs.config

Item {
    id: wsCell
    required property var host

    property int wsId: 0
    property string label: ""
    property bool active: false
    property bool present: false
    signal activated()

    Layout.alignment: host.isHorizontal ? Qt.AlignVCenter : Qt.AlignHCenter
    Layout.preferredWidth: host.isHorizontal ? 20 : Config.barHeight
    Layout.preferredHeight: host.isHorizontal ? Config.barHeight : 20

    onActiveChanged: {
        if (active && host.lastDirection !== 0) {
            slideHome.stop();
            if (host.isHorizontal) {
                num.slideX = host.lastDirection * 2;
                num.slideY = 0;
            } else {
                num.slideY = host.lastDirection * 2;
                num.slideX = 0;
            }
            slideHome.start();
        }
    }

    NumberAnimation {
        id: slideHome
        target: num
        properties: "slideX,slideY"
        to: 0
        duration: 180
        easing.type: Easing.OutCubic
    }

    Bloom {
        id: bloom
    }

    Text {
        id: num
        property real slideX: 0
        property real slideY: 0
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: slideX
        anchors.verticalCenterOffset: slideY - 1
        text: wsCell.label !== "" ? wsCell.label : wsCell.wsId
        color: wsCell.active ? Config.accentColor : (wsCell.present ? Config.textColor : Config.subtextColor)
        opacity: wsCell.active ? 1.0 : (wsCell.present ? 0.78 : 0.35)
        font.family: Config.font
        font.pixelSize: wsCell.active ? 15 : 13
        font.weight: Font.Medium
        Behavior on color {
            ColorAnimation {
                duration: 120
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: 120
            }
        }
        Behavior on font.pixelSize {
            NumberAnimation {
                duration: 120
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -2
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: {
            bloom.fire(mouseX, mouseY);
        }
        onClicked: {
            wsCell.activated();
        }
    }
}
