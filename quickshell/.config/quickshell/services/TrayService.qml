pragma Singleton
import QtQuick
import Quickshell

Singleton {
    property var items: []
    property bool hasItems: false

    function getIconSource(icon) { return ""; }
    function getMenuIconSource(icon) { return ""; }
    function registerActiveMenu(menu) {}
}
