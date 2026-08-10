<p align="center">
   <img src="screenshots/ydot.svg" alt="ydot" width="120" />
</p>

<h1 align="center">ydot</h1>

<p align="center">
  Personal Arch Linux + Hyprland dotfiles with a centralized theme system. All configs deploy via GNU Stow and are driven from a unified QML shell.
</p>

<p align="center">
  <img alt="License" src="https://img.shields.io/badge/license-MIT-blue.svg" />
  <img alt="Stars" src="https://img.shields.io/github/stars/yaredow/dotfiles?style=social" />
</p>

## Screenshots

<table>
  <tr>
    <td><img src="screenshots/desktop.png" alt="Desktop" width="400" /></td>
    <td><img src="screenshots/terminal.png" alt="Terminal" width="400" /></td>
  </tr>
  <tr>
    <td><img src="screenshots/launcher.png" alt="Launcher" width="400" /></td>
    <td><img src="screenshots/menu.png" alt="Menu" width="400" /></td>
  </tr>
  <tr>
    <td><img src="screenshots/lock.png" alt="Lock screen" width="400" /></td>
    <td><img src="screenshots/sddm-theme.png" alt="SDDM" width="400" /></td>
  </tr>
</table>

## Highlights

- **Centralized theming** — pick a theme and every app restyles: Hyprland, kitty, fastfetch, btop, starship, nvim, rmpc, herdr and more
- **Unified QML shell** — bar, launcher, settings panel, clipboard history, keybinds reference, lock screen and power menu in one place
- **Searchable settings** — change theme or font with live search
- **Clipboard history** — `SUPER + V` opens a searchable cliphist manager
- **Wallpaper cycling** — `SUPER + W` rotates theme-bound wallpapers

> [!NOTE]
> **Environment**
>
> - **OS:** Arch Linux
> - **Window Manager:** Hyprland
> - **Terminal:** Kitty
> - **Shell:** Zsh + Starship
> - **Editor:** Neovim / Zed
> - **Multiplexer:** herdr

## Installation

### Fresh install

```sh
curl -fsSL https://raw.githubusercontent.com/yaredow/dotfiles/main/install.sh | sh
```

For a private fork, set `DOTFILES_REPO`:

```sh
DOTFILES_REPO="https://token@github.com/youruser/dotfiles.git" curl -fsSL ... | sh
```

### Existing setup

```sh
git clone https://github.com/yaredow/dotfiles ~/dotfiles
cd ~/dotfiles
./install.sh
```

### Options

```sh
./install.sh --check   # pre-flight checks only (tools, package lists, themes,
                       # and stow conflicts) — makes no changes
./install.sh --help
```

- **Safe to re-run** — a failed run can be recovered by running `install.sh` again.
- Real files that would block GNU Stow are backed up to `~/.local/state/stow-backup-*/` instead of failing the install.
- Everything is logged to `~/.local/state/dotfiles-install.log` (override with `DOTFILES_LOG`).

### Manual stow

```sh
stow shell terminal wm  # deploy by topic
stow -D shell           # remove a package
```

## Theming

Source of truth: `theme/.config/theme/themes/<name>/colors.json` — themes: **tokyonight**, **catppuccin**, **gruvbox**.

```
theme-set.sh <name>
  ├─ render templates → kitty / hypr / fastfetch / btop / starship / herdr / opencode / rmpc
  ├─ copy colors.json → ~/.config/quickshell/state/colors.json
  ├─ nvim integration → ~/.config/nvim/lua/theme.lua
  ├─ wallpaper for that theme
  └─ state.json: theme.name + wallpaper.current
```

Edit templates under `theme/.config/theme/templates/*.tpl` and `colors.json` — never the generated outputs.

## Structure

```
.
├── shell/          # zsh, atuin (stow → ~)
├── terminal/       # kitty, fastfetch, btop, herdr
├── wm/             # hyprland, quickshell (bar, launcher, lock screen)
├── dev/            # nvim, git, zed, yazi
├── media/          # mpd, mpv, rmpc, youtube-tui
├── desktop/        # gtk-3/4, qt6ct, electron flags
├── bin/            # ~/.local/bin scripts (theme-set, wallpaper)
├── theme/          # colors.json + templates
├── scripts/        # NOT stowed — pacman.txt, yay.txt, stow-exclude.txt
├── ydot-sddm/      # NOT stowed — SDDM theme
├── screenshots/    # README gallery
└── install.sh      # Bootstrap (auto-discovers stow packages)
```

Top-level dirs are **topic-based stow packages** grouped by domain, except those in
`scripts/stow-exclude.txt` (`scripts/`, `sddm/`, `screenshots/`, `ydot-sddm/`).
`starship.toml` is rendered by `theme-set.sh` directly into `~/.config/starship.toml`.

Wallpapers live in `~/.local/wallpapers/<theme>/` (cycled with `SUPER + W`). Repo seeds are under
`theme/.../themes/<name>/wallpapers/`.

## Keybinds

`ALT` is the primary modifier; `ALT + SHIFT` handles window control.

| Keys                                        | Action                    |
|---------------------------------------------|---------------------------|
| `ALT + T`                                   | Terminal                  |
| `ALT + F`                                   | File manager              |
| `ALT + B`                                   | Browser                   |
| `ALT + M`                                   | Music                     |
| `ALT + SPACE`                               | App launcher              |
| `SUPER + ALT + SPACE`                        | App menu                  |
| `ALT + W`                                   | Settings panel            |
| `ALT + Q`                                   | Close window              |
| `ALT + h/j/k/l`                             | Move focus                |
| `ALT + SHIFT + h/j/k/l`                     | Move window               |
| `ALT + SHIFT + T`                           | Toggle float              |
| `ALT + SHIFT + F`                           | Toggle fullscreen         |
| `ALT + 1-9,0`                               | Switch workspace          |
| `ALT + SHIFT + 1-9,0`                       | Move window to workspace  |
| `SUPER + V`                                 | Clipboard history         |
| `SUPER + S`                                 | Screenshot                |
| `SUPER + R`                                 | Toggle screen recording   |
| `SUPER + W`                                 | Cycle wallpaper           |
| `SUPER + L`                                 | Lock screen               |
| `SUPER + /`                                 | Keybinds reference        |
| `XF86PowerOff`                              | Power menu                |
| `XF86AudioRaise/Lower/Mute`                 | Volume OSD                |
| `XF86MonBrightnessUp/Down`                  | Brightness OSD            |
| `XF86AudioNext/Prev/Play/Pause`             | Media control             |
