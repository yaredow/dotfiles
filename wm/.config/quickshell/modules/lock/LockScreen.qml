pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../../components/"
import qs.config
import qs.services

WlSessionLock {
    id: root

    locked: true

    onLockStateChanged: {
        if (!locked)
            Qt.callLater(LockService.unlock)
    }

    WlSessionLockSurface {
        id: lockSurface
        color: "transparent"

        Image {
            anchors.fill: parent
            source: WallpaperService.currentWallpaper ? "file://" + WallpaperService.currentWallpaper : ""
            fillMode: Image.PreserveAspectCrop
            visible: source !== ""
            smooth: true
            asynchronous: true
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.alpha(Config.backgroundColor, 0.7)
        }

        // -- idle suspend timer --
        property int idleSeconds: 0

        function resetIdle() { idleSeconds = 0 }

        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: {
                lockSurface.idleSeconds++
                if (lockSurface.idleSeconds >= 600)
                    Quickshell.execDetached(["systemctl", "suspend"])
            }
        }

        // -- top-right power buttons --
        Item {
            id: powerBox
            z: 10
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 28
            width: powerRow.width
            height: powerRow.height
            opacity: 0.5
            Behavior on opacity { NumberAnimation { duration: 250 } }

            Row {
                id: powerRow
                spacing: 6

                Item {
                    width: 36; height: 36
                    GlassSurface { anchors.fill: parent; radius: width / 2 }
                    Text { anchors.centerIn: parent; text: "󰒲"; font.family: Config.font; font.pixelSize: 16; color: sMouse.containsMouse ? Config.accentColor : Config.textColor }
                    MouseArea { id: sMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["systemctl", "suspend"]) }
                }

                Item {
                    width: 36; height: 36
                    GlassSurface { anchors.fill: parent; radius: width / 2 }
                    Text { anchors.centerIn: parent; text: "󰜉"; font.family: Config.font; font.pixelSize: 16; color: rMouse.containsMouse ? Config.accentColor : Config.textColor }
                    MouseArea { id: rMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["systemctl", "reboot"]) }
                }

                Item {
                    width: 36; height: 36
                    GlassSurface { anchors.fill: parent; radius: width / 2 }
                    Text { anchors.centerIn: parent; text: "󰐥"; font.family: Config.font; font.pixelSize: 16; color: dMouse.containsMouse ? Config.accentColor : Config.textColor }
                    MouseArea { id: dMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["systemctl", "poweroff"]) }
                }
            }

            MouseArea {
                id: powerHover
                anchors.fill: parent
                anchors.margins: -8
                hoverEnabled: true
                onContainsMouseChanged: powerBox.opacity = containsMouse ? 1.0 : 0.5
            }
        }

        MouseArea {
            anchors.fill: parent
            z: -1
            onClicked: {
                lockSurface.resetIdle()
                if (!lockSurface.hasTyped)
                    lockSurface.hasTyped = true
                passwordInput.forceActiveFocus()
            }
        }

        property bool hasTyped: false

        SequentialAnimation {
            id: shakeAnim
            NumberAnimation { target: centralContent; property: "shakeX"; to: 12; duration: 40 }
            NumberAnimation { target: centralContent; property: "shakeX"; to: -10; duration: 40 }
            NumberAnimation { target: centralContent; property: "shakeX"; to: 8; duration: 40 }
            NumberAnimation { target: centralContent; property: "shakeX"; to: -6; duration: 40 }
            NumberAnimation { target: centralContent; property: "shakeX"; to: 0; duration: 40 }
        }

        Item {
            id: centralContent
            anchors.centerIn: parent
            width: 400
            height: centralCol.implicitHeight

            property real shakeX: 0
            transform: Translate { x: centralContent.shakeX }

            opacity: 0
            scale: 0.94

            Behavior on opacity { NumberAnimation { duration: Config.animDurationLong; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }

            Component.onCompleted: {
                centralContent.opacity = 1
                centralContent.scale = 1.0
                glowPulse.start()
            }

            Column {
                id: centralCol
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 0

                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 96; height: 96

                    Rectangle {
                        id: glowRing
                        anchors.centerIn: parent
                        width: 72; height: 72
                        radius: width / 2
                        color: "transparent"
                        border.width: 2.5
                        border.color: Qt.alpha(Config.accentColor, _glowAlpha)

                        property real _glowAlpha: 0.0

                        Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
                        Behavior on scale { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
                    }

                    Timer {
                        id: glowPulse
                        interval: 2200
                        running: false
                        repeat: true
                        onTriggered: glowRing._glowAlpha = glowRing._glowAlpha === 0.0 ? 0.45 : 0.0
                    }

                    GlassSurface {
                        anchors.centerIn: parent
                        width: 56; height: 56
                        radius: width / 2
                        border.width: 1.5
                        border.color: Qt.alpha(Config.accentColor, 0.4)
                    }

                    YdotLogo {
                        anchors.centerIn: parent
                        width: 34; height: 34
                    }
                }

                Item { width: 1; height: 14 }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Quickshell.env("USER")
                    color: Config.textColor
                    font.family: Config.font
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                }

                Item { width: 1; height: 18 }

                Text {
                    id: clockText
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: TimeService.format("hh:mm")
                    color: Config.accentColor
                    font.family: Config.font
                    font.pixelSize: 56
                    font.weight: Font.Bold
                    font.letterSpacing: 2

                    Timer {
                        interval: 1000
                        running: true
                        repeat: true
                        onTriggered: clockText.text = TimeService.format("hh:mm")
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDate(new Date(), "dddd, dd MMMM yyyy")
                    color: Config.subtextColor
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeNormal
                }

                Item { width: 1; height: 34 }

                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 300; height: 48

                    GlassSurface {
                        id: passwordPill
                        anchors.fill: parent
                        radius: height / 2
                        border.width: 1.5

                        Behavior on border.color {
                            ColorAnimation { duration: 200 }
                        }
                    }

                    Text {
                        id: passwordPlaceholder
                        anchors.centerIn: parent
                        text: {
                            if (LockService.authenticating) return "Verifying..."
                            if (passwordInput.text.length === 0)
                                return lockSurface.hasTyped ? "" : "Enter password..."
                            return ""
                        }
                        color: LockService.authenticating ? Config.accentColor : Config.mutedColor
                        font.family: Config.font
                        font.pixelSize: Config.fontSizeNormal
                        visible: text !== ""

                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            running: LockService.authenticating
                            NumberAnimation { from: 1; to: 0.4; duration: 600; easing.type: Easing.InOutSine }
                            NumberAnimation { from: 0.4; to: 1; duration: 600; easing.type: Easing.InOutSine }
                        }
                    }

                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        visible: passwordInput.text.length > 0 && !LockService.authenticating

                        Repeater {
                            model: passwordInput.text.length
                            delegate: Item {
                                required property int index
                                width: 10; height: 10

                                Rectangle {
                                    id: dot
                                    anchors.centerIn: parent
                                    width: 10; height: 10
                                    radius: width / 2
                                    color: Config.accentColor

                                    property bool isLatest: index === passwordInput.text.length - 1

                                    Component.onCompleted: {
                                        if (isLatest && centralContent.opacity > 0)
                                            dotPop.start()
                                    }

                                    SequentialAnimation {
                                        id: dotPop
                                        PropertyAnimation {
                                            target: dot
                                            property: "scale"
                                            from: 0.3
                                            to: 1.3
                                            duration: 180
                                            easing.type: Easing.OutBack
                                        }
                                        PropertyAnimation {
                                            target: dot
                                            property: "scale"
                                            to: 1.0
                                            duration: 120
                                            easing.type: Easing.OutCubic
                                        }
                                    }

                                    Timer {
                                        interval: 800
                                        running: dot.isLatest && !LockService.authenticating
                                        repeat: true
                                        onTriggered: dot.scale = dot.scale === 1.0 ? 1.2 : 1.0
                                        onRunningChanged: { if (!running) dot.scale = 1.0 }
                                    }
                                }
                            }
                        }
                    }
                }

                Item { width: 1; height: 12 }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: LockService.failed
                    text: LockService.failMessage || "Authentication failed"
                    color: Config.errorColor
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeSmall
                }
            }
        }

        Binding {
            target: passwordPill
            property: "border.color"
            value: {
                if (LockService.failed) return Config.errorColor
                if (passwordInput.activeFocus || lockSurface.hasTyped) return Config.accentColor
                return Qt.alpha(Config.surface2Color, 0.3)
            }
        }

        TextInput {
            id: passwordInput
            width: 1; height: 1
            opacity: 0
            echoMode: TextInput.Password
            focus: true

            Keys.onReturnPressed: submit()
            Keys.onEnterPressed: submit()

            onTextChanged: {
                lockSurface.resetIdle()
                if (text.length > 0 && !lockSurface.hasTyped)
                    lockSurface.hasTyped = true
            }

            function submit() {
                if (!LockService.authenticating && text.length > 0)
                    LockService.tryUnlock(text)
            }
        }

        Connections {
            id: lockServiceConn
            target: LockService

            function onAuthSucceeded() {
                passwordInput.forceActiveFocus()
                glowRing._glowAlpha = 1.0
                fadeOutTimer.start()
            }

            function onFailedChanged() {
                if (LockService.failed) {
                    shakeAnim.start()
                    passwordInput.clear()
                    lockSurface.hasTyped = true
                }
            }
        }

        Timer {
            id: fadeOutTimer
            interval: 200
            onTriggered: {
                glowRing.opacity = 0
                glowRing.scale = 7.0
                centralContent.opacity = 0
                fadeOutAnim.start()
            }
        }

        SequentialAnimation {
            id: fadeOutAnim
            NumberAnimation {
                target: centralContent
                property: "opacity"
                to: 0
                duration: 350
                easing.type: Easing.OutCubic
            }
            ScriptAction {
                script: {
                    lockServiceConn.enabled = false
                    root.locked = false
                }
            }
        }
    }
}
