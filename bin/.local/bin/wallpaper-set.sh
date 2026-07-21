#!/usr/bin/env bash
set -euo pipefail

STATE_FILE="$HOME/.config/quickshell/state.json"
WALLPAPER_DIR="$HOME/.local/wallpapers"

THEME="tokyonight"
INDEX=0
if [[ -f "$STATE_FILE" ]]; then
  THEME=$(jq -r '.["theme.name"] // "tokyonight"' "$STATE_FILE")
  INDEX=$(jq -r '.["wallpaper.index"] // 0 | tonumber' "$STATE_FILE")
fi

WALLPAPER_MAP='{"tokyonight":"tokyonight","catppuccin":"catppuccin","rosepine":"rose-pine"}'
WP_PREFIX=$(echo "$WALLPAPER_MAP" | jq -r ".$THEME")
WP_NUM=$(( INDEX + 1 ))

WP_FILE=$(find "$WALLPAPER_DIR" -maxdepth 1 -name "${WP_PREFIX}-${WP_NUM}.*" -type f 2>/dev/null | head -1)

if [[ -z "$WP_FILE" ]]; then
  notify-send "Wallpaper" "No wallpaper found: ${WP_PREFIX}-${WP_NUM}" -t 3000
  exit 1
fi

awww img "$WP_FILE" --transition-type grow --transition-step 30 --transition-fps 60 --transition-pos 0.5,0.5 2>/dev/null || true
