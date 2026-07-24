#!/bin/bash
set -e

NAME="yadot"
SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
THEME_DIR="/usr/share/sddm/themes/$NAME"
CONFIG_DIR="/etc/sddm.conf.d"

echo "Installing yadot SDDM theme..."

mkdir -p "$THEME_DIR"
cp -r "$SRC_DIR/Main.qml" "$SRC_DIR/metadata.desktop" "$SRC_DIR/theme.conf" "$SRC_DIR/assets" "$THEME_DIR/"

# Copy current wallpaper as background
WP=$(find /home/yada/.local/wallpapers -name "tokyonight-1.*" -type f 2>/dev/null | head -1)
if [[ -n "$WP" ]]; then
  cp "$WP" "$THEME_DIR/assets/background.jpg"
fi

mkdir -p "$CONFIG_DIR"
echo -e "[Theme]\nCurrent=$NAME" > "$CONFIG_DIR/theme.conf"

echo "Done. Test: sddm-greeter-qt6 --test-mode --theme $THEME_DIR"
