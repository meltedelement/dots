#!/usr/bin/env bash
# Picks a readable waybar text colour per bar by sampling what is ACTUALLY
# on screen behind each bar (via grim), not a wallpaper file on disk --
# so it stays correct with no wallpaper set, or a fullscreen window behind.
# Re-run by Refresh.sh after waybar restarts.

STYLE="$HOME/.config/waybar/style.css"
PALETTE="$HOME/.config/waybar/wallust/colors-waybar.css"
BAR_H=36   # strip height to average, ~bar height

command -v magick >/dev/null || exit 0
command -v grim   >/dev/null || exit 0

read -r W H < <(hyprctl monitors -j 2>/dev/null |
  awk '/"width":/{w=$2} /"height":/{h=$2} /"focused": true/{print w+0, h+0; exit}')
[ -n "$W" ] && [ "$W" -gt 0 ] 2>/dev/null || { W=1920; H=1080; }

lum() { # mean perceived luminance 0..1 of a hex colour or an image file
  magick "$1" -resize 1x1! -format "%[fx:0.2126*r+0.7152*g+0.0722*b]" info: 2>/dev/null
}

# Sample the live screen. Waybar's own glyphs are a small minority of the
# pixels, so the mean still tracks the backdrop; the threshold below has a
# dead zone so that feedback can never make the choice oscillate.
sample() { # y -> luminance, or empty on failure
  local y=$1 png out
  png=$(mktemp --suffix=.png) || return 1
  if grim -g "0,${y} ${W}x${BAR_H}" "$png" 2>/dev/null; then out=$(lum "$png"); fi
  rm -f "$png"
  printf '%s' "$out"
}

TOP_BG=$(sample 0)
BOT_BG=$(sample $((H - BAR_H)))

# If the screen could not be read, fall back to the wallpaper file if one is
# genuinely being rendered; otherwise assume a dark desktop.
if [ -z "$TOP_BG" ] || [ -z "$BOT_BG" ]; then
  WALL="$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"
  if pgrep -x 'swaybg|swww-daemon|hyprpaper' >/dev/null && [ -f "$WALL" ]; then
    D=$(mktemp --suffix=.png)
    magick "$WALL" -resize "${W}x${H}^" -gravity center -extent "${W}x${H}" "$D" 2>/dev/null
    TOP_BG=${TOP_BG:-$(magick "$D" -crop "${W}x${BAR_H}+0+0" +repage -resize 1x1! \
      -format "%[fx:0.2126*r+0.7152*g+0.0722*b]" info: 2>/dev/null)}
    BOT_BG=${BOT_BG:-$(magick "$D" -crop "${W}x${BAR_H}+0+$((H-BAR_H))" +repage -resize 1x1! \
      -format "%[fx:0.2126*r+0.7152*g+0.0722*b]" info: 2>/dev/null)}
    rm -f "$D"
  fi
  TOP_BG=${TOP_BG:-0.0}; BOT_BG=${BOT_BG:-0.0}
fi

# Lightest / darkest colour in the wallust palette, so the result still
# belongs to the theme rather than being flat white or black.
mapfile -t COLS < <(grep -oE '#[0-9A-Fa-f]{6}' "$PALETTE" 2>/dev/null | sort -u)
LIGHT="#FFFFFF"; DARK="#0A0A0A"; lmax=-1; lmin=2
for c in "${COLS[@]}"; do
  l=$(lum "xc:$c") || continue
  [ -z "$l" ] && continue
  awk -v l="$l" -v m="$lmax" 'BEGIN{exit !(l>m)}' && { lmax=$l; LIGHT=$c; }
  awk -v l="$l" -v m="$lmin" 'BEGIN{exit !(l<m)}' && { lmin=$l; DARK=$c; }
done

contrast() { awk -v a="$1" -v b="$2" 'BEGIN{if(a<b){t=a;a=b;b=t} printf "%.2f",(a+0.05)/(b+0.05)}'; }

# Previous choices, used for hysteresis inside the dead zone.
prev() { grep -oP "(?<=@define-color adaptive-$1 )#[0-9A-Fa-f]{6}" "$(readlink -f "$STYLE")" 2>/dev/null | head -1; }

pick() { # luminance, which-bar -> hex
  local bg=$1 which=$2 want fg fgl p
  if   awk -v b="$bg" 'BEGIN{exit !(b>0.55)}'; then want=dark
  elif awk -v b="$bg" 'BEGIN{exit !(b<0.45)}'; then want=light
  else # dead zone: keep whatever is already applied, if anything
    p=$(prev "$which"); [ -n "$p" ] && { printf '%s' "$p"; return; }
    want=light
  fi
  [ "$want" = dark ] && fg=$DARK || fg=$LIGHT
  fgl=$(lum "xc:$fg")
  if [ -z "$fgl" ] || awk -v r="$(contrast "$bg" "${fgl:-0}")" 'BEGIN{exit !(r<4.5)}'; then
    [ "$want" = dark ] && fg="#0A0A0A" || fg="#FFFFFF"
  fi
  printf '%s' "$fg"
}

TOP_FG=$(pick "$TOP_BG" top)
BOT_FG=$(pick "$BOT_BG" bottom)

# A soft dark shadow under light text reads as depth and helps on a busy
# dark backdrop. The mirror case -- a pale halo around dark text -- just
# looks like a glow, so a light backdrop gets no shadow at all.
shadow() {
  awk -v b="$1" 'BEGIN{ print (b>0.5) ? "none" : "0 1px 2px rgba(0,0,0,0.45)" }'
}
TOP_SH=$(shadow "$TOP_BG"); BOT_SH=$(shadow "$BOT_BG")

[ -f "$STYLE" ] || exit 0
TARGET=$(readlink -f "$STYLE")
TMP=$(mktemp)
sed '/waybar-adaptive-contrast BEGIN/,/waybar-adaptive-contrast END/d' "$TARGET" > "$TMP"
cat >> "$TMP" <<CSS

/* === waybar-adaptive-contrast BEGIN (generated, do not edit) === */
@define-color adaptive-top $TOP_FG;
@define-color adaptive-bottom $BOT_FG;

window#waybar.bar-top { color: @adaptive-top; text-shadow: $TOP_SH; }
window#waybar.bar-bottom { color: @adaptive-bottom; text-shadow: $BOT_SH; }

window#waybar.bar-top #taskbar button:not(.urgent),
window#waybar.bar-top #workspaces button:not(.urgent) { color: alpha(@adaptive-top, 0.7); }
window#waybar.bar-top #taskbar button.active,
window#waybar.bar-top #workspaces button.active { color: @adaptive-top; }

window#waybar.bar-bottom #taskbar button:not(.urgent),
window#waybar.bar-bottom #workspaces button:not(.urgent) { color: alpha(@adaptive-bottom, 0.7); }
window#waybar.bar-bottom #taskbar button.active,
window#waybar.bar-bottom #workspaces button.active { color: @adaptive-bottom; }
/* === waybar-adaptive-contrast END === */
CSS
cat "$TMP" > "$TARGET" && rm -f "$TMP"
echo "top bg=$TOP_BG -> $TOP_FG | bottom bg=$BOT_BG -> $BOT_FG"
