pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services
import qs.config
import "../../components/"

PanelWindow {
    id: root

    visible: true

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.namespace: "qs_modules"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: LauncherService.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    color: "transparent"

    function hide() {
        launcherPanel.forceActiveFocus();
        LauncherService.hide();
    }

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: LauncherService.visible ? 0.32 : 0

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
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.12
        anchors.horizontalCenter: parent.horizontalCenter
        width: 520
        height: launcherPanel.height
        shown: LauncherService.visible

        Rectangle {
            id: launcherPanel
            width: 520

            property bool showHints: LauncherService.query.length === 0 && LauncherService.provider === "apps"
            property bool showRecentLabel: showHints && appList.count > 0
            property bool showEmptyState: {
                const q = LauncherService.query.trim();
                if (appList.count > 0)
                    return false;
                if (LauncherService.provider === "apps")
                    return q !== "";
                return q.length > 0;
            }
            property int hintsHeight: showHints ? 26 : 0
            property int recentLabelHeight: showRecentLabel ? 18 : 0
            property int listHeight: appList.count > 0 ? Math.min(420, appList.contentHeight + 12) : (showEmptyState ? 120 : 0)
            property int totalHeight: 52 + 24 + hintsHeight + recentLabelHeight + listHeight + (hintsHeight > 0 ? Config.spacing : 0) + (recentLabelHeight > 0 ? Config.spacing : 0) + (listHeight > 0 ? Config.spacing : 0)

            height: totalHeight
            radius: Config.radiusLarge
            color: Config.backgroundTransparentColor
            border.color: Qt.alpha(Config.accentColor, 0.6)
            border.width: 2

            Behavior on height {
                NumberAnimation {
                    duration: Config.animDuration
                    easing.type: Easing.OutCubic
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Config.spacing + 4
                spacing: Config.spacing

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    color: "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Config.spacing + 6
                        anchors.rightMargin: Config.spacing + 6
                        spacing: Config.spacing

                        TextField {
                            id: searchInput
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            color: Config.textColor
                            font.family: Config.monoFont
                            font.pixelSize: Config.fontSizeNormal
                            verticalAlignment: TextInput.AlignVCenter
                            selectByMouse: true
                            placeholderText: LauncherService.placeholder
                            placeholderTextColor: Config.mutedColor
                            background: null

                            onTextChanged: {
                                if (LauncherService.query !== text)
                                    LauncherService.query = text;
                            }

                            Keys.onEscapePressed: root.hide()

                            Keys.onReturnPressed: {
                                launcherPanel.forceActiveFocus();
                                LauncherService.launchSelected();
                            }

                            Keys.onUpPressed: LauncherService.navigateUp()

                            Keys.onDownPressed: LauncherService.navigateDown()

                            Keys.onTabPressed: event => {
                                LauncherService.navigateDown();
                                event.accepted = true;
                            }

                            Keys.onPressed: event => {
                                const ctrl = event.modifiers & Qt.ControlModifier;
                                const isBacktab = event.key === Qt.Key_Backtab;
                                const isShiftTab = event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier);

                                if (isBacktab || isShiftTab) {
                                    LauncherService.navigateUp();
                                    event.accepted = true;
                                    return;
                                }

                                if (!ctrl)
                                    return;

                                // nvim-style list motion
                                if (event.key === Qt.Key_J) {
                                    LauncherService.navigateDown();
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_K) {
                                    LauncherService.navigateUp();
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_D) {
                                    LauncherService.navigateBy(5);
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_U) {
                                    LauncherService.navigateBy(-5);
                                    event.accepted = true;
                                }
                            }

                            function syncFromService() {
                                if (text !== LauncherService.query)
                                    text = LauncherService.query;
                            }

                            function focusSearch() {
                                syncFromService();
                                Qt.callLater(() => {
                                    if (LauncherService.visible)
                                        forceActiveFocus();
                                });
                            }

                            Component.onCompleted: focusSearch()
                        }

                        Rectangle {
                            visible: LauncherService.filteredApps.length > 0
                            Layout.preferredWidth: countText.implicitWidth + 12
                            Layout.preferredHeight: 22
                            radius: height / 2
                            color: Config.surface1Color

                            Text {
                                id: countText
                                anchors.centerIn: parent
                                text: LauncherService.filteredApps.length
                                font.family: Config.monoFont
                                font.pixelSize: Config.fontSizeSmall
                                color: Config.subtextColor
                            }
                        }

                        Rectangle {
                            visible: LauncherService.providerLabel !== ""
                            Layout.preferredWidth: modeLabel.implicitWidth + 12
                            Layout.preferredHeight: 22
                            radius: height / 2
                            color: Config.accentColor

                            Text {
                                id: modeLabel
                                anchors.centerIn: parent
                                text: LauncherService.providerLabel
                                font.family: Config.monoFont
                                font.pixelSize: Config.fontSizeSmall
                                color: Config.textColor
                            }
                        }

                        Rectangle {
                            visible: searchInput.text
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 28
                            radius: height / 2
                            color: clearMouse.containsMouse ? Config.surface2Color : "transparent"

                            Behavior on color {
                                ColorAnimation {
                                    duration: Config.animDurationShort
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "󰅖"
                                font.family: Config.monoFont
                                font.pixelSize: Config.fontSizeSmall
                                color: Config.subtextColor
                            }

                            MouseArea {
                                id: clearMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    searchInput.text = "";
                                    searchInput.forceActiveFocus();
                                }
                            }
                        }
                    }
                }

                // Prefix discovery — only on a blank apps search
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: launcherPanel.hintsHeight
                    Layout.leftMargin: Config.spacing + 6
                    Layout.rightMargin: Config.spacing + 6
                    visible: launcherPanel.showHints
                    spacing: 10

                    Repeater {
                        model: [
                            { prefix: "=", label: "math" },
                            { prefix: ">", label: "run" },
                            { prefix: "?", label: "web" },
                            { prefix: ":", label: "clip" },
                            { prefix: "/", label: "files" },
                            { prefix: ";", label: "actions" }
                        ]

                        delegate: Item {
                            id: hintItem
                            required property var modelData

                            // Fixed height so glyph metrics (e.g. ";") can't shift a cell vertically
                            Layout.preferredWidth: hintRow.implicitWidth
                            Layout.preferredHeight: launcherPanel.hintsHeight
                            Layout.alignment: Qt.AlignVCenter
                            width: hintRow.implicitWidth
                            height: launcherPanel.hintsHeight

                            Row {
                                id: hintRow
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4

                                Text {
                                    text: hintItem.modelData.prefix
                                    color: Config.accentColor
                                    font.family: Config.monoFont
                                    font.pixelSize: Config.fontSizeSmall
                                    font.weight: Font.DemiBold
                                    height: Config.fontSizeSmall + 4
                                    verticalAlignment: Text.AlignVCenter
                                }

                                Text {
                                    text: hintItem.modelData.label
                                    color: Config.mutedColor
                                    font.family: Config.monoFont
                                    font.pixelSize: Config.fontSizeSmall
                                    height: Config.fontSizeSmall + 4
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    LauncherService.setProviderPrefix(hintItem.modelData.prefix);
                                    searchInput.focusSearch();
                                }
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }
                }

                Text {
                    Layout.fillWidth: true
                    Layout.preferredHeight: launcherPanel.recentLabelHeight
                    Layout.leftMargin: Config.spacing + 6
                    visible: launcherPanel.showRecentLabel
                    text: "Recent"
                    color: Config.mutedColor
                    font.family: Config.monoFont
                    font.pixelSize: Config.fontSizeSmall
                    font.weight: Font.DemiBold
                }

                ListView {
                    id: appList
                    Layout.fillWidth: true
                    Layout.fillHeight: listHeight > 0
                    Layout.preferredHeight: launcherPanel.listHeight
                    visible: launcherPanel.listHeight > 0

                    clip: true
                    spacing: 4
                    model: LauncherService.filteredApps
                    currentIndex: LauncherService.selectedIndex

                    add: Transition {
                        NumberAnimation {
                            property: "opacity"
                            from: 0
                            to: 1
                            duration: Config.animDurationShort
                        }
                        NumberAnimation {
                            property: "scale"
                            from: 0.8
                            to: 1
                            duration: Config.animDurationShort
                            easing.type: Easing.OutBack
                        }
                    }

                    remove: Transition {
                        NumberAnimation {
                            property: "opacity"
                            to: 0
                            duration: Config.animDurationShort
                        }
                        NumberAnimation {
                            property: "scale"
                            to: 0.8
                            duration: Config.animDurationShort
                        }
                    }

                    displaced: Transition {
                        NumberAnimation {
                            property: "y"
                            duration: Config.animDuration
                            easing.type: Easing.OutCubic
                        }
                    }

                    highlightFollowsCurrentItem: false
                    highlight: Rectangle {
                        width: appList.width
                        height: 56
                        radius: Config.radius
                        color: Config.surface2Color

                        y: appList.currentItem ? appList.currentItem.y : 0

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

                        width: appList.width
                        height: 56

                        property bool isSelected: index === LauncherService.selectedIndex

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 14

                            Rectangle {
                                Layout.preferredWidth: 40
                                Layout.preferredHeight: 40
                                radius: Config.radiusSmall
                                color: "transparent"

                                Image {
                                    anchors.centerIn: parent
                                    width: 32
                                    height: 32
                                    source: {
                                        const item = delegateItem.modelData;
                                        if (!item)
                                            return "image://icon/application-x-executable";
                                        if (item._type === "file" && item.isVideo)
                                            return Qt.resolvedUrl("cinema.svg");
                                        const icon = item.icon ?? "";
                                        return icon ? "image://icon/" + icon : "image://icon/application-x-executable";
                                    }
                                    sourceSize: Qt.size(32, 32)
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    Layout.fillWidth: true
                                    text: LauncherService.highlightedName(delegateItem.modelData?.name ?? "", Config.accentColor)
                                    textFormat: Text.RichText
                                    color: Config.textColor
                                    font.family: Config.monoFont
                                    font.pixelSize: Config.fontSizeSmall
                                    font.weight: delegateItem.isSelected ? Font.DemiBold : Font.Normal
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: delegateItem.modelData?.comment || delegateItem.modelData?.genericName || ""
                                    color: Config.subtextColor
                                    font.family: Config.monoFont
                                    font.pixelSize: Config.fontSizeSmall
                                    elide: Text.ElideRight
                                    visible: text !== ""
                                }
                            }

                            Text {
                                visible: delegateItem.isSelected
                                text: LauncherService.actionVerb(delegateItem.modelData)
                                color: Config.accentColor
                                font.family: Config.monoFont
                                font.pixelSize: Config.fontSizeSmall
                                font.weight: Font.DemiBold
                            }
                        }

                        MouseArea {
                            id: delegateMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: LauncherService.selectedIndex = delegateItem.index
                            onClicked: {
                                launcherPanel.forceActiveFocus();
                                LauncherService.launch(delegateItem.modelData);
                            }
                        }
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: Config.spacing
                        visible: appList.count === 0
                        opacity: visible ? 1 : 0

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Config.animDurationShort
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: LauncherService.query ? "󰅖" : "󰍉"
                            font.family: Config.monoFont
                            font.pixelSize: Config.fontSizeIcon
                            color: Config.mutedColor

                            RotationAnimator on rotation {
                                from: 0
                                to: 360
                                duration: 1000
                                loops: Animation.Infinite
                                running: !!LauncherService.query && appList.count === 0
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: LauncherService.query ? "No results" : "Type to search"
                            color: Config.subtextColor
                            font.family: Config.monoFont
                            font.pixelSize: Config.fontSizeSmall
                        }
                    }

                    onCurrentIndexChanged: {
                        positionViewAtIndex(currentIndex, ListView.Contain);
                    }

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded

                        contentItem: Rectangle {
                            implicitWidth: 4
                            radius: 2
                            color: Config.surface2Color
                            opacity: parent.active ? 1 : 0

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: Config.animDurationShort
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: LauncherService

        function onVisibleChanged() {
            if (LauncherService.visible)
                searchInput.focusSearch();
        }

        function onQueryChanged() {
            searchInput.syncFromService();
        }
    }

    Shortcut {
        sequence: "Ctrl+F"
        context: Qt.ApplicationShortcut
        onActivated: {
            if (!LauncherService.visible)
                return;
            LauncherService.setProviderPrefix("/");
            searchInput.focusSearch();
        }
    }

    HyprlandFocusGrab {
        windows: [root]
        active: LauncherService.visible
        onCleared: {
            if (LauncherService.visible)
                root.hide();
        }
    }
}
