# ydot — dotfiles

Arch Linux + Hyprland dotfiles with a centralized theme system. All config deploys via GNU Stow.

## Structure

Each top-level directory is a **stow package** rooted at `~`, unless listed in `scripts/stow-exclude.txt`.

```
stow hypr kitty            # specific packages
stow -D hypr               # remove symlinks
./install.sh               # full bootstrap (auto-discovers packages)
```

### Stow packages vs non-packages

| Kind | Examples | How deployed |
|------|----------|--------------|
| Stow package | `hypr/`, `kitty/`, `nvim/`, `quickshell/`, `theme/`, `bin/`, … | `stow` → `~` |
| Non-package | `scripts/`, `sddm/`, `ydot-sddm/`, `starship/` | helpers / templates only |

`starship/` is **not** stowed — `theme-set.sh` renders `starship.toml` from the theme template into `~/.config/starship.toml`.

Adding a new app config: create `appname/.config/...` (picked up automatically). To keep a top-level dir out of stow, add its name to `scripts/stow-exclude.txt`.

## Theme system

Source of truth: `theme/.config/theme/themes/<name>/colors.json`.

```
theme-set.sh <name>
  ├─ render templates → kitty / hypr / fastfetch / btop / starship / rmpc
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
  <theme>/1.jpg …          # theme-bound set (cycle stays here)
  extras/                  # unthemed (picker "Add")
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
| `~/.config/hypr/theme.lua` | `hypr-colors.lua.tpl` |
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
  "wallpaper": { "current": "/home/.../wallpapers/tokyonight/1.jpg", "dynamic": true }
}
```

No flat `"theme.name"` / `"wallpaper.index"` keys. Scripts migrate legacy flat keys on write.

## Key files

| File | Purpose |
|------|---------|
| `install.sh` | Bootstrap |
| `uninstall.sh` | Remove stow symlinks (--purge to also remove generated files) |
| `scripts/pacman.txt` / `yay.txt` | Packages |
| `scripts/stow-exclude.txt` | Non-stow top-level dirs |
| `bin/.local/bin/theme-set.sh` | Theme orchestrator |
| `bin/.local/bin/wallpaper-*.sh` | Wallpaper |
| `hypr/.config/hypr/hyprland.lua` | Hyprland |
| `quickshell/.../state.default.json` | State template |

## Gotchas

- Edit templates / `colors.json` only — never generated outputs
- Kitty static config is `kitty.conf`; colors in generated `theme.conf`
- Wallpapers are **not** stowed; install seeds per-theme dirs under `~/.local/wallpapers/`
- stow refuses if a real file already exists at the target — remove originals first
- Font overrides from the settings panel live in `state.json` → `typography.monoFont`
