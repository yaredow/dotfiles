import QtQuick

Rectangle {
    id: root
    width: Screen.width
    height: Screen.height
    color: config.backgroundColor ?? "#1a1b26"
    focus: true

    property color accentColor: config.accentColor ?? "#7aa2f7"
    property color textColor: config.textColor ?? "#c0caf5"
    property color subtextColor: config.subtextColor ?? "#a9b1d6"
    property color surface0: config.surface0 ?? "#292e42"
    property color surface1: config.surface1 ?? "#3b4261"
    property color surface2: config.surface2 ?? "#414868"
    property color mutedColor: config.mutedColor ?? "#565f89"
    property color errorColor: config.errorColor ?? "#f7768e"
    property string displayFont: config.font ?? "CaskaydiaCove Nerd Font"
    property bool use24Hour: config.use24HourClock === "true"
    property bool loggingIn: false
    property bool unlocked: false
    property bool fpAvailable: false

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

    property int sessionIndex: 0

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
        fpAvailable = user && (typeof sddm.fingerprintLogin === "function");
    }

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

    Keys.onPressed: {
        if (!unlocked) {
            unlocked = true;
            passwordInput.forceActiveFocus();
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (!unlocked) {
                unlocked = true;
                passwordInput.forceActiveFocus();
            } else {
                passwordInput.forceActiveFocus();
            }
        }
    }

    Rectangle {
        anchors { top: parent.top; left: parent.left; topMargin: px(28); leftMargin: px(28) }
        height: px(36)
        width: sessionLabel.width + px(24)
        radius: px(18)
        color: surface0
        border.width: 1
        border.color: Qt.alpha(surface2, 0.4)
        opacity: unlocked ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 300 } }

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

    Row {
        anchors { top: parent.top; right: parent.right; topMargin: px(28); rightMargin: px(28) }
        spacing: px(10)
        opacity: unlocked ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 300 } }

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

    Column {
        id: clockColumn
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: unlocked ? px(-150) : 0
        spacing: px(16)
        Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: 500; easing.type: Easing.InOutQuad } }

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

    Column {
        id: loginCol
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: px(120)
        spacing: px(16)
        opacity: unlocked ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 500 } }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: px(300)
            height: px(42)
            radius: px(10)
            color: "transparent"
            border.width: usernameInput.activeFocus ? 2 : 0
            border.color: usernameInput.activeFocus ? accentColor : "transparent"

            TextInput {
                id: usernameInput
                anchors { fill: parent; leftMargin: px(14); rightMargin: px(14) }
                verticalAlignment: TextInput.AlignVCenter
                horizontalAlignment: TextInput.AlignHCenter
                color: usernameInput.text.length > 0 ? textColor : mutedColor
                font { family: displayFont; pixelSize: px(14) }

                onAccepted: passwordInput.forceActiveFocus()
                onCursorVisibleChanged: if (cursorVisible) forceActiveFocus()
            }
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: px(300)
            height: px(42)
            radius: px(10)
            color: Qt.alpha(surface0, 0.4)
            border.width: passwordInput.activeFocus ? 2 : 0
            border.color: passwordInput.activeFocus ? accentColor : "transparent"
            clip: true

            Behavior on border.color {
                ColorAnimation { duration: 150 }
            }

            Item {
                anchors.fill: parent

                TextInput {
                    id: passwordInput
                    anchors { fill: parent; leftMargin: px(14); rightMargin: px(14) }
                    verticalAlignment: TextInput.AlignVCenter
                    horizontalAlignment: TextInput.AlignHCenter
                    color: textColor
                    font { family: displayFont; pixelSize: px(14) }
                    echoMode: TextInput.Password
                    visible: !root.loggingIn

                    onAccepted: doLogin()
                    onCursorVisibleChanged: if (cursorVisible) forceActiveFocus()
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
        }

        Item {
            id: fpIndicator
            width: parent.width
            height: px(80)

            property real pulse: 0
            property real breathe: 0

            NumberAnimation {
                target: fpIndicator
                property: "pulse"
                from: 0
                to: 1
                duration: 1500
                loops: Animation.Infinite
                running: fpAvailable
                easing.type: Easing.InOutSine
            }

            SequentialAnimation {
                loops: Animation.Infinite
                running: fpAvailable
                NumberAnimation {
                    target: fpIndicator; property: "breathe"
                    from: 0; to: 1; duration: 800; easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    target: fpIndicator; property: "breathe"
                    from: 1; to: 0; duration: 800; easing.type: Easing.InOutSine
                }
            }

            Item {
                anchors.centerIn: parent
                width: px(40)
                height: px(56)

                Rectangle {
                    anchors.centerIn: parent
                    width: px(52)
                    height: px(66)
                    radius: px(26)
                    color: Qt.alpha(accentColor, 0.03 + fpIndicator.pulse * 0.28)
                    scale: 1 + fpIndicator.pulse * 0.14
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: px(42)
                    height: px(54)
                    radius: px(21)
                    color: Qt.alpha(accentColor, 0 + fpIndicator.breathe * 0.12)
                    scale: 1 + fpIndicator.breathe * 0.06
                }

                Canvas {
                    id: fpCanvas
                    anchors.centerIn: parent
                    width: px(30)
                    height: px(44)
                    antialiasing: true

                    property var lineColor: fpAvailable ? accentColor : mutedColor
                    onLineColorChanged: requestPaint()

                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();

                        var lc = fpCanvas.lineColor;
                        var r = lc.r, g = lc.g, b = lc.b;
                        var baseAlpha = fpAvailable ? 1 : 0.45;

                        var w = width, h = height;
                        var cx = w / 2, cy = h / 2;

                        function hash(n) {
                            var s = Math.sin(n * 127.1 + 311.7) * 43758.5453123;
                            return s - Math.floor(s);
                        }
                        function noise(x) {
                            var i = Math.floor(x), f = x - i;
                            var a = hash(i), b2 = hash(i + 1);
                            var u = f * f * (3 - 2 * f);
                            return a + (b2 - a) * u;
                        }

                        function outlinePath() {
                            ctx.beginPath();
                            ctx.moveTo(cx - 7.5, h - 3);
                            ctx.quadraticCurveTo(cx - 12.5, cy + 5, cx - 11.5, cy - 6);
                            ctx.quadraticCurveTo(cx - 10, cy - 16, cx - 4, cy - 20);
                            ctx.quadraticCurveTo(cx, cy - 21.5, cx + 4, cy - 20);
                            ctx.quadraticCurveTo(cx + 10, cy - 16, cx + 11.5, cy - 6);
                            ctx.quadraticCurveTo(cx + 12.5, cy + 5, cx + 7.5, h - 3);
                            ctx.closePath();
                        }

                        ctx.globalAlpha = baseAlpha;
                        ctx.strokeStyle = Qt.rgba(r, g, b, 1);
                        ctx.lineWidth = 1.15;
                        ctx.lineCap = "round";
                        ctx.lineJoin = "round";
                        outlinePath();
                        ctx.stroke();

                        ctx.save();
                        outlinePath();
                        ctx.clip();

                        function ridge(ox, oy, rx, ry, rot, a0, a1, wobble, seed, lw, alpha, samples) {
                            samples = samples || 22;
                            var pts = [];
                            for (var s = 0; s <= samples; s++) {
                                var a = a0 + (a1 - a0) * (s / samples);
                                var rf = 1 + (noise(a * 2.3 + seed) - 0.5) * wobble;
                                var ex = Math.cos(a) * rx * rf;
                                var ey = Math.sin(a) * ry * rf;
                                var x = ox + ex * Math.cos(rot) - ey * Math.sin(rot);
                                var y = oy + ex * Math.sin(rot) + ey * Math.cos(rot);
                                pts.push({ x: x, y: y });
                            }
                            ctx.globalAlpha = alpha;
                            ctx.lineWidth = lw;
                            ctx.beginPath();
                            ctx.moveTo(pts[0].x, pts[0].y);
                            for (var i = 1; i < pts.length - 1; i++) {
                                var mx = (pts[i].x + pts[i + 1].x) / 2;
                                var my = (pts[i].y + pts[i + 1].y) / 2;
                                ctx.quadraticCurveTo(pts[i].x, pts[i].y, mx, my);
                            }
                            ctx.lineTo(pts[pts.length - 1].x, pts[pts.length - 1].y);
                            ctx.stroke();
                        }

                        ctx.strokeStyle = Qt.rgba(r, g, b, 1);
                        ctx.lineCap = "round";
                        ctx.lineJoin = "round";

                        var core = { x: cx - 1.2, y: cy - 9 };
                        var ringCount = 17;
                        var TWO_PI = Math.PI * 2;

                        for (var i = 1; i <= ringCount; i++) {
                            var t = i / ringCount;
                            var rx = 1.6 + t * 12.5;
                            var ry = 1.8 + t * 19.5;
                            var ox = core.x + Math.sin(t * 4.1) * 1.3 + (noise(i * 0.37) - 0.5) * 0.8;
                            var oy = core.y + t * t * 7 + (noise(i * 0.91 + 5) - 0.5) * 0.6;
                            var rot = -0.12 + t * 0.32 + (noise(i * 1.7) - 0.5) * 0.1;
                            var seed = i * 3.3;
                            var lw = 0.7 + noise(i * 0.55) * 0.35;
                            var alpha = baseAlpha * (0.6 + 0.35 * Math.min(1, t * 1.6));

                            var a0, a1;
                            if (t < 0.26) {
                                a0 = -Math.PI * 0.05;
                                a1 = TWO_PI - Math.PI * 0.05;
                            } else if (t < 0.78) {
                                var gap = 0.30 + (t - 0.26) * 0.55;
                                a0 = Math.PI / 2 + gap;
                                a1 = Math.PI / 2 - gap + TWO_PI;
                            } else {
                                var gap2 = 0.85 + (t - 0.78) * 0.9;
                                a0 = Math.PI / 2 + gap2;
                                a1 = Math.PI / 2 - gap2 + TWO_PI;
                            }

                            if (noise(i * 2.13 + 8) > 0.78) {
                                a1 -= (a1 - a0) * (0.15 + noise(i) * 0.25);
                            }

                            ridge(ox, oy, rx, ry, rot, a0, a1, 0.10 + t * 0.06, seed, lw, alpha);

                            if (noise(i * 5.02 + 2) > 0.72) {
                                var bm = a0 + (a1 - a0) * (0.35 + noise(i) * 0.3);
                                ridge(ox, oy, rx * 1.04, ry * 1.05, rot + 0.05, bm, bm + (a1 - a0) * 0.22,
                                      0.16, seed + 1, lw * 0.85, alpha * 0.85, 8);
                            }
                        }

                        var delta = { x: cx + 3.4, y: h - 12 };
                        var deltaCount = 6;
                        for (var d = 1; d <= deltaCount; d++) {
                            var td = d / deltaCount;
                            var drx = 2 + td * 8.5;
                            var dry = 1.6 + td * 6.5;
                            var drot = 0.35 + Math.sin(td * 3) * 0.08;
                            var gapD = 0.55 + td * 0.35;
                            var da0 = -Math.PI / 2 + gapD;
                            var da1 = -Math.PI / 2 - gapD + TWO_PI;
                            ridge(delta.x, delta.y, drx, dry, drot, da0, da1, 0.14, d * 7.7,
                                  0.65 + noise(d) * 0.3, baseAlpha * 0.75, 14);
                        }

                        for (var side = -1; side <= 1; side += 2) {
                            for (var k = 0; k < 4; k++) {
                                var sy = cy - 8 + k * 8 + noise(k * 3 + side) * 1.5;
                                if (sy > h - 6) continue;
                                var sx = cx + side * (10 - k * 0.6);
                                ctx.globalAlpha = baseAlpha * 0.7;
                                ctx.lineWidth = 0.65;
                                ctx.beginPath();
                                ctx.moveTo(sx, sy - 3);
                                ctx.quadraticCurveTo(sx + side * 2.2, sy, sx, sy + 3.2);
                                ctx.stroke();
                            }
                        }

                        ctx.restore();
                    }
                }
            }
        }
    }

    SequentialAnimation {
        id: shakeAnim
        loops: 2
        PropertyAnimation { target: passwordInput; property: "x"; to: px(150) - px(10); duration: 40 }
        PropertyAnimation { target: passwordInput; property: "x"; to: px(150) + px(10); duration: 40 }
        PropertyAnimation { target: passwordInput; property: "x"; to: px(150); duration: 40 }
    }

    Text {
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: px(100) }
        text: "Press any key to enter"
        color: subtextColor
        font { family: displayFont; pixelSize: px(16) }
        opacity: unlocked ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: 300 } }
    }

    Text {
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: px(40) }
        text: "Num Lock is on"
        color: accentColor
        font { family: displayFont; pixelSize: px(13) }
        visible: typeof keyboard !== "undefined" && keyboard.numLock === true
    }
}
