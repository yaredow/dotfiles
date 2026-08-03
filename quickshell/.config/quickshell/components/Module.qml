import QtQuick
import QtQuick.Layouts
import qs.config

Item {
    id: modItem

    required property var host

    property string glyph: ""
    property string imageSource: ""
    property bool showLogo: false
    property string tooltip: ""
    property color color: Config.textColor
    property string fontFamily: Config.font
    property int fontSize: 13
    property int glyphYOffset: -1
    property int fontWeight: Font.DemiBold
    property bool panelOpen: false
    property bool wheelEnabled: false

    signal activated
    signal rightActivated
    signal wheeled(int delta)

    Layout.alignment: modItem.host.isHorizontal ? Qt.AlignVCenter : Qt.AlignHCenter
    Layout.preferredWidth: modItem.host.isHorizontal ? 27 : Config.barHeight
    Layout.preferredHeight: modItem.host.isHorizontal ? Config.barHeight : 27

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
        radius: width / 2
        color: mouse.containsMouse ? Qt.rgba(Config.textColor.r, Config.textColor.g, Config.textColor.b, 0.07) : "transparent"
        Behavior on color {
            ColorAnimation {
                duration: 180
            }
        }
    }

    Item {
        anchors.fill: parent
        scale: mouse.containsMouse ? 1.1 : 1.0

        Behavior on scale {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }

        Image {
            anchors.centerIn: parent
            width: 20; height: 20
            source: modItem.imageSource
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            sourceSize: Qt.size(40, 40)
            smooth: true
            visible: modItem.imageSource != "" && !modItem.showLogo
        }

        YdotLogo {
            anchors.centerIn: parent
            width: 20; height: 20
            visible: modItem.showLogo
        }

        Text {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: modItem.glyphYOffset
            text: modItem.glyph
            color: modItem.color
            font.family: modItem.fontFamily
            font.pixelSize: modItem.fontSize
            font.weight: modItem.fontWeight
            visible: modItem.imageSource == "" && !modItem.showLogo
        }
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
        width: 12
        height: 2
        radius: 1
        color: Config.accentColor
        opacity: modItem.panelOpen ? 0.9 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onEntered: {
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
        onWheel: function(event) {
            if (modItem.wheelEnabled)
                modItem.wheeled(event.angleDelta.y > 0 ? 1 : -1)
        }
    }
}
