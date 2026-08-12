#!/usr/bin/env bash
# =============================================================================
# omarchy-extras.sh — install everything in the ydot package lists that Omarchy
# does NOT already provide.
#
# Reads scripts/pacman.txt + scripts/yay.txt (the same files install.sh uses),
# subtracts the packages Omarchy bundles by default (base + hardware lists from
# basecamp/omarchy, branch 'quattro'), and installs only the remainder.
#
# Idempotent and safe to re-run. Nothing here touches dotfiles/config — it only
# installs packages.
#
# Usage:
#   ./scripts/omarchy-extras.sh            # install the diff (pacman + yay)
#   ./scripts/omarchy-extras.sh --pacman   # pacman/repo packages only
#   ./scripts/omarchy-extras.sh --aur      # AUR packages only
#   ./scripts/omarchy-extras.sh --check    # print the diff, install nothing
# =============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACMAN_FILE="$REPO_DIR/scripts/pacman.txt"
YAY_FILE="$REPO_DIR/scripts/yay.txt"

# --- toggle flags -----------------------------------------------------------
DO_PACMAN=1
DO_AUR=1
CHECK_ONLY=0

# =============================================================================
# Omarchy bundled packages (basecamp/omarchy, branch 'quattro')
#   install/omarchy-base.packages   → OMARCHY_BASE
#   install/omarchy-other.packages  → OMARCHY_OTHER
# Anything in these lists is assumed present on a fresh Omarchy install.
# =============================================================================
OMARCHY_BASE=(
    'aether'
    'alsa-utils'
    'asdcontrol'
    'avahi'
    'bash-completion'
    'bat'
    'bluez'
    'bluez-tools'
    'bluez-utils'
    'bolt'
    'brightnessctl'
    'btop'
    'chromium'
    'clang'
    'cliamp'
    'cups'
    'cups-browsed'
    'cups-filters'
    'cups-pdf'
    'ddcutil'
    'docker'
    'docker-buildx'
    'docker-compose'
    'dosfstools'
    'dotnet-runtime'
    'dua-cli'
    'evince'
    'exfatprogs'
    'expac'
    'eza'
    'fakeroot'
    'fastfetch'
    'fcitx5'
    'fcitx5-gtk'
    'fcitx5-qt'
    'fd'
    'ffmpegthumbnailer'
    'fontconfig'
    'foot'
    'fzf'
    'git'
    'gnome-keyring'
    'gnome-themes-extra'
    'grim'
    'gpu-screen-recorder'
    'gum'
    'gvfs-mtp'
    'gvfs-nfs'
    'gvfs-smb'
    'herdr'
    'hyprland'
    'hyprland-guiutils'
    'hyprland-preview-share-picker'
    'hyprpicker'
    'hyprsunset'
    'imagemagick'
    'imv'
    'inetutils'
    'inotify-tools'
    'inxi'
    'networkmanager'
    'jq'
    'kdenlive'
    'kernel-modules-hook'
    'lazydocker'
    'lazygit'
    'less'
    'libsecret'
    'libvips'
    'libyaml'
    'libreoffice-fresh'
    'llvm'
    'localsend'
    'lua51'
    'luarocks'
    'man-db'
    'mariadb-libs'
    'mise'
    'moonlight-qt'
    'mpv'
    'mpv-mpris'
    'nautilus'
    'nautilus-python'
    'gnome-disk-utility'
    'noto-fonts'
    'noto-fonts-cjk'
    'noto-fonts-emoji'
    'nss-mdns'
    'nvim'
    'obs-studio'
    'obsidian'
    'omacalc'
    'omacut'
    'omawrite'
    'omarchy-nvim'
    'pacman-contrib'
    'pamixer'
    'pinta'
    'plocate'
    'plymouth'
    'postgresql-libs'
    'power-profiles-daemon'
    'python-gobject'
    'python-poetry-core'
    'ttfx'
    'qemu-user-static-binfmt'
    'qrencode'
    'quickshell-git'
    'ripgrep'
    'ruby'
    'tensaku'
    'sddm'
    'slurp'
    'socat'
    'starship'
    'sushi'
    'system-config-printer'
    'tesseract'
    'tesseract-data-eng'
    'tldr'
    'tree-sitter-cli'
    'tmux'
    'tobi-try'
    'ttf-ia-writer'
    'ttf-jetbrains-mono-nerd-basic'
    'tzupdate'
    'udiskie'
    'ufw'
    'ufw-docker'
    'unzip'
    'usage'
    'uwsm'
    'whois'
    'wireless-regdb'
    'wireplumber'
    'wl-clipboard'
    'wtype'
    'woff2-font-awesome'
    'xdg-desktop-portal-gtk'
    'xdg-desktop-portal-hyprland'
    'xdg-terminal-exec'
    'xournalpp'
    'yaru-icon-theme'
    'yay'
    'yt-dlp'
    'zbar'
    'zoxide'
)

