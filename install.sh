#!/usr/bin/env bash
set -euo pipefail
set -E

REPO_URL="${DOTFILES_REPO:-https://github.com/yaredow/dotfiles}"
REPO_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
LOG_FILE="${DOTFILES_LOG:-$HOME/.local/state/dotfiles-install.log}"

TOTAL_STEPS=12
step=0
CHECK_ONLY=0
WARNINGS=()

say() {
  step=$((step + 1))
  printf "\n[\033[1;34m%02d/%02d\033[0m] %s\n" "$step" "$TOTAL_STEPS" "$1"
}

usage() {
  cat <<'EOF'
Usage: install.sh [--check] [--help]

Bootstrap the ydot dotfiles.

Options:
  --check   Run pre-flight checks only (no changes), then exit.
  --help    Show this help.

Environment:
  DOTFILES_REPO   Git URL to clone (default: https://github.com/yaredow/dotfiles)
  DOTFILES_DIR    Where to clone/work (default: $HOME/dotfiles)
  DOTFILES_LOG    Log file path (default: $HOME/.local/state/dotfiles-install.log)

Safe to re-run — a failed run can be recovered by running it again.
EOF
}

on_err() {
  WARNINGS+=("Script aborted at line $1 — see log: $LOG_FILE")
}

on_exit() {
  wait || true
  print_summary
}

print_summary() {
  echo ""
  echo "=============================================="
  if [[ "$CHECK_ONLY" -eq 1 ]]; then
    echo "Pre-flight check complete."
  else
    echo "Install finished."
  fi
  if [[ ${#WARNINGS[@]} -eq 0 ]]; then
    echo "  No warnings."
  else
    echo "  ${#WARNINGS[@]} warning(s):"
    local w
    for w in "${WARNINGS[@]}"; do
      echo "    - $w"
    done
  fi
  echo "  Log: $LOG_FILE"
  echo "=============================================="
}

EXCLUDE_FILE="$REPO_DIR/scripts/stow-exclude.txt"

# Action: report (read-only) or backup (move blocking real files aside).
# Uses `git ls-files` so only files stow will actually deploy are scanned —
# generated/untracked/runtime files (theme.conf, state.json, mpd db, …) are
# never touched.
detect_conflicts() {
  local action="${1:-report}"
  local conflicts=()
  local BACKUP_DIR="$HOME/.local/state/stow-backup-$(date +%Y%m%d-%H%M%S)"
  local name rel target

  while IFS= read -r name; do
    [[ -d "$REPO_DIR/$name" ]] || continue
    if [[ -f "$EXCLUDE_FILE" ]] && grep -vE '^\s*(#|$)' "$EXCLUDE_FILE" | grep -qxF "$name"; then
      continue
    fi
    local path
    while IFS= read -r -d '' path; do
      rel="${path#"$name"/}"
      target="$HOME/$rel"
      # Symlink or absent target = safe (previous stow / fresh install)
      [[ -L "$target" || ! -e "$target" ]] && continue
      # Conflict: stow wants a symlink here but a real file is in the way.
      # (A real *directory* at the target is fine — stow descends into it.)
      [[ -f "$REPO_DIR/$path" || ! -d "$target" ]] || continue
      conflicts+=("$target")
      if [[ "$action" == "backup" ]]; then
        local dst="$BACKUP_DIR/$rel"
        mkdir -p "$(dirname "$dst")"
        cp -a "$target" "$dst"
        rm -rf "$target"
      fi
    done < <(git ls-files -z -- "$name")
  done < <(git ls-files | cut -d/ -f1 | sort -u)

  if [[ ${#conflicts[@]} -gt 0 ]]; then
    printf "  %d existing file(s) block stow:\n" "${#conflicts[@]}"
    for c in "${conflicts[@]}"; do
      printf "    %s\n" "$c"
    done
    if [[ "$action" == "backup" ]]; then
      echo "  Backed up to: $BACKUP_DIR"
      WARNINGS+=("${#conflicts[@]} stow conflicts backed up to $BACKUP_DIR")
    fi
  else
    echo "  none — clean"
  fi
}

preflight() {
  echo "── Pre-flight checks ──"
  local tool
  for tool in git jq stow zsh sddm yay; do
    if command -v "$tool" >/dev/null 2>&1; then
      printf "  [ ok ]  %s\n" "$tool"
    else
      printf "  [warn]  %s missing (installed by this script unless noted)\n" "$tool"
    fi
  done

  local f n
  for f in scripts/pacman.txt scripts/yay.txt; do
    if [[ -s "$REPO_DIR/$f" ]]; then
      n=$(grep -vcE '^\s*(#|$)' "$REPO_DIR/$f")
      printf "  [ ok ]  %-18s %s package(s)\n" "$f" "$n"
    else
      printf "  [fail]  %s missing or empty\n" "$f"
      WARNINGS+=("$f missing or empty")
    fi
  done

  local themes=0 td name nw
  local -a no_wp=()
  for td in "$REPO_DIR/theme/.config/theme/themes"/*/; do
    [[ -d "$td" ]] || continue
    themes=$((themes + 1))
    name=$(basename "$td")
    if [[ -d "$td/wallpapers" ]]; then
      nw=$(find "$td/wallpapers" -maxdepth 1 -type f | wc -l)
      printf "  [ ok ]  theme %-12s %s wallpaper(s)\n" "$name" "$nw"
    else
      no_wp+=("$name")
    fi
  done
  printf "  [ ok ]  %s theme(s) found\n" "$themes"
  if [[ ${#no_wp[@]} -gt 0 ]]; then
    printf "  [warn]  themes without wallpapers: %s\n" "${no_wp[*]}"
  fi

  echo "── Stow conflict scan ──"
  detect_conflicts report
}

# ── CLI parsing ──
for arg in "$@"; do
  case "$arg" in
    --check) CHECK_ONLY=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "install.sh: unknown option '$arg'" >&2; usage >&2; exit 1 ;;
  esac
done

# =============================================================================
# Self-bootstrap: if running via curl | sh, clone the repo first
# =============================================================================
if [[ ! -d "$REPO_DIR/.git" ]]; then
  if ! command -v git &>/dev/null; then
    sudo pacman -S --noconfirm git
  fi
  echo ":: Cloning dotfiles..."
  # Never rm -rf a directory that already contains something — it may be the
  # user's own data. Clone into it only if it is missing or empty.
  if [[ -e "$REPO_DIR" ]] && [[ -n "$(ls -A "$REPO_DIR" 2>/dev/null)" ]]; then
    echo "  ERROR: '$REPO_DIR' exists and is not empty — refusing to delete it." >&2
    echo "  Remove it manually or set DOTFILES_DIR to a fresh path." >&2
    exit 1
  fi
  git clone "$REPO_URL" "$REPO_DIR"
fi

cd "$REPO_DIR"

[[ "$EUID" -eq 0 ]] && { echo "Do not run as root." >&2; exit 1; }

# =============================================================================
# Logging: everything is teed to the log file AND the terminal
# =============================================================================
trap 'on_exit' EXIT
trap 'on_err $LINENO' ERR

preflight

if [[ "$CHECK_ONLY" -eq 1 ]]; then
  echo ""
  echo "--check complete. Nothing was installed."
  exit 0
fi

# Stale pacman lock → hang, kill it
sudo rm -f /var/lib/pacman/db.lck

# =============================================================================
# 1 – Install yay (AUR helper)
# =============================================================================
say "Installing yay (AUR helper)..."
if ! command -v yay &>/dev/null; then
  sudo pacman -S --needed --noconfirm base-devel git
  rm -rf /tmp/yay-build
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

if ! sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"; then
  echo "  batch failed, retrying one-by-one..."
  FAILED=()
  for pkg in "${PACMAN_PKGS[@]}"; do
    pacman -Q "$pkg" &>/dev/null && continue
    sudo pacman -S --noconfirm "$pkg" || FAILED+=("$pkg")
  done
  if [[ ${#FAILED[@]} -gt 0 ]]; then
    WARNINGS+=("${#FAILED[@]} pacman packages failed: ${FAILED[*]}")
  fi
fi

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
  if ! yay -S --needed --noconfirm "${YAY_PKGS[@]}"; then
    echo "  batch failed, retrying one-by-one..."
    for pkg in "${YAY_PKGS[@]}"; do
      yay -Q "$pkg" &>/dev/null && continue
      yay -S --needed --noconfirm "$pkg" || true
    done
  fi
else
  echo "  none to install"
fi

# =============================================================================
# 4 – Stow all config packages
# =============================================================================
say "Stowing dotfiles..."
STOW_PACKAGES=()
for dir in "$REPO_DIR"/*/; do
  name=$(basename "$dir")
  # Match non-comment, non-blank lines in stow-exclude.txt
  if [[ -f "$EXCLUDE_FILE" ]] && grep -vE '^\s*(#|$)' "$EXCLUDE_FILE" | grep -qxF "$name"; then
    continue
  fi
  STOW_PACKAGES+=("$name")
done

if [[ ${#STOW_PACKAGES[@]} -eq 0 ]]; then
  echo "  ERROR: no stow packages found" >&2
  exit 1
fi
echo "  packages: ${STOW_PACKAGES[*]}"

# Move any real files that would block stow out of the way first
detect_conflicts backup
if ! stow --restow --target="$HOME" --dir="$REPO_DIR" "${STOW_PACKAGES[@]}"; then
  WARNINGS+=("stow failed for some packages — see log")
fi

# =============================================================================
# 5 – Bootstrap default state
# =============================================================================
say "Bootstrapping quickshell state..."
mkdir -p "$HOME/.config/quickshell"
if [[ ! -f "$HOME/.config/quickshell/state.json" ]]; then
  cp "$REPO_DIR/quickshell/.config/quickshell/state.default.json" "$HOME/.config/quickshell/state.json"
fi

# =============================================================================
# 6 – Copy default wallpapers (per-theme dirs)
#     BEFORE theme-set so wallpaper.current is resolved during install.
# =============================================================================
say "Copying default wallpapers..."
mkdir -p "$HOME/.local/wallpapers"
for theme_dir in "$REPO_DIR/theme/.config/theme/themes"/*/; do
  [[ -d "$theme_dir" ]] || continue
  name=$(basename "$theme_dir")
  seed="$theme_dir/wallpapers"
  [[ -d "$seed" ]] || continue
  mkdir -p "$HOME/.local/wallpapers/$name"
  cp -n "$seed"/* "$HOME/.local/wallpapers/$name/" 2>/dev/null || true
done
mkdir -p "$HOME/.local/wallpapers/extras"

# =============================================================================
# 7 – Set theme (default from state.default.json, or user's existing choice)
# =============================================================================
say "Setting theme..."
DEFAULT_THEME="tokyonight"
if [[ -f "$REPO_DIR/quickshell/.config/quickshell/state.default.json" ]]; then
  DEFAULT_THEME=$(jq -r '.theme.name // "tokyonight"' "$REPO_DIR/quickshell/.config/quickshell/state.default.json" 2>/dev/null || true)
fi
THEME="$DEFAULT_THEME"
if [[ -f "$HOME/.config/quickshell/state.json" ]]; then
  EXISTING=$(jq -r '.theme.name // empty' "$HOME/.config/quickshell/state.json" 2>/dev/null || true)
  [[ -n "$EXISTING" && "$EXISTING" != "null" ]] && THEME="$EXISTING"
fi
echo "  theme: $THEME"
if ! "$HOME/.local/bin/theme-set.sh" "$THEME"; then
  WARNINGS+=("theme-set.sh failed for theme '$THEME' — see log")
fi

# =============================================================================
# 8 – Generate antidote static plugin file
# =============================================================================
say "Generating antidote plugin file..."
zsh -c 'source /usr/share/zsh-antidote/antidote.zsh && antidote bundle < "$HOME/.zsh_plugins.txt" > "$HOME/.zsh_plugins.zsh"' 2>/dev/null || true

# =============================================================================
# 9 – Enable systemd services
# =============================================================================
say "Enabling systemd services..."
sudo systemctl enable --now NetworkManager.service 2>/dev/null || true
sudo systemctl enable --now bluetooth.service 2>/dev/null || true
sudo systemctl enable --now ufw.service 2>/dev/null || true
sudo systemctl enable sddm 2>/dev/null || true

# =============================================================================
# 10 – Install ydot SDDM theme
#      Wallpapers + state are already in place, so the theme picks up the real
#      colors and current wallpaper. Failure here must not abort the install.
# =============================================================================
say "Installing ydot SDDM theme..."
if ! sudo bash "$REPO_DIR/ydot-sddm/install.sh" "$HOME"; then
  WARNINGS+=("SDDM theme install failed — retry: sudo bash $REPO_DIR/ydot-sddm/install.sh")
fi

# =============================================================================
# 11 – Change default shell to zsh
# =============================================================================
say "Changing default shell to zsh..."
ZSH_PATH="$(command -v zsh || true)"
if [[ -z "$ZSH_PATH" ]]; then
  WARNINGS+=("zsh not found — install 'zsh' and run: sudo usermod -s /usr/bin/zsh $USER")
elif [[ "$(getent passwd "$USER" | cut -d: -f7)" != "$ZSH_PATH" ]]; then
  sudo usermod -s "$ZSH_PATH" "$USER"
  echo "  default shell set to $ZSH_PATH (log out and back in to activate)"
else
  echo "  already zsh"
fi

# =============================================================================
# 12 – Setup tmux TPM
# =============================================================================
say "Installing tmux TPM..."
if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
else
  echo "  already installed"
fi

mkdir -p "$HOME/.local/share"

echo ""
echo "Done! Restart your shell or run: exec zsh"
