import QtQuick

Rectangle {
    id: root
    width: Screen.width
    height: Screen.height
    color: config.backgroundColor ?? "#1e1e2e"
    focus: true

    property color accentColor: config.accentColor ?? "#cba6f7"
    property color textColor: config.textColor ?? "#cdd6f4"
    property color subtextColor: Qt.lighter(textColor, 0.7)
    property color surface0: "#313244"
    property color surface1: "#45475a"
    property color surface2: "#585b70"
    property color mutedColor: "#6c7086"
    property color errorColor: "#f38ba8"
    property string displayFont: config.font ?? "CaskaydiaCove Nerd Font"
    property bool use24Hour: config.use24HourClock === "true"
    property bool loggingIn: false

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
        usernameInput.text = user || "";
        if (typeof sessionModel !== "undefined" && sessionModel.lastIndex >= 0)
            sessionIndex = sessionModel.lastIndex;
        if (user)
            passwordInput.forceActiveFocus();
        else
            usernameInput.forceActiveFocus();
    }

    property int sessionIndex: 0

    function doLogin() {
        if (loggingIn) return;
        var user = usernameInput.text.trim();
        if (!user) {
            usernameInput.forceActiveFocus();
            return;
        }
        loggingIn = true;
        sddm.login(user, passwordInput.text, sessionIndex);
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
            passwordInput.text = "";
            passwordInput.forceActiveFocus();
        }
        function onLoginSucceeded() { loginTimer.stop(); }
    }

    // Background with subtle gradient
    Rectangle {
        anchors.fill: parent
        color: root.color

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.alpha(accentColor, 0.08) }
                GradientStop { position: 0.5; color: "transparent" }
                GradientStop { position: 1.0; color: Qt.alpha(root.color, 0.4) }
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: passwordInput.forceActiveFocus()
        }
    }

    // Session selector pill (top-left)
    Rectangle {
        anchors { top: parent.top; left: parent.left; topMargin: px(28); leftMargin: px(28) }
        height: px(36)
        width: sessionLabel.width + px(24)
        radius: px(18)
        color: surface0
        border.width: 1
        border.color: Qt.alpha(surface2, 0.4)

        Text {
            id: sessionLabel
            anchors.centerIn: parent
            text: {
                if (typeof sessionModel === "undefined" || sessionIndex < 0)
                    return "Hyprland";
                var idx = sessionModel.index(sessionIndex, 0);
                return sessionModel.data(idx, sessionNameRole) || "Hyprland";
            }
            color: textColor
            font { family: displayFont; pixelSize: px(13); weight: Font.Medium }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (typeof sessionModel === "undefined") return;
                sessionIndex = (sessionIndex + 1) % sessionModel.count;
            }
        }
    }

    // Power buttons (top-right)
    Row {
        anchors { top: parent.top; right: parent.right; topMargin: px(28); rightMargin: px(28) }
        spacing: px(10)

        Repeater {
            model: [
                { icon: "⏾", action: function() { sddm.suspend(); } },
                { icon: "↻", action: function() { sddm.reboot(); } },
                { icon: "⏻", action: function() { sddm.powerOff(); } }
            ]

            delegate: Rectangle {
                width: px(36); height: px(36)
                radius: width / 2
                color: pbMouse.containsMouse ? surface1 : surface0
                border.width: 1
                border.color: Qt.alpha(surface2, 0.4)

                Text {
                    anchors.centerIn: parent
                    text: modelData.icon
                    font.pixelSize: px(16)
                    color: pbMouse.containsMouse ? accentColor : subtextColor
                }

                MouseArea {
                    id: pbMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: modelData.action()
                }
            }
        }
    }

    // Avatar and clock
    Column {
        id: clockColumn
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: px(-120)
        spacing: px(16)

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: px(72); height: px(72)
            radius: width / 2
            color: Qt.alpha(surface1, 0.6)
            border.width: 2
            border.color: Qt.alpha(accentColor, 0.6)

            Image {
                anchors.centerIn: parent
                source: "assets/ydot.svg"
                width: px(40); height: px(40)
                fillMode: Image.PreserveAspectFit
                smooth: true
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: {
                var fmt = root.use24Hour ? "hh:mm" : "h:mm AP";
                return new Date().toLocaleString(Qt.locale(), fmt);
            }
            color: accentColor
            font { family: displayFont; pixelSize: px(60); weight: Font.Bold }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDate(new Date(), "dddd, dd MMMM yyyy")
            color: subtextColor
            font { family: displayFont; pixelSize: px(16) }
        }
    }

    // Login card
    Rectangle {
        id: loginCard
        width: px(340)
        height: loginColumn.height + px(48)
        radius: px(20)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: px(80)
        color: Qt.alpha("#1e1e2e", 0.75)

        Column {
            id: loginColumn
            anchors { fill: parent; margins: px(24) }
            spacing: px(12)

            // User label
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: usernameInput.text.length > 0 ? usernameInput.text : (typeof sddm !== "undefined" && sddm.lastUser ? sddm.lastUser : "User")
                color: textColor
                font { family: displayFont; pixelSize: px(15); weight: Font.DemiBold }
            }

            // Username input
            Rectangle {
                width: parent.width
                height: px(42)
                radius: px(10)
                color: Qt.alpha(surface1, 0.7)
                border.width: usernameInput.activeFocus ? 2 : 1
                border.color: usernameInput.activeFocus ? accentColor : Qt.alpha(surface2, 0.5)

                TextInput {
                    id: usernameInput
                    anchors { fill: parent; leftMargin: px(12); rightMargin: px(12) }
                    verticalAlignment: TextInput.AlignVCenter
                    color: textColor
                    font { family: displayFont; pixelSize: px(14) }

                    onAccepted: passwordInput.forceActiveFocus()
                    onCursorVisibleChanged: if (cursorVisible) forceActiveFocus()
                }

                Text {
                    anchors.centerIn: parent
                    visible: usernameInput.text.length === 0 && !usernameInput.activeFocus
                    text: "Username"
                    color: mutedColor
                    font { family: displayFont; pixelSize: px(14) }
                }
            }

            // Password input
            Rectangle {
                width: parent.width
                height: px(42)
                radius: px(10)
                color: Qt.alpha(surface1, 0.7)
                border.width: passwordInput.activeFocus ? 2 : 1
                border.color: passwordInput.activeFocus ? accentColor : Qt.alpha(surface2, 0.5)

                Behavior on border.color {
                    ColorAnimation { duration: 150 }
                }

                TextInput {
                    id: passwordInput
                    anchors { fill: parent; leftMargin: px(12); rightMargin: px(12) }
                    verticalAlignment: TextInput.AlignVCenter
                    color: "transparent"
                    font { family: displayFont; pixelSize: px(14) }
                    echoMode: TextInput.Password

                    onAccepted: doLogin()
                    onCursorVisibleChanged: if (cursorVisible) forceActiveFocus()
                }

                // Dot indicators
                Row {
                    anchors.centerIn: parent
                    spacing: 8
                    visible: !root.loggingIn

                    Repeater {
                        model: passwordInput.text.length

                        Rectangle {
                            required property int index
                            readonly property bool isLast: index === passwordInput.text.length - 1
                            width: 10; height: 10
                            radius: width / 2
                            color: accentColor
                            scale: isLast ? 1.2 : 1.0
                            opacity: isLast ? 1.0 : 0.7
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: passwordInput.text.length === 0 && !passwordInput.activeFocus && !root.loggingIn
                    text: "Password"
                    color: mutedColor
                    font { family: displayFont; pixelSize: px(14) }
                }

                Text {
                    anchors.centerIn: parent
                    visible: root.loggingIn
                    text: "Verifying..."
                    color: accentColor
                    font { family: displayFont; pixelSize: px(14) }
                }
            }

            // Login button
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: px(48); height: px(48)
                radius: width / 2
                color: loginBtnMouse.containsMouse ? Qt.lighter(accentColor, 1.2) : accentColor
                opacity: root.loggingIn ? 0.5 : 1.0

                Text {
                    anchors.centerIn: parent
                    text: root.loggingIn ? "⋯" : "→"
                    color: "white"
                    font.pixelSize: px(22)
                }

                MouseArea {
                    id: loginBtnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: doLogin()
                }
            }
        }
    }

    // Shake animation
    SequentialAnimation {
        id: shakeAnim
        loops: 2
        PropertyAnimation { target: loginCard; property: "x"; to: (parent.width - loginCard.width) / 2 - px(10); duration: 40 }
        PropertyAnimation { target: loginCard; property: "x"; to: (parent.width - loginCard.width) / 2 + px(10); duration: 40 }
        PropertyAnimation { target: loginCard; property: "x"; to: (parent.width - loginCard.width) / 2; duration: 40 }
    }

    // Num lock indicator
    Text {
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: px(40) }
        text: "Num Lock is on"
        color: accentColor
        font { family: displayFont; pixelSize: px(13) }
        visible: typeof keyboard !== "undefined" && keyboard.numLock === true
    }
}
