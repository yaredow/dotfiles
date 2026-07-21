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

    MouseArea {
        anchors.fill: parent
        onClicked: SettingsService.hide()
    }

    AnimatedPopup {
        anchors.centerIn: parent
        width: Math.min(800, root.width - 100)
        height: Math.min(600, root.height - 100)
        shown: SettingsService.panelVisible

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // Header
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                color: Config.surface1Color
                radius: 10

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 8

                    Text {
                        text: "Settings"
                        color: Config.textColor
                        font.pixelSize: Config.fontSizeLarge
                        font.bold: true
                    }

                    Item { Layout.fillWidth: true }

                    ActionButton {
                        text: "󰅜"
                        baseColor: "transparent"
                        hoverColor: Config.surface2Color
                        textColor: Config.subtextColor
                        onClicked: SettingsService.hide()
                    }
                }
            }

            // Section tabs
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                color: Config.surface0Color

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    Repeater {
                        model: SettingsService.sections

                        ActionButton {
                            required property var modelData
                            text: modelData.icon + " " + modelData.label
                            baseColor: SettingsService.currentSection === modelData.name ? Config.accentColor : "transparent"
                            hoverColor: SettingsService.currentSection === modelData.name ? Config.accentColor : Config.surface1Color
                            textColor: SettingsService.currentSection === modelData.name ? Config.textReverseColor : Config.subtextColor
                            onClicked: SettingsService.currentSection = modelData.name
                        }
                    }
                }
            }

            // Content
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Config.backgroundColor

                StackLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    currentIndex: {
                        switch (SettingsService.currentSection) {
                            case "wallpaper": return 0;
                            case "theme": return 1;
                            case "font": return 2;
                            default: return 0;
                        }
                    }

                    // === WALLPAPER SECTION ===
                    ColumnLayout {
                        spacing: 8

                        TextField {
                            id: searchField
                            Layout.fillWidth: true
                            Layout.preferredHeight: 36
                            placeholderText: "Search wallpapers..."
                            color: Config.textColor
                            placeholderTextColor: Config.subtextColor
                            backgroundColor: Config.surface0Color
                            onTextChanged: SettingsService.searchQuery = text

                            background: Rectangle {
                                color: Config.surface0Color
                                radius: 6
                                border.color: searchField.activeFocus ? Config.accentColor : "transparent"
                            }
                        }

                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true

                            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                            ScrollBar.vertical.policy: ScrollBar.AsNeeded

                            GridView {
                                id: wallpaperGrid
                                anchors.fill: parent
                                cellWidth: 160
                                cellHeight: 120
                                model: SettingsService.filteredWallpapers
                                delegate: wallpaperDelegate
                                boundsBehavior: Flickable.StopAtBounds
                            }
                        }

                        Text {
                            visible: SettingsService.filteredWallpapers.length === 0
                            text: "No wallpapers in ~/.local/wallpapers/"
                            color: Config.subtextColor
                            font.pixelSize: Config.fontSizeNormal
                            Layout.alignment: Qt.AlignCenter
                        }

                        Component {
                            id: wallpaperDelegate

                            Item {
                                width: wallpaperGrid.cellWidth
                                height: wallpaperGrid.cellHeight
                                property string path: modelData
                                property bool isCurrent: path === SettingsService.currentWallpaper

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    radius: 6
                                    border.width: parent.isCurrent ? 2 : 0
                                    border.color: Config.accentColor
                                    color: "transparent"

                                    Image {
                                        anchors.fill: parent
                                        source: "file://" + parent.parent.path
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                        sourceSize { width: 160; height: 120 }
                                    }

                                    Rectangle {
                                        anchors.bottom: parent.bottom
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        height: 20
                                        color: Qt.rgba(0, 0, 0, 0.5)
                                        radius: 6

                                        Text {
                                            anchors.centerIn: parent
                                            text: parent.parent.parent.path.split("/").pop()
                                            color: "white"
                                            font.pixelSize: 10
                                            elide: Text.ElideLeft
                                            maximumLineCount: 1
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: SettingsService.setWallpaper(parent.parent.path)
                                    }
                                }
                            }
                        }
                    }

                    // === THEME SECTION ===
                    ColumnLayout {
                        spacing: 12

                        Text {
                            text: "Select a theme"
                            color: Config.textColor
                            font.pixelSize: Config.fontSizeNormal
                        }

                        GridView {
                            id: themeGrid
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            cellWidth: 220
                            cellHeight: 160
                            model: SettingsService.availableThemes
                            delegate: themeDelegate
                            boundsBehavior: Flickable.StopAtBounds
                            clip: true
                        }

                        Component {
                            id: themeDelegate

                            Item {
                                width: themeGrid.cellWidth
                                height: themeGrid.cellHeight
                                property string themeName: modelData
                                property bool isActive: themeName === SettingsService.currentTheme

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: 6
                                    radius: 10
                                    border.width: parent.isActive ? 2 : 1
                                    border.color: parent.isActive ? Config.accentColor : Config.surface2Color
                                    color: Config.surface0Color

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 12
                                        spacing: 8

                                        // Palette preview strip
                                        RowLayout {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 24
                                            spacing: 2

                                            property var colors: {
                                                switch (parent.parent.parent.themeName) {
                                                    case "tokyonight": return ["#1a1b26","#292e42","#565f89","#7aa2f7","#bb9af7","#9ece6a","#f7768e"];
                                                    case "catppuccin": return ["#1e1e2e","#313244","#6c7086","#89b4fa","#cba6f7","#a6e3a1","#f38ba8"];
                                                    case "rosepine": return ["#232136","#2a273f","#555169","#9ccfd8","#c4a7e7","#3e8fb0","#eb6f92"];
                                                    default: return ["#1a1b26","#292e42","#565f89","#7aa2f7","#bb9af7","#9ece6a","#f7768e"];
                                                }
                                            }

                                            Repeater {
                                                model: parent.colors
                                                Rectangle {
                                                    width: 24
                                                    height: 24
                                                    radius: 4
                                                    color: modelData
                                                }
                                            }
                                        }

                                        Text {
                                            text: parent.parent.parent.themeName
                                            color: Config.textColor
                                            font.pixelSize: Config.fontSizeNormal
                                            font.bold: parent.parent.parent.isActive
                                        }

                                        Text {
                                            text: parent.parent.parent.isActive ? "Active" : ""
                                            color: Config.accentColor
                                            font.pixelSize: Config.fontSizeSmall
                                        }

                                        Item { Layout.fillHeight: true }

                                        ActionButton {
                                            Layout.fillWidth: true
                                            text: parent.parent.parent.isActive ? "✓ Applied" : "Apply"
                                            baseColor: parent.parent.parent.isActive ? Config.accentColor : Config.surface1Color
                                            hoverColor: Config.surface2Color
                                            textColor: parent.parent.parent.isActive ? Config.textReverseColor : Config.textColor
                                            onClicked: SettingsService.setTheme(parent.parent.parent.themeName)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // === FONT SECTION ===
                    ColumnLayout {
                        spacing: 12

                        Text {
                            text: "Select a terminal font"
                            color: Config.textColor
                            font.pixelSize: Config.fontSizeNormal
                        }

                        ListView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            model: SettingsService.availableFonts
                            delegate: fontDelegate
                            clip: true
                            spacing: 4
                        }

                        Component {
                            id: fontDelegate

                            Rectangle {
                                width: ListView.view.width
                                height: 48
                                radius: 8
                                border.width: modelData === SettingsService.currentFont ? 2 : 1
                                border.color: modelData === SettingsService.currentFont ? Config.accentColor : Config.surface2Color
                                color: modelData === SettingsService.currentFont ? Qt.alpha(Config.accentColor, 0.1) : Config.surface0Color

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 8
                                    spacing: 12

                                    Text {
                                        text: ""
                                        color: modelData === SettingsService.currentFont ? Config.accentColor : Config.subtextColor
                                        font.pixelSize: Config.fontSizeIcon
                                    }

                                    ColumnLayout {
                                        spacing: 2
                                        Text {
                                            text: modelData
                                            color: Config.textColor
                                            font.pixelSize: Config.fontSizeNormal
                                            font.family: modelData
                                        }
                                        Text {
                                            text: modelData === SettingsService.currentFont ? "Active" : ""
                                            color: Config.accentColor
                                            font.pixelSize: Config.fontSizeSmall
                                            visible: modelData === SettingsService.currentFont
                                        }
                                    }

                                    Item { Layout.fillWidth: true }

                                    ActionButton {
                                        text: modelData === SettingsService.currentFont ? "✓" : "Apply"
                                        baseColor: modelData === SettingsService.currentFont ? Config.accentColor : Config.surface1Color
                                        hoverColor: Config.surface2Color
                                        textColor: modelData === SettingsService.currentFont ? Config.textReverseColor : Config.textColor
                                        onClicked: {
                                            if (modelData !== SettingsService.currentFont)
                                                SettingsService.setFont(modelData);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
