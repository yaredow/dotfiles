#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=wallpaper-lib.sh
source "$(dirname "$(readlink -f "$0")")/wallpaper-lib.sh"

# Usage:
#   wallpaper-set.sh                 # restore wallpaper.current or theme default
#   wallpaper-set.sh /path/to/img    # set explicit path

THEME=$(wallpaper_state_get "theme.name" "tokyonight")
CURRENT=$(wallpaper_state_get "wallpaper.current" "")
[[ -z "$CURRENT" && -f "$WALLPAPER_ROOT/.current" ]] && CURRENT=$(cat "$WALLPAPER_ROOT/.current" 2>/dev/null || true)

WP_FILE="${1:-}"
if [[ -z "$WP_FILE" ]]; then
  WP_FILE=$(wallpaper_resolve_for_theme "$THEME" "$CURRENT")
fi

if [[ -z "$WP_FILE" || ! -f "$WP_FILE" ]]; then
  notify-send "Wallpaper" "No wallpaper found for ${THEME}" -t 3000 2>/dev/null || true
  exit 1
fi

# Only animate when a session is running
if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] || pgrep -x awww-daemon >/dev/null 2>&1; then
  wallpaper_awww_set "$WP_FILE" || true
else
  mkdir -p "$WALLPAPER_ROOT"
  printf '%s\n' "$WP_FILE" >"$WALLPAPER_ROOT/.current"
fi

wallpaper_state_update "" "$WP_FILE"
