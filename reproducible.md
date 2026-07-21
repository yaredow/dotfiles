# Reproducible Dotfiles — Implementation Plan

**Goal:** `git clone` + `./scripts/bootstrap.sh` = fully working Arch + Hyprland system with one desktop theme applied everywhere.

---

## 1. Stow Package Inventory

Every config file lives in `~/dotfiles` and is deployed via GNU Stow.

### Current stow packages (already working)

| Package | Path | Symlinked to |
|---------|------|-------------|
| `hypr/` | `.config/hypr/` | `~/.config/hypr` |
| `kitty/` | `.config/kitty/` | `~/.config/kitty` |
| `quickshell/` | `.config/quickshell/` | `~/.config/quickshell` |
| `tmux/` | `.tmux.conf` | `~/.tmux.conf` |
| `starship/` | `.config/starship.toml` | `~/.config/starship.toml` |
| `nvim/` | `.config/nvim/` | `~/.config/nvim` |
| `rofi/` | `.config/rofi/` | `~/.config/rofi` |
| `mpv/` | `.config/mpv/` | `~/.config/mpv` |
| `mpd/` | `.config/mpd/` | `~/.config/mpd` |
| `rmpc/` | `.config/rmpc/` | `~/.config/rmpc` |
| `zed/` | `.config/zed/` | `~/.config/zed` |
| `zsh/` | `.zshrc`, `.zshenv`, `.zsh/` | `~/.zshrc`, `~/.zshenv`, `~/.zsh` |

### New stow packages (to create)

| Package | Path | Symlinked to |
|---------|------|-------------|
| `theme/` | `.config/theme/` | `~/.config/theme` |
| `bin/` | `.local/bin/` | `~/.local/bin` |

### To remove (not needed)

```
alacritty/   → rm -rf
foot/        → rm -rf
ghostty/     → rm -rf
waybar/      → rm -rf
walker/      → rm -rf
```

### To keep (not themed, but functional)

```
yazi/          file manager — keymap only, no theme
youtube-tui/   terminal YouTube — uses terminal colors
```

---

## 2. Theme System

Architecture described in detail below, extracted from plan + conversations.

### Directory layout

```
dotfiles/theme/.config/theme/
├── templates/
│   ├── kitty.conf.tpl
│   ├── hypr-colors.lua.tpl
│   └── tmux.conf.tpl
└── themes/
    ├── tokyonight/colors.json
    ├── catppuccin/colors.json
    └── rosepine/colors.json
```

### The canonical palette (20 Catppuccin keys)

```json
{
  "name": "tokyonight",
  "crust": "#16161e",
  "mantle": "#16161e",
  "base": "#1a1b26",
  "surface0": "#292e42",
  "surface1": "#3b4261",
  "surface2": "#414868",
  "overlay0": "#565f89",
  "overlay1": "#737aa2",
  "overlay2": "#9aa5ce",
  "text": "#c0caf5",
  "subtext0": "#a9b1d6",
  "subtext1": "#c0caf5",
  "rosewater": "#c0caf5",
  "flamingo": "#ff9e64",
  "pink": "#f7768e",
  "mauve": "#bb9af7",
  "red": "#f7768e",
  "maroon": "#f7768e",
  "peach": "#ff9e64",
  "yellow": "#e0af68",
  "green": "#9ece6a",
  "teal": "#7dcfff",
  "sky": "#7dcfff",
  "sapphire": "#7aa2f7",
  "blue": "#7aa2f7",
  "lavender": "#bb9af7"
}
```

One `colors.json` per theme — this is the single source of truth.

### Template format

Simple `{{key}}` substitution. No conditionals, no filters.

```
# kitty.conf.tpl
foreground              {{text}}
background              {{base}}
selection_foreground    {{base}}
selection_background    {{rosewater}}
cursor                  {{rosewater}}
active_border_color     {{lavender}}
inactive_border_color   {{overlay0}}

color0  {{surface1}}
color8  {{surface2}}
color1  {{red}}
color9  {{red}}
color2  {{green}}
color10 {{green}}
color3  {{yellow}}
color11 {{yellow}}
color4  {{blue}}
color12 {{blue}}
color5  {{mauve}}
color13 {{mauve}}
color6  {{teal}}
color14 {{teal}}
color7  {{subtext1}}
color15 {{subtext0}}
```

```
# hypr-colors.lua.tpl
return {
    active1 = "rgba({{sapphire}}ee)",
    active2 = "rgba({{mauve}}ee)",
    inactive = "rgba({{overlay0}}aa)",
}
```

```
# tmux.conf.tpl
BG_COLOR="#{{base_strip}}"
ACTIVE_COLOR="#{{blue_strip}}"
INACTIVE_COLOR="#{{overlay0_strip}}"
TEXT_COLOR="#{{text_strip}}"
ACCENT_COLOR="#{{mauve_strip}}"
```

