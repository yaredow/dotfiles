import QtQuick
import QtQuick.Layouts
import qs.config

Rectangle {
    property var host: null
    readonly property bool horizontal: !host || host.isHorizontal

    Layout.alignment: horizontal ? Qt.AlignVCenter : Qt.AlignHCenter
    Layout.preferredWidth: horizontal ? 1 : 12
    Layout.preferredHeight: horizontal ? 12 : 1
    Layout.leftMargin: horizontal ? 4 : 0
    Layout.rightMargin: horizontal ? 4 : 0
    Layout.topMargin: horizontal ? 0 : 4
    Layout.bottomMargin: horizontal ? 0 : 4
    color: Config.sepColor
}
