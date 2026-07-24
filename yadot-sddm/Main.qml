import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    width: Screen.width
    height: Screen.height
    color: config.backgroundColor ?? "#1A1B26"
    focus: true

    property color accent: config.accentColor ?? "#7AA2F7"
    property color textColor: config.textColor ?? "#C0CAF5"
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
        usernameField.text = user || "";

        if (typeof sessionModel !== "undefined" && sessionModel.lastIndex >= 0)
            sessionCombo.currentIndex = sessionModel.lastIndex;

        if (!user)
            usernameField.forceActiveFocus();
    }

    Keys.onPressed: function(event) {
        if (!loginForm.visible) {
            showLoginForm();
            event.accepted = true;
        }
    }

    function showLoginForm() {
        loginForm.visible = true;
        passwordField.forceActiveFocus();
    }

    function doLogin() {
        if (loggingIn || !loginForm.visible) return;

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

    Loader {
        anchors.fill: parent
        asynchronous: true
        sourceComponent: backgroundImg
        visible: status === Loader.Ready
    }

    Component {
        id: backgroundImg
        Image {
            source: config.background ?? ""
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: loginForm.visible ? 0.55 : 0.35
        Behavior on opacity { NumberAnimation { duration: 400 } }
    }

    // ===== LOCK STATE =====
    Item {
        id: lockState
        anchors.fill: parent
        visible: !loginForm.visible
        opacity: visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 400 } }

        Text {
            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: px(80) }
            text: {
                var fmt = root.use24Hour ? "hh:mm" : "h:mm AP";
                return new Date().toLocaleString(Qt.locale(), fmt);
            }
            color: accent
            font { family: displayFont; pixelSize: px(72); weight: Font.Bold }
        }

        Text {
            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: px(170) }
            text: Qt.formatDate(new Date(), "dddd, MMMM d")
            color: textColor
            font { family: displayFont; pixelSize: px(20) }
            opacity: 0.8
        }

        Text {
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: px(60) }
            text: "Press any key to unlock"
            color: textColor
            font { family: displayFont; pixelSize: px(15) }
            opacity: 0.4
        }

        MouseArea {
            anchors.fill: parent
            onClicked: showLoginForm()
        }
    }

    // ===== LOGIN FORM =====
    Item {
        id: loginForm
        anchors.fill: parent
        visible: false
        opacity: visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 400 } }

        Shortcut {
            sequence: "Escape"
            onActivated: {
                loginForm.visible = false;
                passwordField.text = "";
                root.forceActiveFocus();
            }
        }

        Shortcut {
            sequences: ["Return", "Enter"]
            onActivated: doLogin()
        }

        Rectangle {
            id: card
            width: px(380)
            height: cardLayout.implicitHeight + px(80)
            anchors.centerIn: parent
            color: Qt.darker(root.color, 1.0)
            opacity: 0.85
            radius: px(24)

            SequentialAnimation {
                id: shakeAnim
                loops: 2
                PropertyAnimation { target: card; property: "x"; to: (parent.width - card.width)/2 - px(12); duration: 40 }
                PropertyAnimation { target: card; property: "x"; to: (parent.width - card.width)/2 + px(12); duration: 40 }
                PropertyAnimation { target: card; property: "x"; to: (parent.width - card.width)/2; duration: 40 }
            }

            ColumnLayout {
                id: cardLayout
                anchors { fill: parent; margins: px(40) }
                spacing: px(14)

                Image {
                    id: yadotLogo
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: px(64)
                    Layout.preferredHeight: px(64)
                    source: Qt.resolvedUrl("assets/yadot.svg")
                    fillMode: Image.PreserveAspectFit
                    sourceSize: Qt.size(64, 64)
                    asynchronous: true
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Welcome"
                    color: textColor
                    font { family: displayFont; pixelSize: px(24); weight: Font.Bold }
                }

                Item { Layout.preferredHeight: px(8) }

                TextField {
                    id: usernameField
                    Layout.fillWidth: true
                    Layout.preferredHeight: px(44)
                    color: textColor
                    font { family: displayFont; pixelSize: px(16) }
                    placeholderText: "Username"
                    placeholderTextColor: Qt.lighter(textColor, 0.7)

                    background: Rectangle {
                        color: Qt.lighter(root.color, 1.3)
                        radius: px(12)
                        border.width: parent.activeFocus ? 2 : 0
                        border.color: accent
                    }

                    onAccepted: passwordField.forceActiveFocus()
                }

                TextField {
                    id: passwordField
                    Layout.fillWidth: true
                    Layout.preferredHeight: px(44)
                    echoMode: TextInput.Password
                    color: textColor
                    font { family: displayFont; pixelSize: px(16) }
                    placeholderText: "Password"
                    placeholderTextColor: Qt.lighter(textColor, 0.7)
                    enabled: !root.loggingIn

                    background: Rectangle {
                        color: Qt.lighter(root.color, 1.3)
                        radius: px(12)
                        border.width: parent.activeFocus ? 2 : 0
                        border.color: accent
                    }

                    onAccepted: doLogin()
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: px(8)

                    Text {
                        text: "Session:"
                        color: textColor
                        font { family: displayFont; pixelSize: px(13) }
                        opacity: 0.6
                    }

                    ComboBox {
                        id: sessionCombo
                        Layout.fillWidth: true
                        Layout.preferredHeight: px(36)
                        model: sessionModel
                        textRole: "name"

                        contentItem: Text {
                            text: sessionCombo.currentIndex >= 0 && sessionCombo.displayText
                                ? sessionCombo.displayText : "Hyprland"
                            color: textColor
                            font { family: displayFont; pixelSize: px(13) }
                            verticalAlignment: Text.AlignVCenter
                        }

                        background: Rectangle {
                            color: Qt.lighter(root.color, 1.2)
                            radius: px(8)
                        }

                        indicator: Text {
                            anchors { right: parent.right; rightMargin: px(8); verticalCenter: parent.verticalCenter }
                            text: "▾"
                            color: accent
                            font.pixelSize: px(12)
                        }
                    }
                }

                Button {
                    id: loginBtn
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: px(56)
                    Layout.preferredHeight: px(56)
                    Layout.topMargin: px(8)
                    enabled: !root.loggingIn
                    focusPolicy: Qt.NoFocus

                    contentItem: Text {
                        text: root.loggingIn ? "⋯" : "→"
                        color: "white"
                        font.pixelSize: px(26)
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        color: root.loggingIn ? Qt.lighter(accent, 1.5) : (loginBtn.pressed ? Qt.darker(accent, 1.1) : accent)
                        radius: px(28)
                        opacity: root.loggingIn ? 0.5 : 1.0
                    }

                    onClicked: doLogin()
                }

                Text {
                    id: numLockText
                    Layout.alignment: Qt.AlignHCenter
                    text: "Num Lock is on"
                    color: accent
                    font { family: displayFont; pixelSize: px(13) }
                    visible: typeof keyboard !== "undefined" && keyboard.numLock === true
                    opacity: visible ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }
            }
        }
    }

    // ===== POWER BUTTONS =====
    Row {
        anchors { top: parent.top; right: parent.right; topMargin: px(24); rightMargin: px(24) }
        spacing: px(12)
        z: 100

        Repeater {
            model: [
                { icon: "⏻", action: "shutdown" },
                { icon: "↻", action: "reboot" },
                { icon: "⏾", action: "suspend" }
            ]

            delegate: Rectangle {
                width: px(36); height: px(36)
                radius: px(18)
                color: Qt.rgba(1, 1, 1, 0.1)
                opacity: powerMouse.containsMouse ? 1.0 : 0.5
                Behavior on opacity { NumberAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: modelData.icon
                    color: textColor
                    font.pixelSize: px(16)
                }

                MouseArea {
                    id: powerMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (modelData.action === "shutdown")
                            sddm.powerOff();
                        else if (modelData.action === "reboot")
                            sddm.reboot();
                        else if (modelData.action === "suspend")
                            sddm.suspend();
                    }
                }
            }
        }
    }
}
