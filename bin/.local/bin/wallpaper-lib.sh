#!/usr/bin/env bash
# Shared wallpaper helpers — source from other scripts (bash), do not exec.
# shellcheck shell=bash

WALLPAPER_ROOT="${WALLPAPER_ROOT:-$HOME/.local/wallpapers}"
STATE_FILE="${STATE_FILE:-$HOME/.config/quickshell/state.json}"
THEME_ROOT="${THEME_ROOT:-$HOME/.config/theme}"

wallpaper_list_images() {
  local dir="${1:-}"
  [[ -d "$dir" ]] || return 0
  find "$dir" -maxdepth 1 -type f \( \
    -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o \
    -iname '*.webp' -o -iname '*.gif' \
  \) | sort
}

wallpaper_theme_dir() {
  printf '%s/%s\n' "$WALLPAPER_ROOT" "${1:?theme required}"
}

wallpaper_list_theme() {
  wallpaper_list_images "$(wallpaper_theme_dir "${1:?theme required}")"
}

wallpaper_list_all() {
  [[ -d "$WALLPAPER_ROOT" ]] || return 0
  find "$WALLPAPER_ROOT" -type f \( \
    -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o \
    -iname '*.webp' -o -iname '*.gif' \
  \) ! -path '*/.git/*' | sort
}

wallpaper_state_get() {
  local path="${1:?}" fallback="${2:-}"
  if [[ ! -f "$STATE_FILE" ]]; then
    printf '%s\n' "$fallback"
    return 0
  fi
  local jq_path=".${path}"
  local val
  val=$(jq -r "${jq_path} // empty" "$STATE_FILE" 2>/dev/null || true)
  if [[ -z "$val" || "$val" == "null" ]]; then
    # legacy flat dotted key
    val=$(jq -r --arg k "$path" '.[$k] // empty' "$STATE_FILE" 2>/dev/null || true)
  fi
  if [[ -z "$val" || "$val" == "null" ]]; then
    printf '%s\n' "$fallback"
  else
    printf '%s\n' "$val"
  fi
}

# Migrate flat keys → nested, optionally set theme.name and/or wallpaper.current
wallpaper_state_update() {
  local theme="${1:-}" current="${2:-}"
  mkdir -p "$(dirname "$STATE_FILE")"
  if [[ ! -f "$STATE_FILE" ]]; then
    jq -n \
      --arg theme "${theme:-tokyonight}" \
      --arg current "${current:-}" \
      '{
        theme: { name: $theme },
        wallpaper: { dynamic: true, current: $current }
      }' >"$STATE_FILE"
    return 0
  fi

  local args=()
  local prog='.'
  prog+=' | if (.theme | type) != "object" then .theme = {} else . end'
  prog+=' | if (.wallpaper | type) != "object" then .wallpaper = {} else . end'
  prog+=' | if .["theme.name"] != null then .theme.name = .["theme.name"] | del(.["theme.name"]) else . end'
  prog+=' | if .["wallpaper.current"] != null then .wallpaper.current = .["wallpaper.current"] | del(.["wallpaper.current"]) else . end'
  prog+=' | if has("wallpaper.index") then del(.["wallpaper.index"]) else . end'

  if [[ -n "$theme" ]]; then
    args+=(--arg theme "$theme")
    prog+=' | .theme.name = $theme'
  fi
  if [[ -n "$current" ]]; then
    args+=(--arg current "$current")
    prog+=' | .wallpaper.current = $current'
  fi

  jq "${args[@]}" "$prog" "$STATE_FILE" >"${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
}

wallpaper_awww_set() {
  local file="${1:?}"
  [[ -f "$file" ]] || return 1
  if ! awww img "$file" \
      --transition-type grow \
      --transition-step 30 \
      --transition-fps 60 \
      --transition-pos 0.5,0.5 2>/dev/null; then
    if ! pgrep -x awww-daemon >/dev/null 2>&1; then
      awww-daemon 2>/dev/null &
      sleep 0.4
    fi
    awww img "$file" \
      --transition-type grow \
      --transition-step 30 \
      --transition-fps 60 \
      --transition-pos 0.5,0.5 2>/dev/null || return 1
  fi
  mkdir -p "$WALLPAPER_ROOT"
  printf '%s\n' "$file" >"$WALLPAPER_ROOT/.current"
  return 0
}

wallpaper_first_of_theme() {
  wallpaper_list_theme "${1:?}" | head -1
}

wallpaper_resolve_for_theme() {
  local theme="${1:?}" current="${2:-}"
  local tdir
  tdir=$(wallpaper_theme_dir "$theme")
  if [[ -n "$current" && -f "$current" && "$current" == "$tdir/"* ]]; then
    printf '%s\n' "$current"
    return 0
  fi
  wallpaper_first_of_theme "$theme"
}

wallpaper_next_in_theme() {
  local theme="${1:?}" current="${2:-}"
  local -a files=()
  mapfile -t files < <(wallpaper_list_theme "$theme")
  ((${#files[@]} > 0)) || return 1
  if [[ -z "$current" ]]; then
    printf '%s\n' "${files[0]}"
    return 0
  fi
  local i next=0
  for i in "${!files[@]}"; do
    if [[ "${files[$i]}" == "$current" ]]; then
      next=$(( (i + 1) % ${#files[@]} ))
      break
    fi
  done
  printf '%s\n' "${files[$next]}"
}

wallpaper_list_themes() {
  [[ -d "$THEME_ROOT/themes" ]] || return 0
  find "$THEME_ROOT/themes" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort
}
