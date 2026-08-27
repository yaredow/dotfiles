#!/bin/bash
# Deploy themed osc.conf for mpv's modern.lua OSC and append the current system font.

src="$HOME/.local/state/omarchy/current/theme/osc.conf"
dst="$HOME/.config/mpv/script-opts/osc.conf"

[[ -f "$src" ]] || exit 0

mkdir -p "$(dirname "$dst")"
cp "$src" "$dst"

font=$(omarchy-font-current 2>/dev/null)
[[ -n "$font" ]] && echo "font=$font" >> "$dst"
