import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import "./modules/bar/"
import "./modules/notifications/"

ShellRoot {
    Bar {}
    NotificationOverlay {}
}
