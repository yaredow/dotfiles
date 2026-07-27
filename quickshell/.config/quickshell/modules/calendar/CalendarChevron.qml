import QtQuick
import qs.config

Text {
    id: chevron

    property color restColor: Config.textColor
    property color hotColor: Config.accentColor
    signal triggered()

    color: chevronMouse.containsMouse ? hotColor : restColor
    font.family: Config.monoFont
    font.pixelSize: 24
    Behavior on color {
        ColorAnimation {
            duration: 120
        }
    }

    MouseArea {
        id: chevronMouse
        anchors.fill: parent
        anchors.margins: -7
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: chevron.triggered()
    }
}
