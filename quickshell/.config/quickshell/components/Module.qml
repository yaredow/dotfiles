import QtQuick
import QtQuick.Layouts
import qs.config

Item {
    id: modItem

    required property var host

    property string glyph: ""
    property string tooltip: ""
    property color color: Config.textColor
    property string fontFamily: Config.font
    property int fontSize: 14
    property int glyphYOffset: -1

    signal activated()
    signal rightActivated()

    Layout.alignment: Qt.AlignVCenter
    Layout.preferredWidth: 24
    Layout.preferredHeight: Config.barHeight

    Timer {
        id: tipDelay
        interval: 320
        onTriggered: {
            if (!modItem.tooltip) return;
            const p = modItem.mapToItem(null, modItem.width / 2, modItem.height / 2);
            modItem.host.showTooltip(modItem.tooltip, p.x, p.y);
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 3
        radius: Config.radiusSmall
        color: mouse.containsMouse ? Qt.rgba(Config.textColor.r, Config.textColor.g, Config.textColor.b, 0.08) : "transparent"
        Behavior on color { ColorAnimation { duration: 180 } }
    }

    Bloom { id: bloom; }

    Text {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: modItem.glyphYOffset
        text: modItem.glyph
        color: modItem.color
        font.family: modItem.fontFamily
        font.pixelSize: modItem.fontSize
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onEntered: {
            bloom.fire(mouseX, mouseY);
            if (modItem.tooltip) tipDelay.restart();
        }
        onExited: {
            tipDelay.stop();
            modItem.host.hideTooltip(modItem.tooltip);
        }
        onClicked: (e) => {
            tipDelay.stop();
            modItem.host.hideTooltip(modItem.tooltip);
            if (e.button === Qt.RightButton) modItem.rightActivated();
            else modItem.activated();
        }
    }
}
