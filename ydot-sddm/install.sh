#!/bin/bash
set -e

NAME="ydot"
SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
THEME_DIR="/usr/share/sddm/themes/$NAME"
CONFIG_DIR="/etc/sddm.conf.d"
USER_HOME="${1:-$HOME}"

echo "Installing ydot SDDM theme..."

mkdir -p "$THEME_DIR"
cp -r "$SRC_DIR/Main.qml" "$SRC_DIR/metadata.desktop" "$SRC_DIR/theme.conf" "$SRC_DIR/assets" "$THEME_DIR/"

# Copy current wallpaper as background
WP=$(find "$USER_HOME/.local/wallpapers" -name "tokyonight-1.*" -type f 2>/dev/null | head -1)
if [[ -n "$WP" ]]; then
  cp "$WP" "$THEME_DIR/assets/background.jpg"
fi

mkdir -p "$CONFIG_DIR"

cat > "$CONFIG_DIR/theme.conf" << EOF
[Theme]
Current=$NAME
EOF

cat > "$CONFIG_DIR/hidpi.conf" << 'EOF'
[Wayland]
EnableHiDPI=true

[X11]
EnableHiDPI=true

[General]
GreeterEnvironment=QT_SCREEN_SCALE_FACTORS=2,QT_FONT_DPI=192
EOF

echo "Done. Test: sddm-greeter-qt6 --test-mode --theme $THEME_DIR"
