#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=wallpaper-lib.sh
source "$(dirname "$(readlink -f "$0")")/wallpaper-lib.sh"

THEME_ROOT="${THEME_ROOT:-$HOME/.config/theme}"
THEME="${1:-}"
if [[ -z "$THEME" ]]; then
  echo "Usage: theme-set.sh <theme>" >&2
  echo "Available:" >&2
  wallpaper_list_themes | sed 's/^/  /' >&2
  exit 1
fi

THEME_DIR="$THEME_ROOT/themes/$THEME"
[[ -d "$THEME_DIR" ]] || { echo "Theme not found: $THEME" >&2; exit 1; }
[[ -f "$THEME_DIR/colors.json" ]] || { echo "Missing colors.json in theme: $THEME" >&2; exit 1; }

COLORS=$(cat "$THEME_DIR/colors.json")

mkdir -p "$HOME/.config/quickshell/state"
cp "$THEME_DIR/colors.json" "$HOME/.config/quickshell/state/colors.json"

# Wallpaper early for perceived snappiness
CURRENT=$(wallpaper_state_get "wallpaper.current" "")
WP_FILE=$(wallpaper_resolve_for_theme "$THEME" "$CURRENT")
if [[ -n "$WP_FILE" && -f "$WP_FILE" ]]; then
  if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] || pgrep -x awww-daemon >/dev/null 2>&1; then
    wallpaper_awww_set "$WP_FILE" || true
  fi
fi

render() {
  local tpl="$THEME_ROOT/templates/$1.tpl"
  local dst="$2"
  [[ -f "$tpl" ]] || return 0
  mkdir -p "$(dirname "$dst")"
  local args=()
  local key val
  for key in crust mantle base surface0 surface1 surface2 overlay0 overlay1 overlay2 \
             text subtext0 subtext1 rosewater flamingo pink mauve red maroon peach \
             yellow green teal sky sapphire blue lavender; do
    val=$(echo "$COLORS" | jq -r --arg k "$key" '.[$k] // empty')
    [[ -n "$val" && "$val" != "null" ]] || continue
    args+=(-e "s|{{${key}}}|${val}|g" -e "s|{{${key}_strip}}|${val#\#}|g")
  done

  # integrations + fonts
  local starship nvim mono size
  starship=$(echo "$COLORS" | jq -r '.integrations.starship // empty')
  nvim=$(echo "$COLORS" | jq -r '.integrations.nvim // empty')
  mono=$(echo "$COLORS" | jq -r '.fonts.mono // "JetBrainsMono Nerd Font"')
  size=$(echo "$COLORS" | jq -r '.fonts.size // 13')

  # Global font override from quickshell state
  if [[ -f "$STATE_FILE" ]]; then
    local override
    override=$(jq -r '.typography.monoFont // empty' "$STATE_FILE" 2>/dev/null || true)
    [[ -n "$override" && "$override" != "null" ]] && mono="$override"
  fi

  [[ -n "$starship" ]] && args+=(-e "s|{{starship_palette}}|${starship}|g")
  [[ -n "$nvim" ]] && args+=(-e "s|{{nvim_colorscheme}}|${nvim}|g")
  args+=(-e "s|{{font_mono}}|${mono}|g" -e "s|{{font_size}}|${size}|g")


  if ((${#args[@]})); then
    sed "${args[@]}" "$tpl" >"$dst"
  else
    cp "$tpl" "$dst"
  fi
}

KITTY_THEME="$HOME/.config/kitty/theme.conf"
FONT_MONO=$(echo "$COLORS" | jq -r '.fonts.mono // "JetBrainsMono Nerd Font"')
FONT_SIZE=$(echo "$COLORS" | jq -r '.fonts.size // 13')
if [[ -f "$STATE_FILE" ]]; then
  OVERRIDE=$(jq -r '.typography.monoFont // empty' "$STATE_FILE" 2>/dev/null || true)
  [[ -n "$OVERRIDE" && "$OVERRIDE" != "null" ]] && FONT_MONO="$OVERRIDE"
fi

render kitty.conf "$KITTY_THEME.tmp"
render hypr-colors.lua "$HOME/.config/hypr/theme.lua"
render tmux.conf "$HOME/.config/tmux/theme.conf"
render fastfetch.jsonc "$HOME/.config/fastfetch/config.jsonc"
mkdir -p "$HOME/.config/btop/themes"
render btop.theme "$HOME/.config/btop/themes/theme.theme"
render starship.toml "$HOME/.config/starship.toml"


{
  echo ""
  echo "font_family $FONT_MONO"
  echo "font_size $FONT_SIZE"
  echo "bold_font $FONT_MONO"
  echo "italic_font auto"
  echo "bold_italic_font auto"
} >>"$KITTY_THEME.tmp"
mv "$KITTY_THEME.tmp" "$KITTY_THEME"

kitty @ set-colors --all --configured "$KITTY_THEME" 2>/dev/null || true
hyprctl reload >/dev/null 2>&1 || true
pkill -SIGUSR1 kitty 2>/dev/null || true
tmux source-file ~/.tmux.conf 2>/dev/null || true

NVIM_THEME=$(echo "$COLORS" | jq -r '.integrations.nvim // "tokyonight-night"')
mkdir -p "$HOME/.config/nvim/lua"
echo "return \"$NVIM_THEME\"" >"$HOME/.config/nvim/lua/theme.lua"

ln -sfn "$THEME_DIR" "$HOME/.config/theme/current"

wallpaper_state_update "$THEME" "${WP_FILE:-}"

echo "Theme set to: $THEME"
