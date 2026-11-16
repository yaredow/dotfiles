# ydot — dotfiles

Arch Linux + Niri dotfiles with a centralized theme system. All config deploys via GNU Stow.

## Structure

Top-level directories are **per-tool stow packages** rooted at `~`. Pick and stow just what you need.

```
stow niri noctalia alacritty fish   # deploy by tool
stow -D kitty                       # remove a package
./install.sh                        # full bootstrap (auto-discovers packages)
```

### Packages (27 per-tool stow packages)

Each tool is its own root-level stow package rooted at `~`.

<details>
<summary>Package list</summary>

| Package | Contents | Domain |
|---------|----------|--------|
| `niri/` | config.kdl | window manager |
| `noctalia/` | config.toml, archlinux.svg | desktop shell |
| `alacritty/` | alacritty.toml | terminal |
| `kitty/` | kitty.conf (colors in generated theme.conf) | terminal |
| `fish/` | config.fish, aliases, functions | shell experience |
| `atuin/` | atuin config + themes | shell history |
| `bat/` | config + tokyonight theme | TUI tools |
| `fastfetch/` | logo.txt (config.jsonc is generated) | TUI tools |
| `btop/` | btop.conf (theme.theme is generated) | TUI tools |
| `fontconfig/` | fonts.conf | system fonts |
| `git/` | git config (delta, aliases) | dev tools |
| `gtk/` | gtk-3.0 + gtk-4.0 settings.ini, gtk.css | desktop environment |
| `herdr/` | config.toml | dev tools / multiplexer |
| `mpd/` | mpd.conf, playlists | media |
| `mpv/` | mpv.conf, input.conf, scripts, fonts (osc.conf is generated) | media |
| `rmpc/` | config.ron (theme.ron is generated) | media |
| `youtube-tui/` | *.yml keybinds/pages/cmds | media |
| `electron/` | electron-flags.conf | desktop environment |
| `postman/` | postman.desktop entry | dev tools |
| `qbittorrent/` | tokyo-night.qbtheme | media |
| `spotify/` | spotify-flags.conf, spotify-launcher.conf, .desktop entry | media apps |
| `telegram/` | TokyoNight.tdesktop-theme | media apps |
| `yazi/` | keymap.toml | file manager |
| `zed/` | settings.json, keymap.json | editor |
| `zen/` | policies.json, user.js, vimium theme | browser |
| `bin/` | ~/.local/bin scripts (theme-set, wallpaper, recording) | system scripts |
| `theme/` | colors.json + templates | system theme |

</details>

Non-stow (listed in `scripts/stow-exclude.txt`): `scripts/`, `screenshots/`, `greetd/`, `keyd/`, `quickshell/`, `sddm/`, `ydot-sddm/`.

Adding a new app: create a root package `<tool>/<relative path from ~>/...`. To keep a top-level dir out of stow, add its name to `scripts/stow-exclude.txt`. `starship.toml` is rendered by `theme-set.sh` directly into `~/.config/starship.toml` (no stow package).

## Theme system

Source of truth: `theme/.config/theme/themes/<name>/colors.json`.

```
theme-set.sh <name>
  ├─ render templates → alacritty / kitty / fastfetch / btop / starship / herdr / rmpc
  ├─ copy colors.json → ~/.config/quickshell/state/colors.json
  ├─ nvim via integrations.nvim → ~/.config/nvim/lua/theme.lua
  ├─ wallpaper via awww (see below)
  └─ state.json: theme.name + wallpaper.current (nested only)
```

Templates: `theme/.config/theme/templates/*.tpl` with `{{key}}` / `{{key_strip}}` and `{{starship_palette}}`.

Per-theme integrations in `colors.json`:

```json
"integrations": { "nvim": "tokyonight-night", "starship": "tokyonight_night", "herdr": "tokyo-night", "opencode": "tokyonight", "rmpc": "tokyonight" }
```

### Wallpapers

```
~/.local/wallpapers/
  <theme>/default-wallpaper.jpg …   # theme-bound set (cycle stays here)
  extras/                           # unthemed (picker "Add")
```

Repo seeds: `theme/.../themes/<name>/wallpapers/` (copied on install with `cp -n`).

| Script | Role |
|--------|------|
| `wallpaper-lib.sh` | shared helpers (source only) |
| `wallpaper-set.sh [path]` | awww + `wallpaper.current` |
| `wallpaper-cycle.sh` | next image in current theme dir (SUPER+W) |
| `theme-set.sh <name>` | full theme + wallpaper for that theme |

### Generated files (do not edit/commit)

| Path | Source |
|------|--------|
| `~/.config/kitty/theme.conf` | `kitty.conf.tpl` |
| `~/.config/fastfetch/config.jsonc` | `fastfetch.jsonc.tpl` |
| `~/.config/btop/themes/theme.theme` | `btop.theme.tpl` |
| `~/.config/starship.toml` | `starship.toml.tpl` |
| `~/.config/nvim/lua/theme.lua` | `integrations.nvim` |
| `~/.config/herdr/config.toml` | `herdr.toml.tpl` (theme name + `[theme.custom]` palette) |
| `~/.config/opencode/tui.json` | `opencode-tui.json.tpl` (`integrations.opencode`) |
| `~/.config/rmpc/themes/theme.ron` | `rmpc.ron.tpl` (full theme) |
| `~/.config/theme/current` | symlink → active theme |
| `~/.config/quickshell/state.json` | machine-local (from `state.default.json`) |
| `~/.config/quickshell/state/colors.json` | copy of active `colors.json` |

### State shape (nested only)

```json
{
  "theme": { "name": "tokyonight" },
  "wallpaper": { "current": "/home/.../wallpapers/tokyonight/default-wallpaper.jpg", "dynamic": true }
}
```

No flat `"theme.name"` / `"wallpaper.index"` keys. Scripts migrate legacy flat keys on write.

## Key files

| File | Purpose |
|------|---------|
| `install.sh` | Bootstrap |
| `scripts/pacman.txt` / `yay.txt` | Packages |
| `scripts/stow-exclude.txt` | Non-stow top-level dirs |
| `bin/.local/bin/theme-set.sh` | Theme orchestrator |
| `bin/.local/bin/wallpaper-*.sh` | Wallpaper |
| `niri/.config/niri/config.kdl` | Niri compositor config |
| `noctalia/.config/noctalia/config.toml` | Noctalia shell config |
| `quickshell/.config/quickshell/state.default.json` | State template |

## Gotchas

- Edit templates / `colors.json` only — never generated outputs
- Kitty static config is `kitty.conf`; colors in generated `theme.conf`
- Wallpapers are **not** stowed; install seeds per-theme dirs under `~/.local/wallpapers/`
- stow refuses if a real file already exists at the target — remove originals first
- Font overrides from the settings panel live in `state.json` → `typography.monoFont`
- `qt6ct.conf` is copied by install.sh as a real file (not stowed) — qt6ct rewrites it at runtime
