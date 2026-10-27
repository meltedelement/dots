# dotfiles

Fedora + Hyprland desktop, based on [JaKooLit/Hyprland-Dots](https://github.com/JaKooLit/Hyprland-Dots) (v2.3.20),
with my own changes in `hypr/UserConfigs`, `hypr/UserScripts` and `hypr/themes`.

`home/` mirrors `$HOME`. These are copies, not symlinks: edit the live files, then run `./sync.sh` to pull them in.

| Script | Does |
| --- | --- |
| `./sync.sh` | live → repo (configs, themes, fonts, wallpapers that themes use, package manifest) |
| `./restore.sh --dry-run` | show what would change in `$HOME` |
| `./restore.sh` | repo → live; never deletes extra files in `$HOME` |

## Not in this repo
- **Theme Studio** (Super+T): separate repo, `~/Projects/themeSwitcher`. After cloning, run its `./install.sh`,
  then check that Super+T in `hypr/configs/Keybinds.conf` still points at `~/.local/bin/theme-studio`.
- `~/.icons` (660MB): Bibata-Modern-Ice cursors and Flat-Remix icons. The names are in `manifest/icon-themes.txt`.
- `~/wallpapers` (1.1GB JaKooLit wallpaper bank). Only the wallpapers a theme references are copied to `home/wallpapers/`.

## Rebuild on a fresh Fedora
1. Enable the repos in `manifest/dnf-repos.txt` (Hyprland comes from COPR `sdegler/hyprland`).
2. `sudo dnf install $(cat manifest/dnf-userinstalled.txt)`, and add the flatpaks in `manifest/flatpaks.txt`.
3. `./restore.sh`, then `systemctl --user enable --now xm6-avrcp-fix.service`.
4. AGS v1 lives in `/usr/local` (built by the JaKooLit installer) and has to be rebuilt.
