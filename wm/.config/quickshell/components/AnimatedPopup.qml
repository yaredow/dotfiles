pragma ComponentBehavior: Bound
import QtQuick
import qs.config

Item {
    id: root

    property bool shown: false

    property real fromScale: Config.animPopupFromScale
    property int enterDuration: Config.animDurationLong
    property int exitDuration: Config.animDuration
    property int easingType: Config.animPopupEasing
    property real easingOvershoot: 0.0

    property bool _ready: false
    Component.onCompleted: Qt.callLater(() => { _ready = true; })

    scale: (shown && _ready) ? 1.0 : fromScale
    opacity: (shown && _ready) ? 1.0 : 0.0

    Behavior on scale {
        NumberAnimation {
            duration: root.shown ? root.enterDuration : root.exitDuration
            easing.type: root.easingType
            easing.overshoot: root.easingOvershoot
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: Config.animDurationShort
        }
    }
}
