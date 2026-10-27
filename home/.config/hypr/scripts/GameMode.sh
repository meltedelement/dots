#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Focus Mode. Animations/blur/gaps off + notifications silenced (swaync DND).
# No popup, and waybar is only reloaded if its adaptive colours actually change.

SCRIPTSDIR="$HOME/.config/hypr/scripts"
STYLE=$(readlink -f "$HOME/.config/waybar/style.css")

# Re-sample the backdrop for waybar's adaptive colours; only signal waybar
# (which makes it visibly reload) when the generated CSS really changed.
recolour_waybar() {
    local before after
    before=$(md5sum "$STYLE" 2>/dev/null)
    "${SCRIPTSDIR}/WaybarAdaptiveColors.sh" >/dev/null 2>&1
    after=$(md5sum "$STYLE" 2>/dev/null)
    [ "$before" != "$after" ] && killall -SIGUSR2 waybar 2>/dev/null
}

FOCUSMODE_OFF=$(hyprctl getoption animations:enabled | awk 'NR==1{print $2}')
if [ "$FOCUSMODE_OFF" = 1 ] ; then
    hyprctl --batch "\
        keyword animations:enabled 0;\
        keyword decoration:shadow:enabled 0;\
        keyword decoration:blur:enabled 0;\
        keyword general:gaps_in 0;\
        keyword general:gaps_out 0;\
        keyword general:border_size 1;\
        keyword decoration:rounding 0"

    hyprctl keyword "windowrule opacity 1 override 1 override 1 override, ^(.*)$"
    swaync-client --dnd-on >/dev/null 2>&1
    swww kill
    sleep 0.3
    recolour_waybar
else
    # hyprctl reload restores every keyword changed above from the config
    hyprctl reload >/dev/null
    swaync-client --dnd-off >/dev/null 2>&1
    pgrep -x swww-daemon >/dev/null || { swww-daemon --format xrgb & sleep 0.3; }
    swww img "$HOME/.config/rofi/.current_wallpaper"
    sleep 0.5
    recolour_waybar
fi
