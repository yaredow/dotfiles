pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config

Button {
    id: root

    property string iconText: "\uF0C4F"
    property string tooltipText: "Back"
    property int size: 40

    property real iconOffsetX: -2
    property real iconOffsetY: 0

    implicitWidth: size
    implicitHeight: size
    Layout.preferredWidth: size
    Layout.preferredHeight: size

    background: Rectangle {
        radius: root.height / 2
        color: root.hovered ? Config.surface2Color : "transparent"
        Behavior on color { ColorAnimation { duration: Config.animDuration } }
    }

    Text {
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: root.iconOffsetX
        anchors.verticalCenterOffset: root.iconOffsetY
        text: root.iconText
        color: Config.textColor
        font.family: Config.font
        font.pixelSize: Config.fontSizeIcon
    }

    ToolTip.visible: root.hovered && root.tooltipText !== ""
    ToolTip.text: root.tooltipText
    ToolTip.delay: 500
}
