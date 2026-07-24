#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${DOTFILES_REPO:-https://github.com/yaredow/dotfiles}"
REPO_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

TOTAL_STEPS=11
step=0

say() {
  step=$((step + 1))
  printf "\n[\033[1;34m%02d/%02d\033[0m] %s\n" "$step" "$TOTAL_STEPS" "$1"
}

# =============================================================================
# Self-bootstrap: if running via curl | sh, clone the repo first
# =============================================================================
if [[ ! -d "$REPO_DIR/.git" ]]; then
  if ! command -v git &>/dev/null; then
    sudo pacman -S --noconfirm git
  fi
  echo ":: Cloning dotfiles..."
  git clone "$REPO_URL" "$REPO_DIR"
fi

cd "$REPO_DIR"

[[ "$EUID" -eq 0 ]] && { echo "Do not run as root." >&2; exit 1; }

# =============================================================================
# 1 – Install yay (AUR helper)
# =============================================================================
say "Installing yay (AUR helper)..."
if ! command -v yay &>/dev/null; then
  sudo pacman -S --needed --noconfirm base-devel git
  mkdir -p /tmp/yay-build
  git clone https://aur.archlinux.org/yay.git /tmp/yay-build
  (cd /tmp/yay-build && makepkg -si --noconfirm)
  rm -rf /tmp/yay-build
else
  echo "  already installed"
fi

# =============================================================================
# 2 – Install pacman packages
# =============================================================================
say "Installing pacman packages..."
PACMAN_PKGS=()
while IFS= read -r line; do
  line="${line%%#*}"
  line="${line//[[:space:]]/}"
  [[ -z "$line" ]] && continue
  PACMAN_PKGS+=("$line")
done < "$REPO_DIR/scripts/pacman.txt"

sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"

# =============================================================================
# 3 – Install AUR packages
# =============================================================================
say "Installing AUR packages..."
YAY_PKGS=()
while IFS= read -r line; do
  line="${line%%#*}"
  line="${line//[[:space:]]/}"
  [[ -z "$line" ]] && continue
  YAY_PKGS+=("$line")
done < "$REPO_DIR/scripts/yay.txt"

if [[ ${#YAY_PKGS[@]} -gt 0 ]]; then
  yay -S --needed --noconfirm "${YAY_PKGS[@]}"
else
  echo "  none to install"
fi

# =============================================================================
# 4 – Stow all config packages
# =============================================================================
say "Stowing dotfiles..."
STOW_PACKAGES=(bin hypr kitty mpd mpv nvim qt6ct quickshell rmpc starship theme tmux yazi youtube-tui zed zsh)

stow --target="$HOME" --dir="$REPO_DIR" "${STOW_PACKAGES[@]}"

# =============================================================================
# 5 – Bootstrap default state
# =============================================================================
say "Bootstrapping quickshell state..."
mkdir -p "$HOME/.config/quickshell"
if [[ ! -f "$HOME/.config/quickshell/state.json" ]]; then
  cp "$REPO_DIR/quickshell/.config/quickshell/state.default.json" "$HOME/.config/quickshell/state.json"
fi

# =============================================================================
# 6 – Bootstrap default theme
# =============================================================================
say "Setting default theme..."
"$HOME/.local/bin/theme-set.sh" tokyonight

# =============================================================================
# 7 – Generate antidote static plugin file
# =============================================================================
say "Generating antidote plugin file..."
zsh -c 'source /usr/share/zsh-antidote/antidote.zsh && antidote bundle < "$HOME/.zsh_plugins.txt" > "$HOME/.zsh_plugins.zsh"' 2>/dev/null || true

# =============================================================================
# 8 – Enable systemd services
# =============================================================================
say "Enabling systemd services..."
sudo systemctl enable --now NetworkManager.service 2>/dev/null || true
sudo systemctl enable --now bluetooth.service 2>/dev/null || true
sudo systemctl enable --now ufw.service 2>/dev/null || true

# =============================================================================
# 9 – Change default shell to zsh
# =============================================================================
say "Changing default shell to zsh..."
if [[ "$SHELL" != "$(which zsh)" ]]; then
  chsh -s "$(which zsh)"
else
  echo "  already zsh"
fi

# =============================================================================
# 10 – Setup tmux TPM
# =============================================================================
say "Installing tmux TPM..."
if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
else
  echo "  already installed"
fi

# =============================================================================
# 11 – Copy default wallpapers
# =============================================================================
say "Copying default wallpapers..."
mkdir -p "$HOME/.local/wallpapers"
for img in "$REPO_DIR/theme/.config/theme/wallpapers"/*.jpg; do
  [[ -f "$img" ]] && cp -n "$img" "$HOME/.local/wallpapers/"
done

mkdir -p "$HOME/.local/share"

echo ""
echo "Done! Restart your shell or run: exec zsh"
