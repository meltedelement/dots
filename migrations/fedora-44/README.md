# Fedora 42 → 44 migration (Hyprland 0.51.1 → 0.56.2)

Run `./apply.sh` once you're on F44. Every change here passed `Hyprland --verify-config`
under 0.56.2 (`config ok`), checked in a Fedora 44 container on 2026-10-27.

| File | Change |
| --- | --- |
| `hypr/hyprland.conf` | sources `configs/WindowRules.conf` (0.53+ syntax) instead of `WindowRules-pre-53.conf` |
| `hypr/UserConfigs/WindowRules.conf` | converted to `match:` syntax with `convert_rules.py` (same rules, same order) |
| `hypr/configs/Keybinds.conf` | Super+Shift+I: `togglesplit` → `layoutmsg, togglesplit` |
| `hypr/scripts/ChangeLayout.sh` | same fix for Super+O after switching layouts |
| `hypr/configs/SystemSettings.conf`, `UserConfigs/UserSettings.conf` | commented out `dwindle:pseudotile` and `misc:vfr` (both removed) |
| `hypr/UserConfigs/Startup_Apps.conf` | `ags` → `qs -c overview` (AGS v1 can't load on F44's gjs 1.88) |
| `quickshell/` | JaKooLit's overview config, so Super+A works through `OverviewToggle.sh` |

Needs `sudo dnf install quickshell` (in the Fedora 44 repos).
Doesn't touch Theme Studio or `hypr/themes`.