OMARCHY_OTHER=(
    'autoconf-archive'
    'asusctl'
    'base'
    'base-devel'
    'broadcom-wl'
    'btrfs-progs'
    'dkms'
    'egl-wayland'
    'gst-plugin-pipewire'
    'gtk4-layer-shell'
    'libpulse'
    'intel-ipu7-camera'
    'intel-lpmd'
    'intel-media-driver'
    'libva-intel-driver'
    'libva-nvidia-driver'
    'limine'
    'limine-mkinitcpio-hook'
    'limine-snapper-sync'
    'linux'
    'linux-firmware'
    'linux-headers'
    'linux-ptl'
    'linux-ptl-headers'
    'macbook12-spi-driver-dkms'
    'nvidia-580xx-dkms'
    'nvidia-dkms'
    'nvidia-open-dkms'
    'nvidia-580xx-utils'
    'nvidia-utils'
    'lib32-nvidia-580xx-utils'
    'lib32-nvidia-utils'
    'pipewire'
    'pipewire-alsa'
    'pipewire-jack'
    'pipewire-pulse'
    'qt6-wayland'
    'snapper'
    'sof-firmware'
    'thermald'
    'webp-pixbuf-loader'
    'yay-debug'
    'tuxedo-drivers-nocompatcheck-dkms'
    'yt6801-dkms'
    'zram-generator'
    'libvpl'
    'vpl-gpu-rt'
    'vulkan-intel'
    'vulkan-radeon'
    'vulkan-asahi'
    'linux-firmware-marvell'
    'dell-xps-touchpad-haptics'
    'lsp-plugins-lv2'
    'apple-bcm-firmware'
    'apple-t2-audio-config'
    'linux-t2'
    'linux-t2-headers'
    't2fanrd'
    'qmk-hid'
)

# =============================================================================
# AUR package name resolutions.
#   - A package name in the "provided by omarchy" list is NOT installed (the
#     same app is already on the system under another package name).
#   - PROVIDED_BY maps those provided names back to which ydot package they
#     cover, so script output stays readable.
#   - RENAME maps AUR names that have changed upstream to their current names.
# =============================================================================
PROVIDED_BY=(
    # ydot pkg  → omarchy package that already provides it
    'herdr-bin:herdr'
    'localsend-bin:localsend'
    'neovim:nvim + omarchy-nvim'
    'quickshell:quickshell-git'
)

RENAME=(
    'nvm:nvm-git'
    'proton-vpn-gtk-app:proton-vpn-qt-app'
)

# --- helpers ----------------------------------------------------------------
say() { printf '\n[\033[1;34m%s\033[0m] %s\n' "$COUNT" "$1"; }

usage() {
  cat <<'EOF'
Usage: omarchy-extras.sh [--pacman] [--aur] [--check] [--help]

Install ydot packages that Omarchy does not already provide.

Options:
  --pacman   Only install official-repo (pacman) packages
  --aur      Only install AUR packages
  --check    Print what would be installed, make no changes
  --help     Show this help

Reads scripts/pacman.txt and scripts/yay.txt, subtracts the packages bundled
by Omarchy (basecamp/omarchy, branch 'quattro'), then installs the rest.

Safe to re-run. Only installs packages — never touches config or dotfiles.
EOF
}

# Parse a package list file: strip comments + blank lines.
read_pkg_file() {
  local file="$1"
  [[ -s "$file" ]] || { echo "ERROR: '$file' missing or empty" >&2; exit 1; }
  local line
  while IFS= read -r line; do
    line="${line%%#*}"
    line="${line//[[:space:]]/}"
    [[ -z "$line" ]] && continue
    printf '%s\n' "$line"
  done < "$file"
}

in_omarchy() {
  local p="$1" x
  for x in "${OMARCHY_BASE[@]}" "${OMARCHY_OTHER[@]}"; do
    [[ "$x" == "$p" ]] && return 0
  done
  return 1
}

provided_by() {
  local p="$1" entry
  for entry in "${PROVIDED_BY[@]}"; do
    [[ "${entry%%:*}" == "$p" ]] && { echo "${entry#*:}"; return 0; }
  done
  return 1
}

aur_rename() {
  local p="$1" entry want="$2"
  for entry in "${RENAME[@]}"; do
    [[ "${entry%%:*}" == "$p" ]] && { eval "$want=${entry#*:}"; return 0; }
  done
  eval "$want=$p"
}