### `theme-set.sh` (in `dotfiles/bin/.local/bin/`)

```bash
#!/usr/bin/env bash
set -euo pipefail

THEME_ROOT="$HOME/.config/theme"
THEME="${1:?Usage: theme-set.sh <tokyonight|catppuccin|rosepine>}"
THEME_DIR="$THEME_ROOT/themes/$THEME"

[[ -d "$THEME_DIR" ]] || { echo "Theme not found: $THEME"; exit 1; }

# 1. Read colors.json
COLORS=$(cat "$THEME_DIR/colors.json")

# 2. Quickshell — copy to watched path, instant live reload
mkdir -p "$HOME/.config/quickshell/state"
cp "$THEME_DIR/colors.json" "$HOME/.config/quickshell/state/colors.json"

# 3. Render and apply templates
render() {
  local tpl="$THEME_ROOT/templates/$1.tpl"
  local dst="$2"
  mkdir -p "$(dirname "$dst")"
  sed_cmd=""
  for key in crust mantle base surface0 surface1 surface2 overlay0 overlay1 overlay2 \
             text subtext0 subtext1 rosewater flamingo pink mauve red maroon peach \
             yellow green teal sky sapphire blue lavender; do
    val=$(echo "$COLORS" | jq -r ".$key")
    sed_cmd+=" -e 's/{{$key}}/$val/g'"
    # strip variant (no #)
    sed_cmd+=" -e 's/{{${key}_strip}}/${val#\#}/g'"
  done
  eval "sed $sed_cmd" "$tpl" > "$dst"
}

render kitty.conf        "$HOME/.config/kitty/theme.conf"
render hypr-colors.lua   "$HOME/.config/hypr/theme.lua"
render tmux.conf         "$HOME/.config/tmux/theme.conf"

# 4. Starship — swap palette line
PALETTE_MAP='{"tokyonight":"tokyonight_night","catppuccin":"catppuccin_mocha","rosepine":"rose_pine"}'
PALETTE=$(echo "$PALETTE_MAP" | jq -r ".$THEME")
sed -i "s/^palette = .*/palette = \"$PALETTE\"/" "$HOME/.config/starship.toml"

# 5. Reload hooks
hyprctl reload >/dev/null 2>&1 || true
pkill -SIGUSR1 kitty 2>/dev/null || true
tmux source-file ~/.tmux.conf 2>/dev/null || true

echo "Theme set to: $THEME"
```

### Quickshell integration

**ThemeService.qml** — replace the current 387-line version with:

```qml
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string colorsPath: Quickshell.env("HOME") + "/.config/quickshell/state/colors.json"

    property var palette: ({})
    property string currentThemeName: palette.name ?? "tokyonight"
    property var availableThemes: ["tokyonight", "catppuccin", "rosepine"]

    function color(key, fallback) { return palette[key] ?? fallback }

    FileView {
        path: root.colorsPath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.palette = JSON.parse(text())
    }
}
```

**Config.qml** — update color keys from old schema to Catppuccin schema:

| Old key | New key |
|---------|---------|
| `background` | `base` |
| `surface0` | `surface0` |
| `surface1` | `surface1` |
| `surface2` | `surface2` |
| `surface3` | `overlay1` |
| `text` | `text` |
| `textReverse` | `base` |
| `subtext` | `subtext0` |
| `subtextReverse` | `overlay0` |
| `accent` | `sapphire` |
| `success` | `green` |
| `warning` | `yellow` |
| `error` | `red` |
| `muted` | `overlay0` |
| `greyBlue` | `surface1` |
| `blueDark` | `crust` |
| `sepColor` | `overlay1` |

### Hyprland integration

Add to top of `hyprland.lua`:
```lua
local theme = require("theme")
```

Replace hardcoded `active_border`/`inactive_border`:
```lua
col = {
    active_border = { colors = { theme.active1, theme.active2 }, angle = 45 },
    inactive_border = theme.inactive,
}
```

### Kitty integration

Remove inline color block from `kitty.conf`, add:
```conf
include ./theme.conf
```

### Tmux integration

Remove `BG_COLOR=...` through `ACCENT_COLOR=...` lines, add:
```conf
source-file -q ~/.config/tmux/theme.conf
```

### Starship integration

Ensure `starship.toml` has a dedicated `palette = "tokyonight_night"` line (already exists). Add Rosé Pine palette.

### Neovim integration

In `ui.lua`, replace `vim.cmd.colorscheme 'tokyonight-night'` with:

