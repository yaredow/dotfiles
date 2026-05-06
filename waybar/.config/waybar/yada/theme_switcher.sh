#!/bin/bash

# brewland theme switcher
# toggles between catppuccin latte and mocha across the system

RELOAD_FISH_SHELL="${RELOAD_FISH_SHELL:-false}"
CONF_DIR="$HOME/.config"
THEME_DIR="$CONF_DIR/hypr/themes"
GTK_THEME_SOURCE="$CONF_DIR/brewland/themes/gtkthemes"
BRIDGE_FILE="$CONF_DIR/hypr/HLconfigs/theme-colors.conf"

info() { echo -e "\033[0;34m[ INFO ]\033[0m $1"; }
ok() { echo -e "\033[0;32m[ OKAY ]\033[0m $1"; }
warn() { echo -e "\033[0;33m[ WARN ]\033[0m $1"; }

safe_sed() {
    [[ -f "$2" ]] && sed -i "$1" "$2"
}

safe_ln() {
    if [[ -e "$1" ]]; then
        ln -sf "$1" "$2"
    else
        warn "$1 not found, skipping link to $2"
    fi
}

# figure out which flavor to switch to
CURRENT_THEME=$(readlink "$BRIDGE_FILE" 2>/dev/null)
if [[ "$1" == "latte" || "$1" == "mocha" ]]; then
    NEW_FLAVOR="$1"
else
    if [[ "$CURRENT_THEME" == *"/mocha.conf" ]]; then
        NEW_FLAVOR="latte"
    else
        NEW_FLAVOR="mocha"
    fi
fi

info "switching to catppuccin $NEW_FLAVOR..."

if [[ "$NEW_FLAVOR" == "latte" ]]; then
    GTK_THEME="catppuccin-latte-mauve-standard+default"
    KVANTUM_THEME="catppuccin-latte-mauve"
    COLOR_SCHEME="prefer-light"
    VSCODE_THEME="Catppuccin Latte"
else
    GTK_THEME="catppuccin-mocha-mauve-standard+default"
    KVANTUM_THEME="catppuccin-mocha-mauve"
    COLOR_SCHEME="prefer-dark"
    VSCODE_THEME="Catppuccin Mocha"
fi

# --- hyprland & desktop ---
safe_ln "$THEME_DIR/$NEW_FLAVOR.conf" "$BRIDGE_FILE"
hyprctl source "$BRIDGE_FILE" &>/dev/null
safe_ln "$CONF_DIR/hypr/hyprlock/themes/$NEW_FLAVOR.conf" "$CONF_DIR/hypr/hyprlock/themes/current.conf"

# --- gtk ---
gsettings set org.gnome.desktop.interface color-scheme "$COLOR_SCHEME"
gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME"

for dir in "$HOME/.local/share/themes" "$CONF_DIR/gtk-4.0"; do
    mkdir -p "$dir"
done

if [[ -d "$GTK_THEME_SOURCE/$GTK_THEME" ]]; then
    [[ ! -d "$HOME/.local/share/themes/$GTK_THEME" ]] && \
        safe_ln "$GTK_THEME_SOURCE/$GTK_THEME" "$HOME/.local/share/themes/$GTK_THEME"
    
    safe_ln "$GTK_THEME_SOURCE/$GTK_THEME/gtk-4.0/gtk.css" "$CONF_DIR/gtk-4.0/gtk.css"
    safe_ln "$GTK_THEME_SOURCE/$GTK_THEME/gtk-4.0/gtk-dark.css" "$CONF_DIR/gtk-4.0/gtk-dark.css"
    safe_ln "$GTK_THEME_SOURCE/$GTK_THEME/gtk-4.0/assets" "$CONF_DIR/gtk-4.0/assets"
fi

# --- status bar & notifications ---
safe_sed "s|@import .*|@import \"../waybar/colors/$NEW_FLAVOR.css\";|" "$CONF_DIR/waybar/style.css"
pkill -USR2 waybar

safe_ln "$CONF_DIR/swaync/colors/$NEW_FLAVOR.css" "$CONF_DIR/swaync/colors/current_colors.css"
swaync-client -rs &>/dev/null
echo "$NEW_FLAVOR" > "$CONF_DIR/swaync/current_flavor"

# --- terminal & apps ---
safe_sed "s|^include .*|include $NEW_FLAVOR.conf|" "$CONF_DIR/kitty/kitty.conf"
pgrep -x kitty > /dev/null && pkill -USR1 -x kitty

for settings in "$CONF_DIR/VSCodium/User/settings.json" "$CONF_DIR/Antigravity/User/settings.json"; do
    if [[ -f "$settings" ]]; then
        safe_sed "s/\"workbench.colorTheme\": \".*\"/\"workbench.colorTheme\": \"$VSCODE_THEME\"/" "$settings"
        safe_sed "s/\"workbench.iconTheme\": \".*\"/\"workbench.iconTheme\": \"catppuccin-$NEW_FLAVOR\"/" "$settings"
    fi
done

# --- system utils ---
safe_ln "$CONF_DIR/fish/themes/Catppuccin ${NEW_FLAVOR^}.theme" "$CONF_DIR/fish/themes/current_theme.theme"
[[ "$RELOAD_FISH_SHELL" == "true" ]] && pkill -USR1 fish

pgrep -x rofi >/dev/null && pkill -x rofi
[[ -f "$CONF_DIR/rofi/themes/$NEW_FLAVOR.rasi" ]] && \
    cp "$CONF_DIR/rofi/themes/$NEW_FLAVOR.rasi" "$CONF_DIR/rofi/themes/colors.rasi"

safe_ln "$CONF_DIR/fastfetch/themes/$NEW_FLAVOR.jsonc" "$CONF_DIR/fastfetch/config.jsonc"

if pgrep -x cava >/dev/null; then
    pkill -x cava
fi
safe_ln "$CONF_DIR/cava/themes/$NEW_FLAVOR-transparent.cava" "$CONF_DIR/cava/config"

echo "$NEW_FLAVOR" > "$CONF_DIR/nvim/current_flavor"
pgrep -x nvim > /dev/null && pkill -USR1 -x nvim

if command -v kvantummanager &> /dev/null; then
    kvantummanager --set "$KVANTUM_THEME" &>/dev/null
fi

notify-send -a "System Switcher" "Theme Toggled" "Switching to $NEW_FLAVOR"
ok "theme set to $NEW_FLAVOR."
