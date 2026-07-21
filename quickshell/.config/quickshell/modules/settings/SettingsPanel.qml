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

    visible: true

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: SettingsService.panelVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "qs_modules"

    color: "transparent"

    readonly property int tabH: 32
    readonly property int itemH: 40
    readonly property int maxItems: Math.max(SettingsService.themes.length, SettingsService.fonts.length)

    MouseArea {
        anchors.fill: parent
        onClicked: SettingsService.hide()
    }

    Item {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.2
        width: 280
        height: 16 + tabH + 8 + (maxItems * itemH)
        visible: SettingsService.panelVisible
        opacity: visible ? 1 : 0

        Behavior on opacity { NumberAnimation { duration: 150 } }

        Rectangle {
            anchors.fill: parent
            radius: Config.radiusLarge
            color: Config.backgroundTransparentColor
            border.color: Qt.alpha(Config.accentColor, 0.2)
            border.width: 1

            Keys.onEscapePressed: SettingsService.hide()
            Keys.onReturnPressed: SettingsService.activate(SettingsService.selectedIndex)

            Keys.onUpPressed: {
                if (SettingsService.selectedIndex > 0)
                    SettingsService.selectedIndex--
            }

            Keys.onDownPressed: {
                if (SettingsService.selectedIndex < SettingsService.currentItems.length - 1)
                    SettingsService.selectedIndex++
            }

            Keys.onLeftPressed: {
                var idx = SettingsService.sections.findIndex(function(s) { return s.name === SettingsService.section })
                if (idx > 0) {
                    SettingsService.section = SettingsService.sections[idx - 1].name
                    SettingsService.selectedIndex = 0
                }
            }

            Keys.onRightPressed: {
                var idx = SettingsService.sections.findIndex(function(s) { return s.name === SettingsService.section })
                if (idx < SettingsService.sections.length - 1) {
                    SettingsService.section = SettingsService.sections[idx + 1].name
                    SettingsService.selectedIndex = 0
                }
            }

            Component.onCompleted: forceActiveFocus()
        }

        Rectangle {
            x: 8
            y: 8
            width: 264
            height: tabH
            radius: Config.radius
            color: Config.surface1Color

            Row {
                anchors.fill: parent
                spacing: 4

                Repeater {
                    model: SettingsService.sections

                    Rectangle {
                        required property var modelData
                        width: (parent.width - 4) / SettingsService.sections.length
                        height: parent.height
                        radius: Config.radius
                        color: SettingsService.section === modelData.name ? Config.accentColor : "transparent"

                        Behavior on color {
                            ColorAnimation { duration: Config.animDurationShort }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: modelData.label
                            color: Config.textColor
                            font.family: Config.font
                            font.pixelSize: Config.fontSizeNormal
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                SettingsService.section = modelData.name
                                SettingsService.selectedIndex = 0
                            }
                        }
                    }
                }
            }
        }

        ListView {
            x: 8
            y: 8 + tabH + 8
            width: 264
            height: maxItems * itemH
            spacing: 2
            interactive: false

            model: SettingsService.currentItems
            currentIndex: SettingsService.selectedIndex
            highlightFollowsCurrentItem: true

            delegate: Item {
                required property int index
                required property var modelData

                width: ListView.view.width
                height: itemH

                property bool isCurrent: index === ListView.view.currentIndex
                property bool isActive: {
                    if (modelData.type === "theme")
                        return modelData.name === SettingsService.currentTheme
                    return modelData.name === SettingsService.currentFont
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 2
                    radius: Config.radiusSmall
                    color: isCurrent ? Config.surface2Color : "transparent"

                    Behavior on color {
                        ColorAnimation { duration: Config.animDurationShort }
                    }
                }

                Text {
                    x: 12
                    y: 0
                    width: parent.width - 36
                    height: parent.height
                    text: modelData.name
                    color: Config.textColor
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeNormal
                    font.bold: isActive
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }

                Text {
                    x: parent.width - 24
                    y: 0
                    width: 16
                    height: parent.height
                    text: "✓"
                    color: Config.accentColor
                    font.pixelSize: Config.fontSizeSmall
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    visible: isActive
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        SettingsService.selectedIndex = index
                        SettingsService.activate(index)
                    }
                }
            }
        }
    }

    HyprlandFocusGrab {
        windows: [root]
        active: SettingsService.panelVisible
        onCleared: {
            if (SettingsService.panelVisible)
                SettingsService.hide()
        }
    }
}
