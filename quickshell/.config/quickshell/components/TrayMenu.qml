pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.config
import qs.services

PanelWindow {
    id: root

    property var rootMenuHandle: null
    property int anchorX: 0
    property int anchorY: 0

    color: "transparent"

    implicitWidth: Math.max(220, mainColumn.implicitWidth)
    implicitHeight: mainColumn.implicitHeight

    WlrLayershell.namespace: "qs_modules"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.exclusiveZone: -1

    anchors { left: true; top: true }
    margins {
        left: Math.min(root.screen.width - implicitWidth - 10, root.anchorX)
        top: Math.min(root.screen.height - implicitHeight - 10, root.anchorY)
    }

    ListModel { id: menuStack }

    function pushSubMenu(menuItem) {
        if (menuItem && menuItem.menu) {
            menuStack.append({ "handle": menuItem.menu });
        }
    }

    function popSubMenu() {
        if (menuStack.count > 0)
            menuStack.remove(menuStack.count - 1);
    }

    property var currentMenuHandle: {
        if (menuStack.count > 0)
            return menuStack.get(menuStack.count - 1).handle;
        return root.rootMenuHandle;
    }

    HyprlandFocusGrab {
        id: focusGrab
        windows: [root]
        active: false
        onCleared: root.close()
    }

    function open() {
        root.visible = true;
        focusTimer.restart();
    }

    function close() {
        root.visible = false;
        menuStack.clear();
        focusGrab.active = false;
    }

    Timer {
        id: focusTimer
        interval: 50
        onTriggered: {
            focusGrab.active = true;
            background.forceActiveFocus();
        }
    }

    QsMenuOpener {
        id: menuOpener
        menu: root.currentMenuHandle
    }

    Rectangle {
        id: background
        anchors.fill: parent
        color: Config.backgroundTransparentColor
        border.color: Config.surface2Color
        border.width: 1
        radius: Config.radius
        clip: true

        focus: true
        Keys.onEscapePressed: {
            if (menuStack.count > 0)
                popSubMenu();
            else
                root.close();
        }

        ColumnLayout {
            id: mainColumn
            width: parent.width
            spacing: 0

            Rectangle {
                visible: menuStack.count > 0
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                color: backMouse.containsMouse ? Config.surface2Color : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    spacing: 5
                    Text {
                        text: String.fromCodePoint(0x2190) + " Back"
                        color: Config.accentColor
                        font.family: Config.font
                        font.bold: true
                        font.pixelSize: 12
                    }
                }
                MouseArea {
                    id: backMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: popSubMenu()
                }
            }

            Rectangle {
                visible: menuStack.count > 0
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Config.surface2Color
            }

            Repeater {
                model: menuOpener.children

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    property bool isSeparator: modelData.type === "separator" || modelData.isSeparator === true
                    property bool isEnabled: modelData.enabled !== false
                    property bool hasSubMenu: (modelData.children && modelData.children.length > 0) || modelData.type === "menu"

                    Layout.preferredWidth: mainColumn.width - 3
                    Layout.preferredHeight: isSeparator ? 8 : 32
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                    color: itemMouse.containsMouse && !isSeparator ? Config.surface2Color : "transparent"
                    radius: Config.radiusSmall
                    opacity: isEnabled ? 1.0 : 0.5

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width - 10
                        height: 1
                        color: Config.surface2Color
                        visible: parent.isSeparator
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8
                        visible: !parent.isSeparator

                        Image {
                            Layout.preferredWidth: 16
                            Layout.preferredHeight: 16
                            source: modelData.icon ? TrayService.getMenuIconSource(modelData.icon) : ""
                            visible: source !== "" && status === Image.Ready
                            sourceSize: Qt.size(16, 16)
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            asynchronous: true
                        }

                        Text {
                            text: {
                                var t = modelData.text || modelData.title || "";
                                return t.replace(/&/g, "").replace(/_/g, "");
                            }
                            color: Config.textColor
                            font.family: Config.font
                            font.pixelSize: 12
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            visible: parent.parent.hasSubMenu
                            text: String.fromCodePoint(0x203A)
                            color: Config.subtextColor
                            font.pixelSize: 14
                        }
                    }

                    // Checkmark/radio indicator
                    Rectangle {
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        width: 10; height: 10
                        radius: modelData.toggleType === 2 ? 5 : 2
                        color: "transparent"
                        border.color: Config.textColor
                        visible: modelData.toggleType > 0 && (modelData.checked === true || modelData.status === "active")
                        Rectangle {
                            anchors.centerIn: parent
                            width: 6; height: 6
                            radius: parent.radius - 1
                            color: Config.textColor
                        }
                    }

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: !parent.isSeparator && parent.isEnabled
                        enabled: hoverEnabled
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            if (parent.hasSubMenu) {
                                root.pushSubMenu(modelData);
                            } else {
                                if (typeof modelData.activate === 'function')
                                    modelData.activate();
                                else if (typeof modelData.triggered === 'function')
                                    modelData.triggered();
                                root.close();
                            }
                        }
                    }
                }
            }
        }
    }
}
