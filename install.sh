#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

# =============================================================================
# Preflight
# =============================================================================
[[ "$EUID" -eq 0 ]] && { echo "Do not run as root." >&2; exit 1; }

cd "$REPO_DIR"

# =============================================================================
# Install yay (AUR helper)
# =============================================================================
if ! command -v yay &>/dev/null; then
  echo ":: Installing yay..."
  sudo pacman -S --needed --noconfirm base-devel git
  mkdir -p /tmp/yay-build
  git clone https://aur.archlinux.org/yay.git /tmp/yay-build
  (cd /tmp/yay-build && makepkg -si --noconfirm)
  rm -rf /tmp/yay-build
fi

# =============================================================================
# Install pacman packages
# =============================================================================
echo ":: Installing pacman packages..."
PACMAN_PKGS=()
while IFS= read -r line; do
  line="${line%%#*}"        # strip comments
  line="${line//[[:space:]]/}"
  [[ -z "$line" ]] && continue
  PACMAN_PKGS+=("$line")
done < "$REPO_DIR/scripts/pacman.txt"

sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"

# =============================================================================
# Install AUR packages
# =============================================================================
echo ":: Installing AUR packages..."
YAY_PKGS=()
while IFS= read -r line; do
  line="${line%%#*}"
  line="${line//[[:space:]]/}"
  [[ -z "$line" ]] && continue
  YAY_PKGS+=("$line")
done < "$REPO_DIR/scripts/yay.txt"

if [[ ${#YAY_PKGS[@]} -gt 0 ]]; then
  yay -S --needed --noconfirm "${YAY_PKGS[@]}"
fi

# =============================================================================
# Stow all config packages
# =============================================================================
echo ":: Stowing dotfiles..."
STOW_PACKAGES=()
for dir in "$REPO_DIR"/*/; do
  pkg="$(basename "$dir")"
  [[ "$pkg" == "scripts" ]] && continue
  [[ "$pkg" == "rofi" ]] && continue   # rofi removed; stow package kept as reference
  STOW_PACKAGES+=("$pkg")
done

stow --target="$HOME" --dir="$REPO_DIR" "${STOW_PACKAGES[@]}"

# =============================================================================
# Bootstrap default theme
# =============================================================================
echo ":: Setting default theme..."
"$HOME/.local/bin/theme-set.sh" tokyonight

# =============================================================================
# Enable services
# =============================================================================
echo ":: Enabling systemd services..."
sudo systemctl enable --now NetworkManager.service 2>/dev/null || true
sudo systemctl enable --now bluetooth.service 2>/dev/null || true
sudo systemctl enable --now ufw.service 2>/dev/null || true

# =============================================================================
# Change default shell to zsh
# =============================================================================
if [[ "$SHELL" != "$(which zsh)" ]]; then
  echo ":: Changing default shell to zsh..."
  chsh -s "$(which zsh)"
fi

# =============================================================================
# Setup tmux TPM
# =============================================================================
if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
  echo ":: Installing tmux TPM..."
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

# =============================================================================
# Copy default wallpapers
# =============================================================================
echo ":: Copying default wallpapers..."
mkdir -p "$HOME/.local/wallpapers"
for img in "$REPO_DIR/theme/.config/theme/wallpapers"/*.jpg; do
  [[ -f "$img" ]] && cp -n "$img" "$HOME/.local/wallpapers/"
done

# =============================================================================
# Create common directories
# =============================================================================
mkdir -p "$HOME/.local/share"

echo ""
echo "Done! Restart your shell or run: exec zsh"
