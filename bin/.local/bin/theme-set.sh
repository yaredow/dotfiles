#!/usr/bin/env bash
set -euo pipefail

THEME_ROOT="$HOME/.config/theme"
THEME="${1:?Usage: theme-set.sh <tokyonight|catppuccin|rosepine>}"
THEME_DIR="$THEME_ROOT/themes/$THEME"

[[ -d "$THEME_DIR" ]] || { echo "Theme not found: $THEME"; exit 1; }

COLORS=$(cat "$THEME_DIR/colors.json")

mkdir -p "$HOME/.config/quickshell/state"
cp "$THEME_DIR/colors.json" "$HOME/.config/quickshell/state/colors.json"

render() {
  local tpl="$THEME_ROOT/templates/$1.tpl"
  local dst="$2"
  mkdir -p "$(dirname "$dst")"
  sed_cmd=""
  for key in crust mantle base surface0 surface1 surface2 overlay0 overlay1 overlay2 \
             text subtext0 subtext1 rosewater flamingo pink mauve red maroon peach \
             yellow green teal sky sapphire blue lavender; do
    val=$(echo "$COLORS" | jq -r ".$key")
    sed_cmd+=" -e 's/{{$key}}/$val/g'"
    sed_cmd+=" -e 's/{{${key}_strip}}/${val#\#}/g'"
  done
  eval "sed $sed_cmd" "$tpl" > "$dst"
}

render kitty.conf        "$HOME/.config/kitty/theme.conf"
render hypr-colors.lua   "$HOME/.config/hypr/theme.lua"
render tmux.conf         "$HOME/.config/tmux/theme.conf"

PALETTE_MAP='{"tokyonight":"tokyonight_night","catppuccin":"catppuccin_mocha","rosepine":"rose_pine"}'
PALETTE=$(echo "$PALETTE_MAP" | jq -r ".$THEME")
STARSHIP_TARGET=$(readlink -f "$HOME/.config/starship.toml" 2>/dev/null || echo "$HOME/.config/starship.toml")
sed -i "s/^palette = .*/palette = \"$PALETTE\"/" "$STARSHIP_TARGET"

# Fonts
FONT_MONO=$(echo "$COLORS" | jq -r '.fonts.mono // "JetBrainsMono Nerd Font"')
FONT_SIZE=$(echo "$COLORS" | jq -r '.fonts.size // 13')
{
  echo ""
  echo "font_family $FONT_MONO"
  echo "font_size $FONT_SIZE"
  echo "bold_font $FONT_MONO"
  echo "italic_font auto"
  echo "bold_italic_font auto"
} >> "$HOME/.config/kitty/theme.conf"

# Wallpaper
WALLPAPER=$(echo "$COLORS" | jq -r '.wallpaper // ""')
if [[ -n "$WALLPAPER" ]]; then
  WALLPAPER_PATH="$HOME/.local/wallpapers/$WALLPAPER"
  if [[ -f "$WALLPAPER_PATH" ]]; then
    hyprctl hyprpaper wallpaper ",$WALLPAPER_PATH,cover" >/dev/null 2>&1 || true
  fi
fi

hyprctl reload >/dev/null 2>&1 || true
pkill -SIGUSR1 kitty 2>/dev/null || true
tmux source-file ~/.tmux.conf 2>/dev/null || true

ln -sfn "$THEME_DIR" "$HOME/.config/theme/current"

NVIM_THEME_MAP='{"tokyonight":"tokyonight-night","catppuccin":"catppuccin-mocha","rosepine":"rose-pine"}'
NVIM_THEME=$(echo "$NVIM_THEME_MAP" | jq -r ".$THEME")
mkdir -p "$HOME/.config/nvim/lua"
echo "return \"$NVIM_THEME\"" > "$HOME/.config/nvim/lua/theme.lua"

echo "Theme set to: $THEME"
