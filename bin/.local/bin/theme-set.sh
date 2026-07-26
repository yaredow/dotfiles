#!/usr/bin/env bash
set -euo pipefail

THEME_ROOT="$HOME/.config/theme"
THEME="${1:?Usage: theme-set.sh <tokyonight|catppuccin|rosepine>}"
THEME_DIR="$THEME_ROOT/themes/$THEME"

[[ -d "$THEME_DIR" ]] || { echo "Theme not found: $THEME"; exit 1; }
[[ -f "$THEME_DIR/colors.json" ]] || { echo "Missing colors.json in theme: $THEME"; exit 1; }

COLORS=$(cat "$THEME_DIR/colors.json")

mkdir -p "$HOME/.config/quickshell/state"
cp "$THEME_DIR/colors.json" "$HOME/.config/quickshell/state/colors.json"

notify-send "Theme" "${THEME}" -t 2000

# Wallpaper first — everything else can wait
WALLPAPER_MAP='{"tokyonight":"tokyonight","catppuccin":"catppuccin","rosepine":"rose-pine"}'
WP_PREFIX=$(echo "$WALLPAPER_MAP" | jq -r ".$THEME")
WP_FILE=$(find "$HOME/.local/wallpapers" -maxdepth 1 -name "${WP_PREFIX}-1.*" -type f 2>/dev/null | head -1)
if [[ -n "$WP_FILE" ]]; then
  awww img "$WP_FILE" --transition-type grow --transition-step 30 --transition-fps 60 --transition-pos 0.5,0.5 2>/dev/null || true
fi

render() {
  local tpl="$THEME_ROOT/templates/$1.tpl"
  local dst="$2"
  mkdir -p "$(dirname "$dst")"
  local args=()
  for key in crust mantle base surface0 surface1 surface2 overlay0 overlay1 overlay2 \
             text subtext0 subtext1 rosewater flamingo pink mauve red maroon peach \
             yellow green teal sky sapphire blue lavender; do
    val=$(echo "$COLORS" | jq -r ".$key")
    args+=(-e "s|{{${key}}}|${val}|g" -e "s|{{${key}_strip}}|${val#\#}|g")
  done
  sed "${args[@]}" "$tpl" > "$dst"
}

KITTY_THEME="$HOME/.config/kitty/theme.conf"

FONT_MONO=$(echo "$COLORS" | jq -r '.fonts.mono // "JetBrainsMono Nerd Font"')
FONT_SIZE=$(echo "$COLORS" | jq -r '.fonts.size // 13')

# Global font override from quickshell state (settings panel)
STATE_FILE="$HOME/.config/quickshell/state.json"
if [[ -f "$STATE_FILE" ]]; then
  OVERRIDE=$(jq -r '.typography.monoFont // ""' "$STATE_FILE" 2>/dev/null || echo "")
  [[ -n "$OVERRIDE" ]] && FONT_MONO="$OVERRIDE"
fi

render kitty.conf        "$KITTY_THEME.tmp"
render hypr-colors.lua   "$HOME/.config/hypr/theme.lua"
render tmux.conf         "$HOME/.config/tmux/theme.conf"
render fastfetch.jsonc   "$HOME/.config/fastfetch/config.jsonc"

{
  echo ""
  echo "font_family $FONT_MONO"
  echo "font_size $FONT_SIZE"
  echo "bold_font $FONT_MONO"
  echo "italic_font auto"
  echo "bold_italic_font auto"
} >> "$KITTY_THEME.tmp"
mv "$KITTY_THEME.tmp" "$KITTY_THEME"

kitty @ set-colors --all --configured "$KITTY_THEME" 2>/dev/null || true

PALETTE_MAP='{"tokyonight":"tokyonight_night","catppuccin":"catppuccin_mocha","rosepine":"rose_pine"}'
PALETTE=$(echo "$PALETTE_MAP" | jq -r ".$THEME")
STARSHIP_TARGET=$(readlink -f "$HOME/.config/starship.toml" 2>/dev/null || echo "$HOME/.config/starship.toml")
sed -i "s/^palette = .*/palette = \"$PALETTE\"/" "$STARSHIP_TARGET"

hyprctl reload >/dev/null 2>&1 || true
pkill -SIGUSR1 kitty 2>/dev/null || true
tmux source-file ~/.tmux.conf 2>/dev/null || true

# Write theme name + reset wallpaper index
STATE_FILE="$HOME/.config/quickshell/state.json"
if [[ -f "$STATE_FILE" ]]; then
  jq --arg theme "$THEME" '.["theme.name"] = $theme | .["wallpaper.index"] = 0' "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
fi

ln -sfn "$THEME_DIR" "$HOME/.config/theme/current"

NVIM_THEME_MAP='{"tokyonight":"tokyonight-night","catppuccin":"catppuccin-mocha","rosepine":"rose-pine"}'
NVIM_THEME=$(echo "$NVIM_THEME_MAP" | jq -r ".$THEME")
mkdir -p "$HOME/.config/nvim/lua"
echo "return \"$NVIM_THEME\"" > "$HOME/.config/nvim/lua/theme.lua"

echo "Theme set to: $THEME"
