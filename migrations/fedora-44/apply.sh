#!/usr/bin/env bash
# Run AFTER the Fedora 44 upgrade (Hyprland 0.56), from a TTY or the new session.
# Backs up ~/.config/hypr and ~/.config/quickshell, then copies the 0.56-ready files over them.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
stamp=$(date +%Y%m%d-%H%M%S)
cp -a "$HOME/.config/hypr" "$HOME/.config/hypr.bak-pre-f44-$stamp"
[[ -d "$HOME/.config/quickshell" ]] && cp -a "$HOME/.config/quickshell" "$HOME/.config/quickshell.bak-pre-f44-$stamp"
rsync -rltE --omit-dir-times --itemize-changes "$HERE/home/" "$HOME/"
echo "backups: ~/.config/{hypr,quickshell}.bak-pre-f44-$stamp"
if command -v Hyprland >/dev/null; then Hyprland --verify-config 2>&1 | tail -n 3; fi
