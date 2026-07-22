# Arch + Hyprland Dotfiles

## Overview
Personal Arch Linux + Hyprland setup built around a centralized theme system. All configs deploy via GNU Stow and are managed from a unified QML settings panel.

## Structure
```
.
├── hypr/           # Hyprland config (Lua)
├── kitty/          # Terminal
├── quickshell/     # Shell/bar/panels (QML)
├── theme/          # Central theme system
├── tmux/           # Terminal multiplexer
├── nvim/           # Editor
├── bin/            # Scripts
├── scripts/        # Bootstrap helpers
└── install.sh      # Fresh-install bootstrap
```

## Features
- **Centralized theme switching** — 3 themes (tokyonight, catppuccin, rosepine) with per-theme wallpapers and fonts
- **Unified QML shell** — Bar, settings panel, clipboard history, keybinds overlay, launcher, power menu
- **Searchable settings panel** — Change theme or font with live search
- **Clipboard history** — `SUPER + V` opens searchable clipboard manager via cliphist
- **Keybinds overlay** — `SUPER + /` shows categorized, searchable keybind reference
- **Wallpaper cycling** — `SUPER + W` cycles wallpapers with smooth transitions
- **Fully reproducible** — `git clone` + `install.sh` builds the entire environment

## Prerequisites
- Fresh Arch Linux install
- Hyprland

## Usage

### Fresh install
```sh
curl -fsSL https://raw.githubusercontent.com/yourusername/dotfiles/main/install.sh | sh
```

### Existing setup
```sh
git clone https://github.com/yourusername/dotfiles ~/dotfiles
cd ~/dotfiles
./install.sh
```

## Keybinds
| Keys | Action |
|------|--------|
| `ALT + T` | Terminal |
| `ALT + Space` | App launcher |
| `ALT + W` | Settings panel |
| `SUPER + V` | Clipboard history |
| `SUPER + /` | Keybinds reference |
| `SUPER + W` | Cycle wallpaper |
| `SUPER + S` | Screenshot |
| `SUPER + L` | Lock screen |

## Current State
Actively developed — stable for daily use but iterating on UX.
