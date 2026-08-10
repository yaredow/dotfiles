#!/usr/bin/env bash
set -euo pipefail

THEME_ROOT="${THEME_ROOT:-$HOME/.config/theme}"
THEME="${1:-}"
if [[ -z "$THEME" ]]; then
  echo "Usage: theme-new.sh <name>" >&2
  echo "Scaffolds a new theme under $THEME_ROOT/themes/<name>/" >&2
  exit 1
fi

THEME_DIR="$THEME_ROOT/themes/$THEME"
if [[ -d "$THEME_DIR" ]]; then
  echo "Theme already exists: $THEME" >&2
  exit 1
fi

mkdir -p "$THEME_DIR"/{wallpapers,}

cat > "$THEME_DIR/colors.json" <<'EOF'
{
  "name": "THEME_NAME",
  "crust": "#",
  "mantle": "#",
  "base": "#",
  "surface0": "#",
  "surface1": "#",
  "surface2": "#",
  "overlay0": "#",
  "overlay1": "#",
  "overlay2": "#",
  "text": "#",
  "subtext0": "#",
  "subtext1": "#",
  "rosewater": "#",
  "flamingo": "#",
  "pink": "#",
  "mauve": "#",
  "red": "#",
  "maroon": "#",
  "peach": "#",
  "yellow": "#",
  "green": "#",
  "teal": "#",
  "sky": "#",
  "sapphire": "#",
  "blue": "#",
  "lavender": "#",
  "fonts": {
    "mono": "CaskaydiaCove Nerd Font",
    "size": 10
  },
  "integrations": {
    "nvim": "",
    "starship": "",
    "herdr": "",
    "opencode": "",
    "rmpc": ""
  }
}
EOF

sed -i "s/THEME_NAME/$THEME/" "$THEME_DIR/colors.json"

echo "Theme scaffolded: $THEME_DIR"
echo "  Edit colors.json to fill in hex values and integration names."
echo "  Add wallpapers to: $THEME_DIR/wallpapers/"
