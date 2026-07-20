import QtQuick
import QtQuick.Layouts
import qs.config

Item {
    id: wsCell
    required property var host

    property int wsId: 0
    property bool active: false
    property bool present: false
    signal activated()

    Layout.alignment: Qt.AlignVCenter
    Layout.preferredWidth: 20
    Layout.preferredHeight: Config.barHeight

    onActiveChanged: {
        if (active && host.lastDirection !== 0) {
            slideHome.stop();
            num.slideX = host.lastDirection * 2;
            slideHome.start();
        }
    }

    NumberAnimation {
        id: slideHome
        target: num
        properties: "slideX"
        to: 0
        duration: 180
        easing.type: Easing.OutCubic
    }

    Bloom { id: bloom; }

    Text {
        id: num
        property real slideX: 0
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: slideX
        anchors.verticalCenterOffset: -1
        text: wsCell.wsId
        color: wsCell.active ? Config.accentColor : (wsCell.present ? Config.textColor : Qt.alpha(Config.textColor, 0.35))
        opacity: wsCell.active ? 1.0 : (wsCell.present ? 0.75 : 0.35)
        font.family: Config.monoFont
        font.pixelSize: wsCell.active ? 15 : 13
        font.weight: Config.fontWeight
        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on opacity { NumberAnimation { duration: 120 } }
        Behavior on font.pixelSize { NumberAnimation { duration: 120 } }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -2
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: { bloom.fire(mouseX, mouseY); }
        onClicked: { wsCell.activated(); }
    }
}
