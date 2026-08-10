#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

usage() {
  cat <<'EOF'
Usage: uninstall.sh [--purge] [--help]

Remove ydot dotfiles symlinks.

Options:
  --purge   Also remove generated theme/config files (kitty/theme.conf,
            hypr/theme.lua, btop/theme.theme, fastfetch/config.jsonc,
            starship.toml, nvim/lua/theme.lua, mpv/osc.conf,
            herdr/config.toml, opencode/tui.json, rmpc/themes/theme.ron,
            quickshell/state/colors.json, theme/current symlink)
  --help    Show this help.

Environment:
  DOTFILES_DIR  Path to the dotfiles repo (default: ~/dotfiles)
EOF
}

PURGE=0
for arg in "$@"; do
  case "$arg" in
    --purge) PURGE=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "uninstall.sh: unknown option '$arg'" >&2; usage >&2; exit 1 ;;
  esac
done

[[ -d "$REPO_DIR/.git" ]] || { echo "Dotfiles repo not found at $REPO_DIR" >&2; exit 1; }
cd "$REPO_DIR"

EXCLUDE_FILE="$REPO_DIR/scripts/stow-exclude.txt"

echo "Unstowing dotfiles..."
for dir in "$REPO_DIR"/*/; do
  name=$(basename "$dir")
  if [[ -f "$EXCLUDE_FILE" ]] && grep -vE '^\s*(#|$)' "$EXCLUDE_FILE" | grep -qxF "$name"; then
    continue
  fi
  echo "  -$name"
  stow -D --target="$HOME" --dir="$REPO_DIR" "$name" 2>/dev/null || true
done

if [[ "$PURGE" -eq 1 ]]; then
  echo "Purging generated config files..."
  rm -f "$HOME/.config/kitty/theme.conf"
  rm -f "$HOME/.config/hypr/theme.lua"
  rm -f "$HOME/.config/btop/themes/theme.theme"
  rm -f "$HOME/.config/fastfetch/config.jsonc"
  rm -f "$HOME/.config/starship.toml"
  rm -f "$HOME/.config/nvim/lua/theme.lua"
  rm -f "$HOME/.config/mpv/script-opts/osc.conf"
  rm -f "$HOME/.config/herdr/config.toml"
  rm -f "$HOME/.config/opencode/tui.json"
  rm -f "$HOME/.config/rmpc/themes/theme.ron"
  rm -f "$HOME/.config/quickshell/state/colors.json"
  rm -f "$HOME/.config/theme/current"
  rm -f "$HOME/.zsh_plugins.zsh"
  echo "  done"
  echo ""
  echo "  Note: state.json was kept in ~/.config/quickshell/ (machine-local)"
  echo "  Remove it manually if desired: rm ~/.config/quickshell/state.json"
fi

echo "Done."
