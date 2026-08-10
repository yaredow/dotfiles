pragma Singleton
import QtQuick
import Quickshell

Singleton {
    property var openModules: ({})
    property int closePulse: 0
    property string closeExclude: ""

    readonly property bool anyModuleOpen: {
        for (var key in openModules) {
            if (openModules[key])
                return true;
        }
        return false;
    }

    function registerOpen(name) {
        openModules[name] = true;
    }

    function registerClose(name) {
        openModules[name] = false;
    }

    function closeAllExcept(name) {
        closeExclude = name
        closePulse++
    }
}
