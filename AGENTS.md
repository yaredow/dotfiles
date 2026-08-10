# ydot — dotfiles

Arch Linux + Hyprland dotfiles with a centralized theme system. All config deploys via GNU Stow.

## Structure

Top-level directories are **topic-based stow packages** grouped by domain, rooted at `~`.

```
stow shell terminal        # deploy by topic
stow -D shell              # remove symlinks
./install.sh               # full bootstrap (auto-discovers packages)
```

### Packages (8 stow + 3 non-stow)

| Package | Contents | Domain |
|---------|----------|--------|
| `shell/` | zsh (.zshrc, .zshenv, aliases), atuin | shell experience |
| `terminal/` | kitty, fastfetch, btop, herdr | terminal + TUI tools |
| `wm/` | hyprland, quickshell | window manager + shell |
| `dev/` | nvim, git, zed, yazi, opencode | development tools |
| `media/` | mpd, mpv, rmpc, youtube-tui | media |
| `desktop/` | gtk-3/4, electron | desktop environment |
| `bin/` | theme-set.sh, wallpaper scripts | user scripts (~/.local/bin) |
| `theme/` | colors.json, templates | theme system |
| *`scripts/`* | pacman.txt, yay.txt, qt6ct.conf, helpers | **not stowed** |
| *`sddm/`* / *`ydot-sddm/`* | SDDM greeter theme | **not stowed** |
| *`screenshots/`* | documentation images | **not stowed** |

Adding a new app: put it in the closest topic dir with `app/.config/...`. To keep a top-level dir out of stow, add its name to `scripts/stow-exclude.txt`. `starship.toml` is rendered by `theme-set.sh` directly into `~/.config/starship.toml` (no stow package).

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
| `scripts/pacman.txt` / `yay.txt` | Packages |
| `scripts/stow-exclude.txt` | Non-stow top-level dirs |
| `bin/.local/bin/theme-set.sh` | Theme orchestrator |
| `bin/.local/bin/wallpaper-*.sh` | Wallpaper |
| `wm/.config/hypr/hyprland.lua` | Hyprland |
| `wm/.config/quickshell/state.default.json` | State template |

## Gotchas

- Edit templates / `colors.json` only — never generated outputs
- Kitty static config is `kitty.conf`; colors in generated `theme.conf`
- Wallpapers are **not** stowed; install seeds per-theme dirs under `~/.local/wallpapers/`
- stow refuses if a real file already exists at the target — remove originals first
- Font overrides from the settings panel live in `state.json` → `typography.monoFont`
- `qt6ct.conf` is copied by install.sh as a real file (not stowed) — qt6ct rewrites it at runtime
