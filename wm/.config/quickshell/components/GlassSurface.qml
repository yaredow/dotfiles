import QtQuick
import qs.config

Rectangle {
    id: root

    color: Qt.alpha(Config.surface0Color, 0.35)
    radius: Config.radiusLarge
    border.width: 1
    border.color: Qt.alpha(Config.surface2Color, 0.3)

    property color tintColor: color
    property color borderTint: border.color

    Behavior on color { ColorAnimation { duration: Config.animDurationShort } }
    Behavior on border.color { ColorAnimation { duration: Config.animDurationShort } }
}