```lua
local theme_link = vim.fn.resolve(vim.fn.expand("~/.config/theme/current"))
local theme_name = vim.fn.fnamemodify(theme_link, ":t")
local map = {
  tokyonight = "tokyonight-night",
  catppuccin = "catppuccin-mocha",
  rosepine = "rose-pine",
}
vim.cmd.colorscheme(map[theme_name] or "tokyonight-night")
```

### Hyprland keybind (theme switcher)

```lua
hl.bind(mainMod .. "+SHIFT+T", hl.dsp.exec_cmd(
    "theme=$(ls ~/.config/theme/themes | rofi -dmenu -p 'Theme') && theme-set.sh \"$theme\""
))
```

---

## 3. Bootstrap Script

`dotfiles/scripts/bootstrap.sh` — run once on a fresh Arch install.

```bash
#!/usr/bin/env bash
set -euo pipefail

# 1. Install yay (AUR helper) if not present
# 2. Install pacman packages (from scripts/pacman.txt)
# 3. Install AUR packages (from scripts/yay.txt)
# 4. Stow all packages
# 5. Run theme-set.sh tokyonight (first-time theme apply)
# 6. Enable systemd services
# 7. Create ~/Pictures/Screenshots
# 8. Final instructions (chsh to zsh, reboot, etc.)
```

Replace `install-apps.sh` with `bootstrap.sh` that does the full flow.

### Stow command

```bash
cd ~/dotfiles
for pkg in hypr kitty quickshell tmux starship nvim rofi mpv mpd rmpc zed zsh theme bin; do
  stow "$pkg"
done
```

---

## 4. Package Lists

Keep the existing `pacman.txt` and `yay.txt` format. Update:

**Add to pacman.txt:**
- `stow` (currently missing from the list!)
- `quickshell` (is it pacman or AUR?)
- `jq` — already there ✓

**Remove from pacman.txt:**
- `waybar` — already commented out ✓
- Packages for removed apps

**Remove from yay.txt:**
- `ags-hyprpanel-git` (replaced by quickshell)
- `juno-ocean-gtk-theme-git` (not using GTK apps)
- `bibata-cursor-theme` (up to you)

---

## 5. State Management

| File | Tracked in git? | Managed by |
|------|----------------|------------|
| `dotfiles/theme/.config/theme/` | ✅ Yes | stow |
| `dotfiles/quickshell/.config/quickshell/shell.qml` | ✅ Yes | stow |
| `dotfiles/hypr/.config/hypr/hyprland.lua` | ✅ Yes | stow |
| `~/.config/quickshell/state/colors.json` | ❌ No | `theme-set.sh` writes at runtime |
| `~/.config/quickshell/state.json` | ❌ No (gitignored) | ThemeService writes at runtime |
| `~/.config/theme/current` | ❌ No (symlink) | `theme-set.sh` creates at runtime |
| `~/.config/kitty/theme.conf` | ❌ No (generated) | `theme-set.sh` renders + copies |
| `~/.config/hypr/theme.lua` | ❌ No (generated) | `theme-set.sh` renders + copies |
| `~/.config/tmux/theme.conf` | ❌ No (generated) | `theme-set.sh` renders + copies |
| `~/.config/kitty/kitty.conf` | ✅ Yes | stow (via symlink) |
| `~/.tmux.conf` | ✅ Yes | stow (via symlink) |

**`.gitignore` additions:**
```
# Runtime generated files
theme/**/current
quickshell/.config/quickshell/state/
```

---

## 6. Legacy Cleanup

Files/dirs to delete:
```
alacritty/
foot/
ghostty/
waybar/
walker/
scripts/install-apps.sh   → replaced by bootstrap.sh
theme.md                   → replaced by this doc
```

---

## 7. FZF

FZF color flags in `~/.tmux.conf` scripts need to reference a single sourced file. Add `~/.config/fzf/theme.sh` with color vars, sourced by scripts.

---

## 8. Implementation Order

1. **Scaffold** — create `theme/` and `bin/` stow packages, write all `colors.json` files, write `.tpl` templates
2. **Write `theme-set.sh`** — test it manually to confirm all apps re-theme
3. **Simplify `ThemeService.qml`** → FileView watch, update `Config.qml` color keys
4. **Wire `hyprland.lua`** — `require("theme")`, live test with `hyprctl reload`
5. **Wire `kitty.conf`** — `include ./theme.conf`, test with `pkill -SIGUSR1 kitty`
6. **Wire `.tmux.conf`** — `source-file`, test with `tmux source-file`
7. **Wire `starship.toml`** — add Rosé Pine palette, test `sed` swap
8. **Wire `ui.lua`** — neovim startup read, test with fresh nvim
9. **Write `bootstrap.sh`** — full fresh-install flow
10. **Hyprland keybind** — SUPER+SHIFT+T → rofi → theme-set.sh
11. **Remove legacy stow packages** — alacritty, ghostty, foot, waybar, walker
