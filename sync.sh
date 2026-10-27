#!/usr/bin/env bash
# Copies the live desktop config into this repo (live -> repo).
# Run it before committing:  ./sync.sh && git add -A && git commit
# restore.sh does the reverse.
set -euo pipefail
REPO="$(cd "$(dirname "$0")" && pwd)"
H="$HOME"

# ~/.config dirs that make up the Hyprland desktop (JaKooLit dots + Theme Studio targets)
CONFIG_DIRS=(hypr waybar rofi kitty ghostty swaync wallust wlogout qt5ct qt6ct Kvantum
             cava btop fastfetch swappy quickshell ags nwg-displays gtk-3.0 wezterm systemd)
CONFIG_FILES=(mimeapps.list)

# Everything under $HOME that is small enough for git, at its path relative to $HOME
HOME_PATHS=(.bashrc .bash_profile .profile .gitconfig
            .local/bin/xm6-avrcp-fix.sh
            .local/share/applications/dev.meltedelement.ThemeStudio.desktop
            .themes .local/share/themes .local/share/fonts
            Pictures/wallpapers)

RSYNC=(rsync -a --delete --exclude='*.pyc' --exclude='__pycache__/')

mkdir -p "$REPO/home/.config"
for d in "${CONFIG_DIRS[@]}"; do
  [[ -e "$H/.config/$d" ]] && "${RSYNC[@]}" "$H/.config/$d/" "$REPO/home/.config/$d/"
done
for f in "${CONFIG_FILES[@]}"; do
  [[ -e "$H/.config/$f" ]] && cp -a "$H/.config/$f" "$REPO/home/.config/$f"
done
for p in "${HOME_PATHS[@]}"; do
  [[ -e "$H/$p" ]] || continue
  mkdir -p "$REPO/home/$(dirname "$p")"
  if [[ -d "$H/$p" ]]; then "${RSYNC[@]}" "$H/$p/" "$REPO/home/$p/"; else cp -a "$H/$p" "$REPO/home/$p"; fi
done

# Wallpapers that themes point at outside ~/Pictures/wallpapers (~/wallpapers is 1GB, so only these)
mkdir -p "$REPO/home/wallpapers"
grep -h '^WALLPAPER=' "$H"/.config/hypr/themes/*.theme | cut -d'"' -f2 | grep "^$H/wallpapers/" | sort -u |
  while read -r w; do [[ -f "$w" ]] && cp -a "$w" "$REPO/home/wallpapers/"; done

# What's installed, so a rebuild knows what to put back
mkdir -p "$REPO/manifest"
dnf repoquery --userinstalled --qf '%{name}\n' 2>/dev/null | sort -u > "$REPO/manifest/dnf-userinstalled.txt"
dnf repolist --enabled 2>/dev/null > "$REPO/manifest/dnf-repos.txt"
flatpak list --app --columns=application 2>/dev/null > "$REPO/manifest/flatpaks.txt" || true
python3 -m pip list --user --format=freeze 2>/dev/null > "$REPO/manifest/pip-user.txt" || true
ls "$H/.icons" > "$REPO/manifest/icon-themes.txt"   # not committed (660MB), reinstall by name
gsettings list-recursively org.gnome.desktop.interface > "$REPO/manifest/gsettings-interface.txt" 2>/dev/null || true
echo "synced into $REPO"
