pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs.services

Singleton {
    id: root

    // Direct bindings for reactivity — QML tracks these through `property var` dependencies
    readonly property var _s: StateService.state
    readonly property var _p: ThemeService.palette

    // ========================================================================
    // PALETTE (Catppuccin schema — from state/colors.json)
    // ========================================================================
    readonly property color backgroundColor: _p.base ?? "#1e1e2e"
    readonly property real backgroundOpacity: _s.opacity?.background ?? 0.98
    readonly property color backgroundTransparentColor: Qt.alpha(backgroundColor, backgroundOpacity)
    readonly property color surface0Color: _p.surface0 ?? "#313244"
    readonly property color surface1Color: _p.surface1 ?? "#45475a"
    readonly property color surface2Color: _p.surface2 ?? "#585b70"
    readonly property color surface3Color: _p.overlay0 ?? "#6c7086"

    readonly property color textColor: _p.text ?? "#cdd6f4"
    readonly property color textReverseColor: _p.base ?? "#1e1e2e"
    readonly property color subtextColor: _p.subtext0 ?? "#a6adc8"
    readonly property color subtextReverseColor: _p.overlay0 ?? "#6c7086"

    readonly property color accentColor: _p.mauve ?? "#cba6f7"
    readonly property color successColor: _p.green ?? "#a6e3a1"
    readonly property color warningColor: _p.yellow ?? "#f9e2af"
    readonly property color errorColor: _p.red ?? "#f38ba8"

    readonly property color mutedColor: _p.overlay0 ?? "#6c7086"
    readonly property color greyBlueColor: _p.surface1 ?? "#45475a"
    readonly property color blueDarkColor: _p.mantle ?? "#181825"

    readonly property color sepColor: surface3Color

    // ========================================================================
    // WALLPAPER
    // ========================================================================
    readonly property bool dynamicWallpaper: _s.wallpaper?.dynamic ?? true

    // ========================================================================
    // GEOMETRY & LAYOUT
    // ========================================================================
    readonly property int barHeight: _s.bar?.height ?? 26
    readonly property bool barAutoHide: _s.bar?.autoHide ?? true

    readonly property int radiusSmall: _s.geometry?.radiusSmall ?? 5
    readonly property int radius: _s.geometry?.radius ?? 10
    readonly property int radiusLarge: _s.geometry?.radiusLarge ?? 15
    readonly property int spacing: _s.geometry?.spacing ?? 8
    readonly property int padding: _s.geometry?.padding ?? 6

    // ========================================================================
    // TYPOGRAPHY
    // ========================================================================
    readonly property string font: _s.typography?.font ?? "Caskaydia Cove Nerd Font"
    readonly property string monoFont: _s.typography?.monoFont ?? "Caskaydia Cove Nerd Font Mono"

    readonly property int fontSizeSmall: _s.typography?.sizeSmall ?? 12
    readonly property int fontSizeNormal: _s.typography?.sizeNormal ?? 14
    readonly property int fontSizeLarge: _s.typography?.sizeLarge ?? 16
    readonly property int fontSizeIconSmall: _s.typography?.iconSmall ?? 18
    readonly property int fontSizeIcon: _s.typography?.icon ?? 22
    readonly property int fontSizeIconLarge: _s.typography?.iconLarge ?? 28

    // ========================================================================
    // ANIMATIONS
    // ========================================================================
    readonly property int animDurationShort: _s.animations?.short ?? 100
    readonly property int animDuration: _s.animations?.normal ?? 200
    readonly property int animDurationLong: _s.animations?.long ?? 400

    // Popup/overlay entry+exit animation presets (used by AnimatedPopup.qml)
    readonly property real animPopupFromScale: 0.92
    readonly property int animPopupEasing: Easing.OutExpo

    readonly property bool screenshotAnimations: _s.animations?.screenshot ?? true

    // ========================================================================
    // NOTIFICATIONS
    // ========================================================================
    readonly property int notifWidth: _s.notifications?.width ?? 350
    readonly property int notifImageSize: _s.notifications?.imageSize ?? 40
    readonly property int notifTimeout: _s.notifications?.timeout ?? 5000
    readonly property int notifSpacing: _s.notifications?.spacing ?? 10
}
