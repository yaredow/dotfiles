#!/bin/bash
set -e

NAME="ydot"
SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SRC_DIR/.." && pwd)"
# install.sh runs this via sudo, where $HOME would be /root — it passes the
# real user home as $1. Fall back to $HOME when invoked directly.
USER_HOME="${1:-$HOME}"
THEME_DIR="/usr/share/sddm/themes/$NAME"
CONFIG_DIR="/etc/sddm.conf.d"
STATE_FILE="$USER_HOME/.config/quickshell/state.json"
THEME_ROOT="$USER_HOME/.config/theme"

echo "Installing ydot SDDM theme (user: $USER_HOME)..."

# ── detect current theme ──
THEME_NAME="tokyonight"
if [[ -f "$STATE_FILE" ]]; then
    THEME_NAME=$(jq -r '.theme.name // "tokyonight"' "$STATE_FILE" 2>/dev/null || echo "tokyonight")
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

# ── read fonts ──
FONT="CaskaydiaCove Nerd Font"
MONO_FONT="CaskaydiaCove Nerd Font Mono"
if [[ -f "$STATE_FILE" ]]; then
    FONT=$(jq -r '.typography.font // "CaskaydiaCove Nerd Font"' "$STATE_FILE" 2>/dev/null || echo "$FONT")
    MONO_FONT=$(jq -r '.typography.monoFont // "CaskaydiaCove Nerd Font Mono"' "$STATE_FILE" 2>/dev/null || echo "$MONO_FONT")
fi

# ── stage the theme in a temp dir (never write into the git repo) ──
STAGING=$(mktemp -d)
trap 'rm -rf "$STAGING"' EXIT

cp "$SRC_DIR/Main.qml" "$SRC_DIR/metadata.desktop" "$STAGING/"
cp -r "$SRC_DIR/assets" "$STAGING/assets"

# ── bake in the current wallpaper, if available ──
WP=""
if [[ -f "$STATE_FILE" ]]; then
    WP=$(jq -r '.wallpaper.current // empty' "$STATE_FILE" 2>/dev/null || true)
fi
if [[ -n "$WP" && -f "$WP" ]]; then
    cp "$WP" "$STAGING/assets/background.jpg"
    echo "Wallpaper copied from: $WP"
fi

# ── generate theme.conf ──
cat > "$STAGING/theme.conf" << THEMECONF
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
monoFont=$MONO_FONT
use24HourClock=true
background=assets/background.jpg
THEMECONF

# ── install to SDDM ──
rm -rf "$THEME_DIR"
mkdir -p "$THEME_DIR"
cp "$STAGING/Main.qml" "$STAGING/metadata.desktop" "$STAGING/theme.conf" "$THEME_DIR/"
cp -r "$STAGING/assets" "$THEME_DIR/"

mkdir -p "$CONFIG_DIR"
cat > "$CONFIG_DIR/theme.conf" << EOF
[Theme]
Current=$NAME
EOF

# Deploy the repo's SDDM drop-ins (not stowed — these are templates only)
if [[ -f "$REPO_ROOT/sddm/etc/sddm.conf.d/hidpi.conf" ]]; then
    cp "$REPO_ROOT/sddm/etc/sddm.conf.d/hidpi.conf" "$CONFIG_DIR/hidpi.conf"
    echo "Installed HiDPI SDDM config."
fi

echo "Done. Test: sddm-greeter-qt6 --test-mode --theme $THEME_DIR"
