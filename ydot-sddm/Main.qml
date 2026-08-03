import QtQuick

Rectangle {
    id: root

    width: Screen.width
    height: Screen.height
    color: config.backgroundColor || "#1a1b26"
    focus: true

    property color accentColor: config.accentColor ?? "#7aa2f7"
    property color textColor: config.textColor ?? "#cdd6f4"
    property color subtextColor: config.subtextColor ?? "#a6adc8"
    property color surface0: config.surface0 ?? "#313244"
    property color surface1: config.surface1 ?? "#45475a"
    property color surface2: config.surface2 ?? "#585b70"
    property color mutedColor: config.mutedColor ?? "#6c7086"
    property color errorColor: config.errorColor ?? "#f38ba8"
    property string displayFont: config.font ?? "FiraCode Nerd Font"
    property bool use24Hour: config.use24HourClock === "true"
    property bool loggingIn: false
    property bool failed: false
    property int sessionIndex: 0

    readonly property int sessionNameRole: 260
    readonly property int userNameRole: 257
    readonly property real panelWidth: Math.min(390, width * 0.86)

    function px(value) {
        return value * Math.max(1, Math.min(1.25, Screen.height / 900))
    }

    function currentTime() {
        var now = new Date()
        var hours = now.getHours()
        var minutes = String(now.getMinutes()).padStart(2, "0")
        if (use24Hour)
            return String(hours).padStart(2, "0") + ":" + minutes
        var suffix = hours >= 12 ? "PM" : "AM"
        hours = hours % 12 || 12
        return hours + ":" + minutes + " " + suffix
    }

    function selectInitialUser() {
        var user = ""
        if (typeof sddm !== "undefined" && sddm.lastUser)
            user = sddm.lastUser
        if (!user && typeof userModel !== "undefined" && userModel.count > 0 && userModel.lastIndex >= 0) {
            var index = userModel.index(userModel.lastIndex, 0)
            user = userModel.data(index, userNameRole) || ""
        }
        usernameInput.text = user
        if (user)
            passwordInput.forceActiveFocus()
        else
            usernameInput.forceActiveFocus()
    }

    function doLogin() {
        if (loggingIn)
            return
        var user = usernameInput.text.trim()
        if (!user) {
            usernameInput.forceActiveFocus()
            return
        }
        loggingIn = true
        failed = false
        sddm.login(user, passwordInput.text, sessionIndex)
        loginTimeout.start()
    }

    Component.onCompleted: {
        if (typeof sessionModel !== "undefined" && sessionModel.lastIndex >= 0)
            sessionIndex = sessionModel.lastIndex
        selectInitialUser()
    }

    Timer {
        id: clockTimer
        interval: 1000
        running: true
        repeat: true
        onTriggered: clockLabel.text = root.currentTime()
    }

    Timer {
        id: loginTimeout
        interval: 5000
        onTriggered: root.loggingIn = false
    }

    Connections {
        target: sddm

        function onLoginFailed() {
            root.loggingIn = false
            root.failed = true
            loginTimeout.stop()
            passwordInput.text = ""
            passwordInput.forceActiveFocus()
            shakeAnimation.start()
        }

        function onLoginSucceeded() {
            loginTimeout.stop()
        }
    }

    Image {
        anchors.fill: parent
        source: Qt.resolvedUrl("assets/background.jpg")
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(root.color, 0.74)
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.alpha(root.color, 0.12) }
            GradientStop { position: 0.58; color: Qt.alpha(root.color, 0.34) }
            GradientStop { position: 1.0; color: Qt.alpha(root.color, 0.88) }
        }
    }

    // Quiet branding and time area. This is intentionally not the lock-screen layout.
    Item {
        anchors.left: parent.left
        anchors.leftMargin: Math.max(60, width * 0.11)
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(620, root.width * 0.48)
        height: heroColumn.implicitHeight
        opacity: 0.96

        Column {
            id: heroColumn
            width: parent.width
            spacing: 0

            Item {
                width: parent.width
                height: 120

                Rectangle {
                    anchors.centerIn: parent
                    width: 104
                    height: 104
                    radius: width / 2
                    color: Qt.alpha(surface1, 0.32)
                    border.width: 1.5
                    border.color: Qt.alpha(accentColor, 0.48)
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: 116
                    height: 116
                    radius: width / 2
                    color: "transparent"
                    border.width: 1
                    border.color: Qt.alpha(accentColor, 0.18)
                }

                Image {
                    anchors.centerIn: parent
                    source: Qt.resolvedUrl("assets/ydot.svg")
                    width: 62
                    height: 62
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }
            }

            Item { width: 1; height: 28 }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "ydot"
                color: textColor
                font.family: displayFont
                font.pixelSize: px(18)
                font.weight: Font.Medium
                font.letterSpacing: 4
            }

            Item { width: 1; height: 10 }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                id: clockLabel
                text: root.currentTime()
                color: accentColor
                font.family: displayFont
                font.pixelSize: px(76)
                font.weight: Font.Bold
                font.letterSpacing: 3
            }

            Item { width: 1; height: 4 }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDate(new Date(), "dddd, dd MMMM yyyy")
                color: subtextColor
                font.family: displayFont
                font.pixelSize: px(16)
            }

            Item { width: 1; height: 26 }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 52
                height: 2
                radius: 1
                color: accentColor
                opacity: 0.8
            }

            Item { width: 1; height: 18 }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "A quiet place to begin."
                color: subtextColor
                opacity: 0.76
                font.family: displayFont
                font.pixelSize: px(13)
            }
        }
    }

    // Compact login workspace.
    Rectangle {
        id: loginPanel
        anchors.right: parent.right
        anchors.rightMargin: Math.max(42, root.width * 0.09)
        anchors.verticalCenter: parent.verticalCenter
        width: root.panelWidth
        height: loginColumn.implicitHeight + 56
        radius: 24
        color: Qt.alpha(surface0, 0.72)
        border.width: 1
        border.color: Qt.alpha(surface2, 0.42)

        Column {
            id: loginColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 28
            spacing: 0

            Text {
                text: "Welcome back"
                color: textColor
                font.family: displayFont
                font.pixelSize: 22
                font.weight: Font.DemiBold
            }

            Item { width: 1; height: 6 }

            Text {
                text: usernameInput.text ? "Sign in as " + usernameInput.text : "Choose a user to continue"
                color: subtextColor
                font.family: displayFont
                font.pixelSize: 13
            }

            Item { width: 1; height: 26 }

            // Visible current-user indicator. The editable username stays hidden.
            Rectangle {
                width: parent.width
                height: 44
                radius: 14
                color: Qt.alpha(surface1, 0.36)
                border.width: 1
                border.color: Qt.alpha(surface2, 0.3)

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10

                    Text {
                        text: "󰀉"
                        color: accentColor
                        font.family: displayFont
                        font.pixelSize: 17
                    }

                    Text {
                        text: usernameInput.text || "No user selected"
                        color: usernameInput.text ? textColor : mutedColor
                        font.family: displayFont
                        font.pixelSize: 14
                        font.weight: Font.Medium
                    }
                }
            }

            Item { width: 1; height: 10 }

            Rectangle {
                id: passwordField
                width: parent.width
                height: 50
                radius: 16
                color: Qt.alpha(surface1, 0.28)
                border.width: 1.5
                border.color: root.failed ? errorColor : passwordInput.activeFocus ? accentColor : Qt.alpha(surface2, 0.34)
                Behavior on border.color { ColorAnimation { duration: 180 } }
                property real shakeX: 0
                transform: Translate { x: passwordField.shakeX }

                TextInput {
                    id: passwordInput
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    verticalAlignment: TextInput.AlignVCenter
                    color: textColor
                    font.family: displayFont
                    font.pixelSize: 14
                    echoMode: TextInput.Password
                    onAccepted: root.doLogin()
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    visible: passwordInput.text.length === 0 && !passwordInput.activeFocus && !root.loggingIn
                    text: "Password"
                    color: mutedColor
                    font.family: displayFont
                    font.pixelSize: 14
                }

                Text {
                    anchors.centerIn: parent
                    visible: root.loggingIn
                    text: "Verifying..."
                    color: accentColor
                    font.family: displayFont
                    font.pixelSize: 14
                }
            }

            Item { width: 1; height: 14 }

            Text {
                visible: root.failed
                text: "Authentication failed"
                color: errorColor
                font.family: displayFont
                font.pixelSize: 12
            }

            Item { width: 1; height: 18 }

            Row {
                width: parent.width
                spacing: 8

                Rectangle {
                    width: 38
                    height: 38
                    radius: 12
                    color: Qt.alpha(surface1, 0.4)
                    border.width: 1
                    border.color: Qt.alpha(surface2, 0.3)

                    Text {
                        anchors.centerIn: parent
                        text: "󰅂"
                        color: subtextColor
                        font.family: displayFont
                        font.pixelSize: 18
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (typeof sessionModel === "undefined") return
                            sessionIndex = (sessionIndex + 1) % sessionModel.count
                        }
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: {
                        if (typeof sessionModel === "undefined" || sessionIndex < 0)
                            return "Hyprland"
                        var index = sessionModel.index(sessionIndex, 0)
                        return sessionModel.data(index, sessionNameRole) || "Hyprland"
                    }
                    color: subtextColor
                    font.family: displayFont
                    font.pixelSize: 12
                }
            }
        }
    }

    // SDDM receives the actual username here; the field is deliberately hidden.
    TextInput {
        id: usernameInput
        visible: false
        width: 1
        height: 1
    }

    SequentialAnimation {
        id: shakeAnimation
        loops: 2
        PropertyAnimation { target: passwordField; property: "shakeX"; to: -8; duration: 40 }
        PropertyAnimation { target: passwordField; property: "shakeX"; to: 8; duration: 40 }
        PropertyAnimation { target: passwordField; property: "shakeX"; to: 0; duration: 40 }
    }
}
