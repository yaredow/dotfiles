pragma Singleton
import QtQuick
import Quickshell.Services.SystemTray

QtObject {
    id: root

    readonly property var items: SystemTray.items.values
    readonly property bool hasItems: items.length > 0

    function getIconSource(iconString) {
        if (!iconString) return "image://icon/image-missing"
        if (iconString.includes("?path=")) {
            const split = iconString.split("?path=")
            if (split.length === 2) {
                const name = split[0]
                const path = split[1]
                let fileName = name
                if (fileName.includes("/")) fileName = fileName.substring(fileName.lastIndexOf("/") + 1)
                return "file://" + path + "/" + fileName
            }
        }
        if (iconString.startsWith("/")) return "file://" + iconString
        if (iconString.startsWith("file://") || iconString.startsWith("image://")) return iconString
        return "image://icon/" + iconString
    }

    function getMenuIconSource(iconString) {
        if (!iconString || iconString === "") return ""
        return getIconSource(iconString)
    }

    property var activeMenu: null

    function registerActiveMenu(menuInstance) {
        if (activeMenu && activeMenu !== menuInstance) {
            if (typeof activeMenu.close === "function") activeMenu.close()
            else activeMenu.visible = false
        }
        activeMenu = menuInstance
    }
}
