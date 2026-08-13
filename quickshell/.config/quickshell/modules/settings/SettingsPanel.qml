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
    readonly property int panelWidth: 300

    function hide() {
        settingsPanel.forceActiveFocus();
        SettingsService.hide();
    }

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: SettingsService.panelVisible ? 0.32 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: Config.animDuration
                easing.type: Easing.OutCubic
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.hide()
        }
    }

    AnimatedPopup {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.2
        width: root.panelWidth
        height: settingsPanel.height
        shown: SettingsService.panelVisible

        Rectangle {
            id: settingsPanel
            width: root.panelWidth

            property int visibleCount: Math.min(SettingsService.maxVisibleItems, Math.max(SettingsService.filteredItems.length, 1))
            property int listHeight: visibleCount * root.itemH
            property int totalHeight: 8 + root.tabH + 6 + 32 + 6 + listHeight + 8

            height: totalHeight
            radius: Config.radiusLarge
            color: Config.backgroundTransparentColor
            border.color: Qt.alpha(Config.accentColor, 0.35)
            border.width: 1

            Behavior on height {
                NumberAnimation {
                    duration: Config.animDuration
                    easing.type: Easing.OutCubic
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 6

                Row {
                    Layout.fillWidth: true
                    height: root.tabH
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
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: parent.width * 0.5
                                height: 2
                                radius: 1
                                color: SettingsService.section === modelData.name ? Config.accentColor : "transparent"
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: SettingsService.setSection(modelData.name)
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
                    placeholderText: SettingsService.section === "theme" ? "Search themes…" : "Search fonts…"
                    placeholderTextColor: Config.subtextColor

                    background: Rectangle {
                        radius: Config.radiusSmall
                        color: Qt.alpha(Config.surface0Color, 0.4)
                    }

                    onTextChanged: {
                        if (SettingsService.query !== text)
                            SettingsService.query = text;
                    }

                    Keys.onEscapePressed: root.hide()

                    Keys.onReturnPressed: {
                        settingsPanel.forceActiveFocus();
                        SettingsService.activateSelected();
                    }

                    Keys.onUpPressed: SettingsService.navigateUp()
                    Keys.onDownPressed: SettingsService.navigateDown()

                    Keys.onLeftPressed: event => {
                        // Empty query: switch tabs. Otherwise keep caret motion.
                        if (SettingsService.query.length === 0) {
                            SettingsService.cycleSection(-1);
                            event.accepted = true;
                        }
                    }

                    Keys.onRightPressed: event => {
                        if (SettingsService.query.length === 0) {
                            SettingsService.cycleSection(1);
                            event.accepted = true;
                        }
                    }

                    Keys.onTabPressed: event => {
                        SettingsService.navigateDown();
                        event.accepted = true;
                    }

                    Keys.onPressed: event => {
                        const ctrl = event.modifiers & Qt.ControlModifier;
                        const isBacktab = event.key === Qt.Key_Backtab;
                        const isShiftTab = event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier);

                        if (isBacktab || isShiftTab) {
                            SettingsService.navigateUp();
                            event.accepted = true;
                            return;
                        }

                        if (!ctrl)
                            return;

                        if (event.key === Qt.Key_J) {
                            SettingsService.navigateDown();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_K) {
                            SettingsService.navigateUp();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_D) {
                            SettingsService.navigateBy(5);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_U) {
                            SettingsService.navigateBy(-5);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Left) {
                            SettingsService.cycleSection(-1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Right) {
                            SettingsService.cycleSection(1);
                            event.accepted = true;
                        }
                    }

                    function syncFromService() {
                        if (text !== SettingsService.query)
                            text = SettingsService.query;
                    }

                    function focusSearch() {
                        syncFromService();
                        Qt.callLater(() => {
                            if (SettingsService.panelVisible)
                                forceActiveFocus();
                        });
                    }

                    Component.onCompleted: focusSearch()
                }

                ListView {
                    id: itemList
                    Layout.fillWidth: true
                    Layout.preferredHeight: settingsPanel.listHeight
                    clip: true
                    spacing: 2
                    interactive: SettingsService.filteredItems.length > SettingsService.maxVisibleItems
                    boundsBehavior: Flickable.StopAtBounds

                    model: SettingsService.filteredItems
                    currentIndex: SettingsService.selectedIndex

                    highlightFollowsCurrentItem: false
                    highlight: Rectangle {
                        width: itemList.width
                        height: root.itemH
                        radius: Config.radiusSmall
                        color: Config.surface2Color
                        y: itemList.currentItem ? itemList.currentItem.y : 0

                        Behavior on y {
                            NumberAnimation {
                                duration: Config.animDurationShort
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    delegate: Item {
                        id: delegateItem
                        required property int index
                        required property var modelData

                        width: ListView.view.width
                        height: root.itemH

                        property bool isCurrent: index === SettingsService.selectedIndex
                        property bool isActive: SettingsService.isItemActive(modelData)

                        Text {
                            anchors.left: parent.left
                            anchors.right: checkMark.left
                            anchors.leftMargin: 12
                            anchors.rightMargin: 8
                            height: parent.height
                            text: modelData.name
                            color: Config.textColor
                            // Preview the actual UI font on font rows
                            font.family: modelData.type === "font" ? (modelData.font || Config.font) : Config.font
                            font.pixelSize: Config.fontSizeNormal
                            font.bold: isActive
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }

                        Text {
                            id: checkMark
                            anchors.right: parent.right
                            anchors.rightMargin: 12
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
                            onEntered: SettingsService.selectedIndex = index
                            onClicked: {
                                settingsPanel.forceActiveFocus();
                                SettingsService.activate(index);
                            }
                        }
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 6
                        visible: itemList.count === 0

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "No results"
                            color: Config.subtextColor
                            font.family: Config.font
                            font.pixelSize: Config.fontSizeSmall
                        }
                    }

                    onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                    ScrollBar.vertical: ScrollBar {
                        policy: itemList.interactive ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
                        contentItem: Rectangle {
                            implicitWidth: 4
                            radius: 2
                            color: Config.surface2Color
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: SettingsService

        function onPanelVisibleChanged() {
            if (SettingsService.panelVisible)
                searchInput.focusSearch();
        }

        function onQueryChanged() {
            searchInput.syncFromService();
        }

        function onSectionChanged() {
            searchInput.focusSearch();
        }
    }

    HyprlandFocusGrab {
        windows: [root]
        active: SettingsService.panelVisible
        onCleared: {
            if (SettingsService.panelVisible)
                root.hide();
        }
    }
}
