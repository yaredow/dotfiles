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

    MouseArea {
        anchors.fill: parent
        onClicked: SettingsService.hide()
    }

    Item {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.2
        width: 280
        height: { var n = Math.max(SettingsService.themes.length, SettingsService.fonts.length); return 16 + tabH + 8 + 36 + 4 + (n * itemH); }
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
            Keys.onReturnPressed: {
                if (SettingsService.filteredItems.length > 0)
                    SettingsService.activate(SettingsService.selectedIndex)
            }

            Keys.onUpPressed: {
                if (SettingsService.selectedIndex > 0)
                    SettingsService.selectedIndex--
            }

            Keys.onDownPressed: {
                if (SettingsService.selectedIndex < SettingsService.filteredItems.length - 1)
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

            Component.onCompleted: searchInput.forceActiveFocus()
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 6

            Row {
                Layout.fillWidth: true
                height: tabH
                spacing: 4

                Repeater {
                    model: SettingsService.sections

                    Rectangle {
                        required property var modelData
                        width: (parent.width - 4) / SettingsService.sections.length
                        height: parent.height
                        radius: Config.radius

                        color: "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: modelData.label
                            color: SettingsService.section === modelData.name ? Config.accentColor : Config.subtextColor
                            font.family: Config.font
                            font.pixelSize: Config.fontSizeNormal
                            font.bold: SettingsService.section === modelData.name
                        }

                        Rectangle {
                            anchors {
                                bottom: parent.bottom
                                horizontalCenter: parent.horizontalCenter
                            }
                            width: parent.width * 0.5
                            height: 2
                            radius: 1
                            color: SettingsService.section === modelData.name ? Config.accentColor : "transparent"
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

            TextField {
                id: searchInput
                Layout.fillWidth: true
                Layout.preferredHeight: 32

                color: Config.textColor
                font.family: Config.font
                font.pixelSize: Config.fontSizeNormal
                verticalAlignment: TextInput.AlignVCenter
                selectByMouse: true
                placeholderText: "Search..."
                placeholderTextColor: Config.subtextColor

                background: Rectangle {
                    radius: Config.radiusSmall
                    color: Qt.alpha(Config.surface0Color, 0.4)
                }

                onTextChanged: SettingsService.query = text

                Keys.onEscapePressed: SettingsService.hide()
                Keys.onReturnPressed: {
                    if (SettingsService.filteredItems.length > 0)
                        SettingsService.activate(SettingsService.selectedIndex)
                }
                Keys.onUpPressed: {
                    if (SettingsService.selectedIndex > 0)
                        SettingsService.selectedIndex--
                }
                Keys.onDownPressed: {
                    if (SettingsService.selectedIndex < SettingsService.filteredItems.length - 1)
                        SettingsService.selectedIndex++
                }
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_J && (event.modifiers & Qt.ControlModifier)) {
                        if (SettingsService.selectedIndex < SettingsService.filteredItems.length - 1)
                            SettingsService.selectedIndex++;
                        event.accepted = true;
                    } else if (event.key === Qt.Key_K && (event.modifiers & Qt.ControlModifier)) {
                        if (SettingsService.selectedIndex > 0)
                            SettingsService.selectedIndex--;
                        event.accepted = true;
                    }
                }
            }

            ListView {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.max(SettingsService.themes.length, SettingsService.fonts.length) * itemH
                Layout.fillHeight: true
                clip: true

                spacing: 2
                interactive: false

                model: SettingsService.filteredItems
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