# Diff pacman.txt against omarchy. Emits lines "KEEP <pkg>" or "DROP <pkg> → why".
diff_pacman() {
  local p
  while IFS= read -r p; do
    if in_omarchy "$p"; then
      printf 'DROP %s (bundled with omarchy)\n' "$p"
    elif provided_by "$p" >/dev/null; then
      printf 'DROP %s (already provided by %s)\n' "$p" "$(provided_by "$p")"
    else
      printf 'KEEP %s\n' "$p"
    fi
  done < <(read_pkg_file "$PACMAN_FILE")
}

diff_yay() {
  local p renamed
  while IFS= read -r p; do
    if in_omarchy "$p"; then
      printf 'DROP %s (bundled with omarchy)\n' "$p"
    elif provided_by "$p" >/dev/null; then
      printf 'DROP %s (already provided by %s)\n' "$p" "$(provided_by "$p")"
    else
      aur_rename "$p" renamed
      printf 'KEEP %s\n' "$renamed"        # renamed name is the one to install
    fi
  done < <(read_pkg_file "$YAY_FILE")
}

# --- CLI --------------------------------------------------------------------
for arg in "$@"; do
  case "$arg" in
    --pacman) DO_AUR=0 ;;
    --aur)    DO_PACMAN=0 ;;
    --check)  CHECK_ONLY=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "omarchy-extras.sh: unknown option '$arg'" >&2; usage >&2; exit 1 ;;
  esac
done

[[ "$EUID" -eq 0 ]] && { echo "Do not run as root." >&2; exit 1; }

# =============================================================================
echo "== Diff: ydot packages not provided by Omarchy =="
COUNT=0
PACMAN_KEEP=()
if [[ "$DO_PACMAN" -eq 1 ]]; then
  echo "-- pacman (official repos) --"
  while IFS= read -r line; do
    COUNT=$((COUNT + 1))
    case "$line" in
      DROP*) echo "  [$COUNT]-- ${line#DROP }" ;;
      KEEP*) p="${line#KEEP }"; PACMAN_KEEP+=("$p"); echo "  [+ $COUNT] $p" ;;
    esac
  done < <(diff_pacman)
fi

YAY_KEEP=()
if [[ "$DO_AUR" -eq 1 ]]; then
  echo "-- AUR --"
  while IFS= read -r line; do
    COUNT=$((COUNT + 1))
    case "$line" in
      DROP*) echo "  [$COUNT]-- ${line#DROP }" ;;
      KEEP*) p="${line#KEEP }"; YAY_KEEP+=("$p"); echo "  [+ $COUNT] $p" ;;
    esac
  done < <(diff_yay)
fi

echo ""
echo "Result: ${#PACMAN_KEEP[@]} pacman + ${#YAY_KEEP[@]} aur package(s) to install."

if [[ "$CHECK_ONLY" -eq 1 ]]; then
  echo "--check complete. Nothing installed."
  exit 0
fi

[[ ${#PACMAN_KEEP[@]} -eq 0 && ${#YAY_KEEP[@]} -eq 0 ]] && { echo "Nothing to do."; exit 0; }

FAILED=()
if [[ ${#PACMAN_KEEP[@]} -gt 0 ]]; then
  say "Installing pacman packages (${#PACMAN_KEEP[@]})..."
  if ! sudo pacman -S --needed --noconfirm "${PACMAN_KEEP[@]}"; then
    echo "  batch failed, retrying one-by-one..."
    FAILED=()
    for pkg in "${PACMAN_KEEP[@]}"; do
      pacman -Q "$pkg" &>/dev/null && continue
      sudo pacman -S --noconfirm "$pkg" || FAILED+=("$pkg")
    done
    [[ ${#FAILED[@]} -gt 0 ]] && echo "  FAILED: ${FAILED[*]}" >&2
  fi
fi

if [[ ${#YAY_KEEP[@]} -gt 0 ]]; then
  say "Installing AUR packages (${#YAY_KEEP[@]})..."
  if ! command -v yay &>/dev/null; then
    echo "  ERROR: yay not found (Omarchy ships it — install it first)" >&2
    exit 1
  fi
  if ! yay -S --needed --noconfirm "${YAY_KEEP[@]}"; then
    echo "  batch failed, retrying one-by-one..."
    FAILED=()
    for pkg in "${YAY_KEEP[@]}"; do
      yay -Q "$pkg" &>/dev/null && continue
      yay -S --needed --noconfirm "$pkg" || true
    done
  fi
fi

echo ""
echo "Done. ${#PACMAN_KEEP[@]} pacman + ${#YAY_KEEP[@]} aur packages installed."