pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../components/"
import qs.services
import qs.config

PanelWindow {
    id: root

    property bool showing: false
    property string filterText: ""

    visible: showing

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.namespace: "qs_modules"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    color: "transparent"

    function hide() {
        showing = false;
    }

    onShowingChanged: {
        if (showing) {
            filterText = "";
            searchInput.forceActiveFocus();
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.hide()
    }

    Shortcut {
        sequences: ["Escape"]
        onActivated: root.hide()
    }

    Rectangle {
        id: content

        anchors.centerIn: parent
        width: 560
        height: Math.min(680, root.height - 80)

        radius: Config.radiusLarge
        color: Config.backgroundTransparentColor
        border.color: Qt.alpha(Config.accentColor, 0.2)
        border.width: 1

        opacity: root.showing ? 1.0 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: Config.animDuration
                easing.type: Easing.OutCubic
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: event => event.accepted = true
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    radius: Config.radius
                    color: Qt.alpha(Config.accentColor, 0.15)

                    Text {
                        anchors.centerIn: parent
                        text: "󰌌"
                        font.family: Config.font
                        font.pixelSize: Config.fontSizeLarge
                        color: Config.accentColor
                    }
                }

                Text {
                    text: "Keybinds"
                    color: Config.textColor
                    font.bold: true
                    font.pixelSize: Config.fontSizeLarge
                    Layout.fillWidth: true
                }

                Rectangle {
                    Layout.preferredWidth: 200
                    Layout.preferredHeight: 32
                    radius: Config.radiusSmall
                    color: Qt.alpha(Config.surface0Color, 0.6)

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 6

                        Text {
                            text: "󰍉"
                            font.family: Config.font
                            font.pixelSize: Config.fontSizeSmall
                            color: Config.subtextColor
                        }

                        TextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            verticalAlignment: TextInput.AlignVCenter
                            color: Config.textColor
                            font.family: Config.font
                            font.pixelSize: Config.fontSizeNormal
                            clip: true

                            property string placeholder: "Search keybinds..."
                            property bool showingPlaceholder: text.length === 0

                            Text {
                                anchors.fill: parent
                                visible: parent.showingPlaceholder
                                text: parent.placeholder
                                color: Config.subtextColor
                                font: parent.font
                                verticalAlignment: TextInput.AlignVCenter
                                elide: Text.ElideRight
                            }

                            onTextChanged: root.filterText = text
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Config.surface1Color
            }

            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: sections.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: sections
                    width: parent.width
                    spacing: 14

                    KeybindSection {
                        title: "Apps"
                        icon: "󰀻"
                        filterText: root.filterText
                        keybinds: [
                            { keys: "Alt + T", action: "Terminal" },
                            { keys: "Alt + F", action: "File Manager" },
                            { keys: "Alt + B", action: "Browser" },
                            { keys: "Alt + M", action: "Music (Spotify)" },
                            { keys: "Alt + Space", action: "App Launcher" },
                        ]
                    }

                    KeybindSection {
                        title: "Windows"
                        icon: "󰖯"
                        filterText: root.filterText
                        keybinds: [
                            { keys: "Alt + Q", action: "Kill window" },
                            { keys: "Alt + Shift + Q", action: "Exit Hyprland" },
                            { keys: "Alt + P", action: "Pseudo tile" },
                            { keys: "Alt + Shift + T", action: "Toggle floating" },
                            { keys: "Alt + Shift + F", action: "Fullscreen" },
                            { keys: "Alt + Shift + = / -", action: "Resize window" },
                            { keys: "Alt + H J K L", action: "Move focus" },
                            { keys: "Alt + Shift + H J K L", action: "Move window" },
                        ]
                    }

                    KeybindSection {
                        title: "Workspaces"
                        icon: "󰍹"
                        filterText: root.filterText
                        keybinds: [
                            { keys: "Alt + 1-0", action: "Switch workspace" },
                            { keys: "Alt + Shift + 1-0", action: "Move to workspace" },
                            { keys: "Alt + Ctrl + H / L", action: "Prev / Next workspace" },
                            { keys: "Alt + S", action: "Magic scratchpad" },
                            { keys: "Alt + Shift + S", action: "Move to scratchpad" },
                            { keys: "Super + W", action: "Cycle wallpaper" },
                        ]
                    }

                    KeybindSection {
                        title: "System"
                        icon: "󰒓"
                        filterText: root.filterText
                        keybinds: [
                            { keys: "Alt + W", action: "Settings Panel" },
                            { keys: "Super + V", action: "Clipboard History" },
                            { keys: "Super + L", action: "Lock screen" },
                            { keys: "Super + S", action: "Screenshot" },
                            { keys: "PowerOff", action: "Power menu" },
                        ]
                    }

                    KeybindSection {
                        title: "Media"
                        icon: "󰎈"
                        filterText: root.filterText
                        keybinds: [
                            { keys: "Volume Keys", action: "Volume up / down / mute" },
                            { keys: "Brightness Keys", action: "Brightness up / down" },
                            { keys: "Media Keys", action: "Play / Pause / Next / Prev" },
                        ]
                    }

                    Item {
                        Layout.preferredHeight: 4
                    }
                }
            }
        }
    }

    component KeybindSection: ColumnLayout {
        property string title: ""
        property string icon: ""
        property string filterText: ""
        property var keybinds: []

        property var filteredKeybinds: {
            if (!filterText) return keybinds;
            var q = filterText.toLowerCase();
            return keybinds.filter(function(k) {
                return k.keys.toLowerCase().indexOf(q) >= 0 || k.action.toLowerCase().indexOf(q) >= 0;
            });
        }
        property bool hasMatches: filteredKeybinds.length > 0

        Layout.fillWidth: true
        spacing: 4
        visible: hasMatches

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: icon
                font.family: Config.font
                font.pixelSize: Config.fontSizeNormal
                color: Config.accentColor
            }

            Text {
                text: title
                font.family: Config.font
                font.pixelSize: Config.fontSizeNormal
                font.bold: true
                color: Config.textColor
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                Layout.alignment: Qt.AlignVCenter
                color: Config.surface1Color
            }
        }

        Repeater {
            model: filteredKeybinds

            delegate: Item {
                required property var modelData

                Layout.fillWidth: true
                Layout.preferredHeight: 28

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    Text {
                        text: modelData.keys
                        font.family: Config.font
                        font.pixelSize: Config.fontSizeNormal
                        font.bold: true
                        color: Config.accentColor
                        Layout.preferredWidth: 220
                        elide: Text.ElideRight
                    }

                    Text {
                        text: modelData.action
                        font.family: Config.font
                        font.pixelSize: Config.fontSizeNormal
                        color: Config.subtextColor
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
