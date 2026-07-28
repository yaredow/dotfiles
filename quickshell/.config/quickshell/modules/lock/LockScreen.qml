pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

WlSessionLock {
    id: root

    locked: true

    onLockStateChanged: {
        if (!locked)
            Qt.callLater(LockService.unlock);
    }

    WlSessionLockSurface {
        color: "transparent"

        // Wallpaper background
        Image {
            anchors.fill: parent
            source: WallpaperService.currentWallpaper ? "file://" + WallpaperService.currentWallpaper : ""
            fillMode: Image.PreserveAspectCrop
            visible: source !== ""
            smooth: true
            asynchronous: true
        }

        // Dark dimming / translucent backdrop overlay following theme colors
        Rectangle {
            anchors.fill: parent
            color: Qt.alpha(Config.backgroundColor, Config.backgroundOpacity)
        }

        MouseArea {
            anchors.fill: parent
            onClicked: passwordInput.forceActiveFocus()
        }

        // Main Content (Borderless floating layout)
        Item {
            id: mainCard
            anchors.centerIn: parent
            width: 380
            height: cardContent.implicitHeight + 48

            ColumnLayout {
                id: cardContent
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 24
                spacing: Config.spacing + 4
                opacity: 0

                Component.onCompleted: fadeIn.start()

                NumberAnimation {
                    id: fadeIn
                    target: cardContent
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: Config.animDurationLong
                    easing.type: Easing.OutCubic
                }

                // Avatar / Branding Ring
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 76
                    height: 76
                    radius: width / 2
                    color: Qt.alpha(Config.surface1Color, 0.6)
                    border.width: 2
                    border.color: Qt.alpha(Config.accentColor, 0.6)

                    Image {
                        anchors.centerIn: parent
                        source: "file://" + Quickshell.env("HOME") + "/.config/quickshell/assets/ydot.svg"
                        width: 42
                        height: 42
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }
                }

                // Clock
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: TimeService.format("hh:mm")
                    font.family: Config.font
                    font.pixelSize: 52
                    font.bold: true
                    color: Config.accentColor
                }

                // Date
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: Qt.formatDate(new Date(), "dddd, dd MMMM yyyy")
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeNormal
                    color: Config.subtextColor
                }

                Item {
                    Layout.preferredHeight: 8
                }

                // User Tag
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 6

                    Text {
                        text: "󰀉"
                        font.family: Config.font
                        font.pixelSize: Config.fontSizeSmall
                        color: Config.accentColor
                    }

                    Text {
                        text: Quickshell.env("USER")
                        color: Config.textColor
                        font.family: Config.font
                        font.pixelSize: Config.fontSizeNormal
                        font.weight: Font.DemiBold
                    }
                }

                // Password Input Display
                Rectangle {
                    id: passwordField
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 280
                    Layout.preferredHeight: 46
                    radius: Config.radius
                    color: Qt.alpha(Config.surface1Color, 0.7)
                    border.width: 1.5
                    border.color: LockService.failed ? Config.errorColor : passwordInput.activeFocus ? Config.accentColor : Qt.alpha(Config.surface2Color, 0.5)

                    Behavior on border.color {
                        ColorAnimation {
                            duration: Config.animDurationShort
                        }
                    }

                    property real shakeX: 0
                    transform: Translate {
                        x: passwordField.shakeX
                    }

                    Row {
                        visible: !LockService.authenticating
                        anchors.centerIn: parent
                        spacing: 8

                        Repeater {
                            model: passwordInput.text.length

                            Rectangle {
                                required property int index
                                readonly property bool isLast: index === passwordInput.text.length - 1
                                width: 10
                                height: 10
                                radius: width / 2
                                color: Config.accentColor
                                scale: isLast ? 1.2 : 1.0
                                opacity: isLast ? 1.0 : 0.85

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: Config.animDuration
                                        easing.type: Easing.OutBack
                                    }
                                }

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: Config.animDuration
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: (passwordInput.text.length === 0) || (LockService.authenticating)
                        text: LockService.authenticating ? "Verifying..." : "Enter password..."
                        color: LockService.authenticating ? Config.accentColor : Config.mutedColor
                        font.family: Config.font
                        font.pixelSize: Config.fontSizeNormal
                    }

                    SequentialAnimation {
                        id: shakeAnim
                        NumberAnimation {
                            target: passwordField
                            property: "shakeX"
                            to: 12
                            duration: 40
                        }
                        NumberAnimation {
                            target: passwordField
                            property: "shakeX"
                            to: -10
                            duration: 40
                        }
                        NumberAnimation {
                            target: passwordField
                            property: "shakeX"
                            to: 8
                            duration: 40
                        }
                        NumberAnimation {
                            target: passwordField
                            property: "shakeX"
                            to: -6
                            duration: 40
                        }
                        NumberAnimation {
                            target: passwordField
                            property: "shakeX"
                            to: 0
                            duration: 40
                        }
                    }
                }

                // Error message display
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    visible: LockService.failed
                    text: LockService.failMessage
                    color: Config.errorColor
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeSmall
                }
            }
        }

        // Quick Power Action Bar (Borderless floating layout)
        Item {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 32
            anchors.horizontalCenter: parent.horizontalCenter
            height: 48
            width: powerRow.implicitWidth + 32

            RowLayout {
                id: powerRow
                anchors.centerIn: parent
                spacing: 16

                Repeater {
                    model: [
                        { icon: "󰒲", label: "Suspend", action: function() { PowerService.suspend(); } },
                        { icon: "󰜉", label: "Reboot", action: function() { PowerService.reboot(); } },
                        { icon: "󰐥", label: "Shutdown", action: function() { PowerService.shutdown(); } }
                    ]

                    delegate: Rectangle {
                        required property var modelData
                        width: 36
                        height: 36
                        radius: Config.radiusSmall
                        color: btnMouse.containsMouse ? Qt.alpha(Config.surface2Color, 0.6) : "transparent"

                        Behavior on color {
                            ColorAnimation {
                                duration: Config.animDurationShort
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: parent.modelData.icon
                            font.family: Config.font
                            font.pixelSize: Config.fontSizeIcon
                            color: btnMouse.containsMouse ? Config.accentColor : Config.textColor
                        }

                        MouseArea {
                            id: btnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: parent.modelData.action()
                        }
                    }
                }
            }
        }

        // Hidden TextInput for receiving keypresses
        TextInput {
            id: passwordInput
            width: 1
            height: 1
            opacity: 0
            echoMode: TextInput.Password
            focus: true

            Keys.onReturnPressed: submit()
            Keys.onEnterPressed: submit()

            function submit() {
                if (!LockService.authenticating && text.length > 0)
                    LockService.tryUnlock(text);
            }
        }

        Connections {
            id: lockServiceConn
            target: LockService

            function onAuthSucceeded() {
                passwordField.forceActiveFocus();
                fadeOut.start();
            }

            function onFailedChanged() {
                if (LockService.failed) {
                    shakeAnim.start();
                    passwordInput.clear();
                }
            }
        }

        SequentialAnimation {
            id: fadeOut

            NumberAnimation {
                target: mainCard
                property: "opacity"
                to: 0
                duration: Config.animDurationLong
                easing.type: Easing.OutCubic
            }

            ScriptAction {
                script: {
                    lockServiceConn.enabled = false;
                    root.locked = false;
                }
            }
        }
    }
}

