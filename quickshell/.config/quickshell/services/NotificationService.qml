pragma Singleton
import QtQuick
import Quickshell

Singleton {
    property int count: 0
    property bool dndEnabled: false

    function toggleDnd() {
        dndEnabled = !dndEnabled;
    }
}
