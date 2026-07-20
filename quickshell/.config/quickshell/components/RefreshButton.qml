pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config

Rectangle {
    id: root

    property bool loading: false
    property int size: 36

    signal clicked

    implicitWidth: size
    implicitHeight: size
    Layout.preferredWidth: size
    Layout.preferredHeight: size
    radius: Config.radius

    color: loading ? Config.accentColor : (mouseArea.containsMouse ? Config.surface2Color : Config.surface1Color)

    Behavior on color { ColorAnimation { duration: Config.animDurationShort } }

    Text {
        anchors.centerIn: parent
        text: String.fromCodePoint(0xF0450)
        font.family: Config.font
        font.pixelSize: Config.fontSizeIcon
        color: loading ? Config.textReverseColor : Config.textColor
        visible: !root.loading
    }

    Text {
        anchors.centerIn: parent
        text: String.fromCodePoint(0xF0451)
        font.family: Config.font
        font.pixelSize: Config.fontSizeIcon
        color: Config.textReverseColor
        visible: root.loading
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
