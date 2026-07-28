import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    width: Screen.width
    height: Screen.height
    color: config.backgroundColor ?? "#1e1e2e"
    focus: true

    property color accent: config.accentColor ?? "#cba6f7"
    property color textColor: config.textColor ?? "#cdd6f4"
    property color baseColor: config.backgroundColor ?? "#1e1e2e"
    property color surface0: "#313244"
    property color surface1: "#45475a"
    property color surface2: "#585b70"
    property color mutedColor: "#6c7086"
    property color errorColor: "#f38ba8"
    property string displayFont: config.font ?? "CaskaydiaCove Nerd Font"
    property bool use24Hour: config.use24HourClock === "true"
    property bool loggingIn: false
    property bool unlocked: false

    readonly property int nameRole: 257
    readonly property int sessionNameRole: 260

    readonly property real dp: {
        var dpr = Screen.devicePixelRatio || 1;
        if (dpr > 1.0) return 1.0;
        var h = Screen.height;
        if (h > 1200) return Math.max(1.0, h / 1080);
        return 1.0;
    }

    function px(v) { return v * dp; }

    Component.onCompleted: {
        var user = "";
        if (typeof sddm !== "undefined" && sddm.lastUser)
            user = sddm.lastUser;
        if (typeof userModel !== "undefined" && userModel.count > 0 && userModel.lastIndex >= 0) {
            var idx = userModel.index(userModel.lastIndex, 0);
            var name = userModel.data(idx, nameRole) || "";
            if (name) user = name;
        }
        usernameField.text = user || "";

        if (typeof sessionModel !== "undefined" && sessionModel.lastIndex >= 0)
            sessionCombo.currentIndex = sessionModel.lastIndex;

        if (!user)
            usernameField.forceActiveFocus();
    }

    Keys.onPressed: function(event) {
        if (!unlocked) {
            triggerUnlock();
            event.accepted = true;
        }
    }

    function triggerUnlock() {
        if (!unlocked) {
            unlocked = true;
            passwordField.forceActiveFocus();
        }
    }

    function doLogin() {
        if (loggingIn || !unlocked) return;

        var user = usernameField.text.trim();
        if (!user) {
            usernameField.forceActiveFocus();
            return;
        }

        var sess = sessionCombo.currentIndex >= 0 ? sessionCombo.currentIndex : 0;
        loggingIn = true;
        sddm.login(user, passwordField.text, sess);
        loginTimer.start();
    }

    Timer {
        id: loginTimer
        interval: 5000
        onTriggered: loggingIn = false
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            loggingIn = false;
            loginTimer.stop();
            shakeAnim.start();
            passwordField.text = "";
            passwordField.forceActiveFocus();
        }
        function onLoginSucceeded() { loginTimer.stop(); }
    }

    // Clean theme-matching backdrop (no generic background image, solid frosted aesthetic)
    Rectangle {
        anchors.fill: parent
        color: baseColor

        // Subtle ambient radial glow or gradient overlay for depth
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.alpha(accent, 0.08) }
                GradientStop { position: 0.5; color: "transparent" }
                GradientStop { position: 1.0; color: Qt.alpha(baseColor, 0.4) }
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (!unlocked)
                    triggerUnlock();
                else
                    passwordField.forceActiveFocus();
            }
        }
    }

    // ===== TOP-LEFT: Session Selector Pill =====
    Rectangle {
        anchors { top: parent.top; left: parent.left; topMargin: px(28); leftMargin: px(28) }
        height: px(40)
        width: sessionRow.implicitWidth + px(28)
        radius: px(20)
        color: surface0
        border.width: 1
        border.color: Qt.alpha(surface2, 0.4)
        z: 100

        RowLayout {
            id: sessionRow
            anchors.centerIn: parent
            spacing: px(8)

            Text {
                text: "󰣇"
                font { family: displayFont; pixelSize: px(14) }
                color: accent
            }

            ComboBox {
                id: sessionCombo
                Layout.preferredHeight: px(32)
                Layout.preferredWidth: px(130)
                model: sessionModel
                textRole: "name"

                contentItem: Text {
                    text: sessionCombo.currentIndex >= 0 && sessionCombo.displayText
                        ? sessionCombo.displayText : "Hyprland"
                    color: textColor
                    font { family: displayFont; pixelSize: px(13); weight: Font.Medium }
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle { color: "transparent" }

                indicator: Text {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    text: "▾"
                    color: accent
                    font.pixelSize: px(12)
                }
            }
        }
    }

    // ===== TOP-RIGHT: Power Buttons Bar =====
    Row {
        anchors { top: parent.top; right: parent.right; topMargin: px(28); rightMargin: px(28) }
        spacing: px(10)
        z: 100

        Repeater {
            model: [
                { icon: "󰒲", action: function() { sddm.suspend(); } },
                { icon: "󰜉", action: function() { sddm.reboot(); } },
                { icon: "󰐥", action: function() { sddm.powerOff(); } }
            ]

            delegate: Rectangle {
                width: px(40); height: px(40)
                radius: width / 2
                color: surface0
                border.width: 1
                border.color: Qt.alpha(surface2, 0.4)

                Text {
                    anchors.centerIn: parent
                    text: modelData.icon
                    font { family: displayFont; pixelSize: px(16) }
                    color: pMouse.containsMouse ? accent : textColor
                }

                MouseArea {
                    id: pMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: modelData.action()
                }
            }
        }
    }

    // ===== MASTER CONTAINER (Centered when locked, shifts up when unlocked) =====
    Item {
        id: masterContainer
        width: px(380)
        height: clockColumn.height + (unlocked ? cardLayout.height + px(36) : 0)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: unlocked ? -px(70) : 0

        Behavior on anchors.verticalCenterOffset {
            NumberAnimation {
                duration: 400
                easing.type: Easing.OutCubic
            }
        }

        // Clock & Avatar Group (Centered initially, moves up smoothly)
        Column {
            id: clockColumn
            width: parent.width
            spacing: px(16)
            anchors.horizontalCenter: parent.horizontalCenter

            // Avatar Ring matching Quickshell lock screen
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: px(76); height: px(76)
                radius: width / 2
                color: Qt.alpha(surface1, 0.6)
                border.width: 2
                border.color: Qt.alpha(accent, 0.6)

                Image {
                    anchors.centerIn: parent
                    source: "assets/ydot.svg"
                    width: px(42); height: px(42)
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }
            }

            // Time
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: {
                    var fmt = root.use24Hour ? "hh:mm" : "h:mm AP";
                    return new Date().toLocaleString(Qt.locale(), fmt);
                }
                color: accent
                font { family: displayFont; pixelSize: px(64); weight: Font.Bold }
            }

            // Date
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDate(new Date(), "dddd, dd MMMM yyyy")
                color: textColor
                font { family: displayFont; pixelSize: px(16) }
                opacity: 0.8
            }

            // Unlock prompt
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Press any key or click to unlock"
                color: textColor
                font { family: displayFont; pixelSize: px(13) }
                opacity: unlocked ? 0 : 0.4
                visible: opacity > 0.05

                Behavior on opacity {
                    NumberAnimation { duration: 250 }
                }
            }
        }

        // ===== LOGIN CARD (Borderless floating layout) =====
        Item {
            id: loginCard
            width: parent.width
            height: cardLayout.implicitHeight + px(48)
            anchors.top: clockColumn.bottom
            anchors.topMargin: px(24)
            anchors.horizontalCenter: parent.horizontalCenter

            opacity: unlocked ? 1 : 0
            scale: unlocked ? 1 : 0.95
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
            }
            Behavior on scale {
                NumberAnimation { duration: 300; easing.type: Easing.OutBack }
            }

            SequentialAnimation {
                id: shakeAnim
                loops: 2
                PropertyAnimation { target: loginCard; property: "x"; to: -px(12); duration: 40 }
                PropertyAnimation { target: loginCard; property: "x"; to: px(12); duration: 40 }
                PropertyAnimation { target: loginCard; property: "x"; to: 0; duration: 40 }
            }

            ColumnLayout {
                id: cardLayout
                anchors { fill: parent; margins: px(24) }
                spacing: px(12)

                // User Tag
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 6

                    Text {
                        text: "󰀉"
                        font.family: displayFont
                        font.pixelSize: px(14)
                        color: accent
                    }

                    Text {
                        text: (typeof sddm !== "undefined" && sddm.lastUser) ? sddm.lastUser : (usernameField.text || "User")
                        color: textColor
                        font { family: displayFont; pixelSize: px(15); weight: Font.DemiBold }
                    }
                }

                // Username Field (subtle, compact)
                TextField {
                    id: usernameField
                    Layout.fillWidth: true
                    Layout.preferredHeight: px(40)
                    color: textColor
                    font { family: displayFont; pixelSize: px(14) }
                    placeholderText: "Username"
                    placeholderTextColor: mutedColor
                    leftPadding: px(12)
                    rightPadding: px(12)

                    background: Rectangle {
                        color: Qt.alpha(surface1, 0.7)
                        radius: px(10)
                        border.width: parent.activeFocus ? 1.5 : 1
                        border.color: parent.activeFocus ? accent : Qt.alpha(surface2, 0.5)
                    }

                    onAccepted: passwordField.forceActiveFocus()
                }

                // Password Field with animated dot indicators matching LockScreen.qml exactly
                Rectangle {
                    id: passwordFieldContainer
                    Layout.fillWidth: true
                    Layout.preferredHeight: px(44)
                    radius: px(10)
                    color: Qt.alpha(surface1, 0.7)
                    border.width: 1.5
                    border.color: passwordField.activeFocus ? accent : Qt.alpha(surface2, 0.5)

                    Behavior on border.color {
                        ColorAnimation { duration: 150 }
                    }

                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        visible: !root.loggingIn

                        Repeater {
                            model: passwordField.text.length

                            Rectangle {
                                required property int index
                                readonly property bool isLast: index === passwordField.text.length - 1
                                width: 10
                                height: 10
                                radius: width / 2
                                color: accent
                                scale: isLast ? 1.2 : 1.0
                                opacity: isLast ? 1.0 : 0.85

                                Behavior on scale {
                                    NumberAnimation { duration: 150; easing.type: Easing.OutBack }
                                }
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: passwordField.text.length === 0 && !root.loggingIn
                        text: "Enter password..."
                        color: mutedColor
                        font { family: displayFont; pixelSize: px(14) }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: root.loggingIn
                        text: "Verifying..."
                        color: accent
                        font { family: displayFont; pixelSize: px(14) }
                    }

                    TextInput {
                        id: passwordField
                        anchors.fill: parent
                        leftPadding: px(12)
                        rightPadding: px(12)
                        opacity: 0
                        echoMode: TextInput.Password
                        focus: unlocked

                        Keys.onReturnPressed: doLogin()
                        Keys.onEnterPressed: doLogin()
                    }
                }
            }
        }
    }
}
