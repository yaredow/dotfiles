#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=wallpaper-lib.sh
source "$(dirname "$(readlink -f "$0")")/wallpaper-lib.sh"

THEME=$(wallpaper_state_get "theme.name" "tokyonight")
CURRENT=$(wallpaper_state_get "wallpaper.current" "")
[[ -z "$CURRENT" && -f "$WALLPAPER_ROOT/.current" ]] && CURRENT=$(cat "$WALLPAPER_ROOT/.current" 2>/dev/null || true)

WP_FILE=$(wallpaper_next_in_theme "$THEME" "$CURRENT" || true)

if [[ -z "${WP_FILE:-}" || ! -f "$WP_FILE" ]]; then
  notify-send "Wallpaper" "No wallpapers in ${THEME}" -t 3000 2>/dev/null || true
  exit 1
fi

wallpaper_awww_set "$WP_FILE" || true
wallpaper_state_update "" "$WP_FILE"

notify-send "Wallpaper" "$(basename "$(dirname "$WP_FILE")")/$(basename "$WP_FILE")" -t 2000 2>/dev/null || true
