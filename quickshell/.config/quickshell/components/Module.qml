import QtQuick
import QtQuick.Layouts
import qs.config

Item {
    id: modItem

    required property var host

    property string glyph: ""
    property string imageSource: ""
    property string tooltip: ""
    property color color: Config.textColor
    property string fontFamily: Config.font
    property int fontSize: 12
    property int glyphYOffset: -1
    property int fontWeight: Font.Medium

    signal activated
    signal rightActivated

    Layout.alignment: modItem.host.isHorizontal ? Qt.AlignVCenter : Qt.AlignHCenter
    Layout.preferredWidth: modItem.host.isHorizontal ? 24 : Config.barHeight
    Layout.preferredHeight: modItem.host.isHorizontal ? Config.barHeight : 24

    Timer {
        id: tipDelay
        interval: 320
        onTriggered: {
            if (!modItem.tooltip)
                return;
            const p = modItem.mapToItem(null, modItem.width / 2, modItem.height / 2);
            modItem.host.showTooltip(modItem.tooltip, p.x, p.y);
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 3
        radius: Config.radiusSmall
        color: mouse.containsMouse ? Qt.rgba(Config.textColor.r, Config.textColor.g, Config.textColor.b, 0.07) : "transparent"
        Behavior on color {
            ColorAnimation {
                duration: 180
            }
        }
    }

    Bloom {
        id: bloom
    }

    Image {
        anchors.centerIn: parent
        width: 20; height: 20
        source: modItem.imageSource
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        sourceSize: Qt.size(40, 40)
        smooth: true
        visible: modItem.imageSource != ""
    }

    Text {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: modItem.glyphYOffset
        text: modItem.glyph
        color: modItem.color
        font.family: modItem.fontFamily
        font.pixelSize: modItem.fontSize
        font.weight: modItem.fontWeight
        visible: modItem.imageSource == ""
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onEntered: {
            bloom.fire(mouseX, mouseY);
            if (modItem.tooltip)
                tipDelay.restart();
        }
        onExited: {
            tipDelay.stop();
            modItem.host.hideTooltip(modItem.tooltip);
        }
        onClicked: e => {
            tipDelay.stop();
            modItem.host.hideTooltip(modItem.tooltip);
            if (e.button === Qt.RightButton)
                modItem.rightActivated();
            else
                modItem.activated();
        }
    }
}
