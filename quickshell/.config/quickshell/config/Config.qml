pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs.services

Singleton {
    id: root

    // Helper function to shorten the service call
    function getState(path, fallback) {
        return StateService.get(path, fallback);
    }

    // ========================================================================
    // PALETTE (Catppuccin schema — from state/colors.json)
    // ========================================================================
    readonly property color backgroundColor: ThemeService.color("base", "#1e1e2e")
    readonly property real backgroundOpacity: getState("opacity.background", 0.9)
    readonly property color backgroundTransparentColor: Qt.alpha(backgroundColor, backgroundOpacity)
    readonly property color surface0Color: ThemeService.color("surface0", "#313244")
    readonly property color surface1Color: ThemeService.color("surface1", "#45475a")
    readonly property color surface2Color: ThemeService.color("surface2", "#585b70")
    readonly property color surface3Color: ThemeService.color("overlay0", "#6c7086")

    readonly property color textColor: ThemeService.color("text", "#cdd6f4")
    readonly property color textReverseColor: ThemeService.color("base", "#1e1e2e")
    readonly property color subtextColor: ThemeService.color("subtext0", "#a6adc8")
    readonly property color subtextReverseColor: ThemeService.color("overlay0", "#6c7086")

    readonly property color accentColor: ThemeService.color("mauve", "#cba6f7")
    readonly property color successColor: ThemeService.color("green", "#a6e3a1")
    readonly property color warningColor: ThemeService.color("yellow", "#f9e2af")
    readonly property color errorColor: ThemeService.color("red", "#f38ba8")

    readonly property color mutedColor: ThemeService.color("overlay0", "#6c7086")
    readonly property color greyBlueColor: ThemeService.color("surface1", "#45475a")
    readonly property color blueDarkColor: ThemeService.color("mantle", "#181825")

    readonly property color sepColor: surface3Color

    // ========================================================================
    // WALLPAPER
    // ========================================================================
    readonly property bool dynamicWallpaper: getState("wallpaper.dynamic", true)

    // ========================================================================
    // GEOMETRY & LAYOUT
    // ========================================================================
    readonly property int barHeight: getState("bar.height", 32)
    readonly property bool barAutoHide: getState("bar.autoHide", true)

    readonly property int radiusSmall: getState("geometry.radiusSmall", 5)
    readonly property int radius: getState("geometry.radius", 10)
    readonly property int radiusLarge: getState("geometry.radiusLarge", 15)
    readonly property int spacing: getState("geometry.spacing", 8)
    readonly property int padding: getState("geometry.padding", 6)

    // ========================================================================
    // TYPOGRAPHY
    // ========================================================================
    readonly property string font: getState("typography.font", "Caskaydia Cove Nerd Font")
    readonly property string monoFont: getState("typography.monoFont", "Caskaydia Cove Nerd Font Mono")

    readonly property int fontSizeSmall: getState("typography.sizeSmall", 12)
    readonly property int fontSizeNormal: getState("typography.sizeNormal", 14)
    readonly property int fontSizeLarge: getState("typography.sizeLarge", 16)
    readonly property int fontSizeIconSmall: getState("typography.iconSmall", 18)
    readonly property int fontSizeIcon: getState("typography.icon", 22)
    readonly property int fontSizeIconLarge: getState("typography.iconLarge", 28)

    // ========================================================================
    // ANIMATIONS
    // ========================================================================
    readonly property int animDurationShort: getState("animations.short", 100)
    readonly property int animDuration: getState("animations.normal", 200)
    readonly property int animDurationLong: getState("animations.long", 400)

    // Popup/overlay entry+exit animation presets (used by AnimatedPopup.qml)
    readonly property real animPopupFromScale: 0.92
    readonly property int animPopupEasing: Easing.OutExpo

    readonly property bool screenshotAnimations: getState("animations.screenshot", true)

    // ========================================================================
    // NOTIFICATIONS
    // ========================================================================
    readonly property int notifWidth: getState("notifications.width", 350)
    readonly property int notifImageSize: getState("notifications.imageSize", 40)
    readonly property int notifTimeout: getState("notifications.timeout", 5000)
    readonly property int notifSpacing: getState("notifications.spacing", 10)
}
