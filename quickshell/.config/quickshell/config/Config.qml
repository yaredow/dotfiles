pragma Singleton
import QtQuick
import Quickshell

Singleton {
    // TokyoNight palette
    readonly property color bg: "#1a1b26"
    readonly property color fg: "#c0caf5"
    readonly property color blue: "#7aa2f7"
    readonly property color yellow: "#e0af68"
    readonly property color muted: "#565f89"
    readonly property color selection: "#283457"

    // Extended palette (lyne-dots compat)
    readonly property color backgroundColor: bg
    readonly property color surface0Color: "#24283b"
    readonly property color surface1Color: "#292e42"
    readonly property color surface2Color: "#414868"
    readonly property color surface3Color: "#565f89"

    readonly property color textColor: fg
    readonly property color textReverseColor: bg
    readonly property color subtextColor: "#a9b1d6"
    readonly property color subtextReverseColor: muted

    readonly property color accentColor: blue
    readonly property color successColor: "#9ece6a"
    readonly property color warningColor: yellow
    readonly property color errorColor: "#f7768e"

    readonly property color mutedColor: "#545c7e"
    readonly property color greyBlueColor: selection
    readonly property color blueDarkColor: "#16161e"

    // Opacity
    readonly property real backgroundOpacity: 0.93
    readonly property color backgroundTransparentColor: Qt.alpha(backgroundColor, backgroundOpacity)

    // Fonts
    readonly property string iconFont: "JetBrainsMono Nerd Font Propo"
    readonly property string labelFont: "SF Pro Display"
    readonly property string monoFont: "SF Mono"
    readonly property string font: "JetBrainsMono Nerd Font Propo"
    readonly property int fontWeight: Font.Medium

    // Typography sizes
    readonly property int fontSizeSmall: 12
    readonly property int fontSizeNormal: 14
    readonly property int fontSizeLarge: 16
    readonly property int fontSizeIconSmall: 18
    readonly property int fontSizeIcon: 22
    readonly property int fontSizeIconLarge: 28

    // Widget sizes
    readonly property int iconSize: 13
    readonly property int labelSize: 13
    readonly property int wsFontSize: 13
    readonly property int clockSize: 14

    // Geometry & layout
    readonly property int barHeight: 24
    readonly property bool barAutoHide: false
    readonly property int barPadding: 14
    readonly property int widgetSpacing: 6

    readonly property int radiusSmall: 5
    readonly property int radius: 10
    readonly property int radiusLarge: 15
    readonly property int spacing: 8
    readonly property int padding: 6

    // Separator
    readonly property color sepColor: Qt.alpha(textColor, 0.18)

    // Animations
    readonly property int animDurationShort: 100
    readonly property int animDuration: 200
    readonly property int animDurationLong: 400
    readonly property real animPopupFromScale: 0.92
    readonly property int animPopupEasing: Easing.OutExpo

    // Notifications
    readonly property int notifWidth: 350
    readonly property int notifImageSize: 40
    readonly property int notifTimeout: 5000
    readonly property int notifSpacing: 10
}
