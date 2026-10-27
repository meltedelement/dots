#!/usr/bin/env bash
# Waybar module: show/toggle Bluetooth headphones between
# A2DP (high-quality music) and HSP/HFP (headset mode with mic).
# Usage: BtHeadsetMode.sh [status|toggle]

card=$(pactl list cards short | awk '$2 ~ /^bluez_card\./ {print $2; exit}')

if [[ -z $card ]]; then
  echo '{"text":"","class":"disconnected"}'
  exit 0
fi

profile=$(pactl list cards | awk -v c="$card" '
  $1=="Name:" {in_card = ($2==c)}
  in_card && /Active Profile:/ {print $3; exit}')
name=$(pactl list cards | awk -v c="$card" '
  $1=="Name:" {in_card = ($2==c)}
  in_card && /device.description =/ {sub(/.*= "/,""); sub(/"$/,""); print; exit}')

case "$1" in
  toggle)
    if [[ $profile == headset-head-unit* ]]; then
      if ! pactl set-card-profile "$card" a2dp-sink 2>/dev/null; then
        # A2DP link sometimes fails on reconnect, leaving only HFP; bring it up
        mac=${card#bluez_card.}; mac=${mac//_/:}
        bluetoothctl connect "$mac" 0000110b-0000-1000-8000-00805f9b34fb >/dev/null
        sleep 2
        pactl set-card-profile "$card" a2dp-sink
      fi
    else
      pactl set-card-profile "$card" headset-head-unit 2>/dev/null \
        || pactl set-card-profile "$card" headset-head-unit-cvsd
    fi
    pkill -RTMIN+9 waybar
    ;;
  *)
    if [[ $profile == headset-head-unit* ]]; then
      printf '{"text":"󰋎 ","class":"headset","tooltip":"%s: headset mode (mic on, low quality)\\nClick: switch to hi-fi"}\n' "$name"
    else
      printf '{"text":"󰋋 ","class":"hifi","tooltip":"%s: hi-fi mode (%s, no mic)\\nClick: switch to headset/mic mode"}\n' "$name" "$profile"
    fi
    ;;
esac
