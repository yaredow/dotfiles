#!/bin/bash
set -e

NAME="ydot"
SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
THEME_DIR="/usr/share/sddm/themes/$NAME"
CONFIG_DIR="/etc/sddm.conf.d"
STATE_FILE="$HOME/.config/quickshell/state.json"
THEME_ROOT="$HOME/.config/theme"

echo "Installing ydot SDDM theme..."

# ── detect current theme ──
THEME_NAME="tokyonight"
if [[ -f "$STATE_FILE" ]]; then
    THEME_NAME=$(jq -r '.theme.name // .theme // "tokyonight"' "$STATE_FILE" 2>/dev/null || echo "tokyonight")
fi
echo "Theme: $THEME_NAME"

# ── read color palette ──
COLORS_FILE="$THEME_ROOT/themes/$THEME_NAME/colors.json"
BG="1a1b26"
TEXT="cdd6f4"
SUBTEXT="a6adc8"
ACCENT="7aa2f7"
SURFACE0="313244"
SURFACE1="45475a"
SURFACE2="585b70"
MUTED="6c7086"
ERR="f38ba8"

if [[ -f "$COLORS_FILE" ]]; then
    BG=$(jq -r '.base // "#1a1b26"' "$COLORS_FILE" | sed 's/^#//')
    TEXT=$(jq -r '.text // "#cdd6f4"' "$COLORS_FILE" | sed 's/^#//')
    SUBTEXT=$(jq -r '.subtext0 // "#a6adc8"' "$COLORS_FILE" | sed 's/^#//')
    ACCENT=$(jq -r '.blue // "#7aa2f7"' "$COLORS_FILE" | sed 's/^#//')
    SURFACE0=$(jq -r '.surface0 // "#313244"' "$COLORS_FILE" | sed 's/^#//')
    SURFACE1=$(jq -r '.surface1 // "#45475a"' "$COLORS_FILE" | sed 's/^#//')
    SURFACE2=$(jq -r '.surface2 // "#585b70"' "$COLORS_FILE" | sed 's/^#//')
    MUTED=$(jq -r '.overlay0 // "#6c7086"' "$COLORS_FILE" | sed 's/^#//')
    ERR=$(jq -r '.red // "#f38ba8"' "$COLORS_FILE" | sed 's/^#//')
fi

# ── read font ──
FONT="FiraCode Nerd Font Mono"
if [[ -f "$STATE_FILE" ]]; then
    FONT=$(jq -r '.typography.monoFont // .fonts.mono // "FiraCode Nerd Font Mono"' "$STATE_FILE" 2>/dev/null || echo "$FONT")
fi

# ── copy wallpaper into theme dir ──
WALLPAPER_PATH="assets/background.jpg"
if [[ -f "$STATE_FILE" ]]; then
    WP=$(jq -r '.wallpaper.current // empty' "$STATE_FILE" 2>/dev/null || true)
    if [[ -n "$WP" && -f "$WP" ]]; then
        cp "$WP" "$SRC_DIR/assets/background.jpg"
        echo "Wallpaper copied from: $WP"
    fi
fi

# ── generate theme.conf ──
cat > "$SRC_DIR/theme.conf" << THEMECONF
[Theme]
backgroundColor=#$BG
textColor=#$TEXT
subtextColor=#$SUBTEXT
accentColor=#$ACCENT
surface0=#$SURFACE0
surface1=#$SURFACE1
surface2=#$SURFACE2
mutedColor=#$MUTED
errorColor=#$ERR
font=$FONT
use24HourClock=true
background=$WALLPAPER_PATH
THEMECONF

# ── install to SDDM ──
mkdir -p "$THEME_DIR"
cp "$SRC_DIR/Main.qml" "$SRC_DIR/metadata.desktop" "$SRC_DIR/theme.conf" "$THEME_DIR/"
cp -r "$SRC_DIR/assets" "$THEME_DIR/"

mkdir -p "$CONFIG_DIR"
cat > "$CONFIG_DIR/theme.conf" << EOF
[Theme]
Current=$NAME
EOF

echo "Done. Test: sddm-greeter-qt6 --test-mode --theme $THEME_DIR"
