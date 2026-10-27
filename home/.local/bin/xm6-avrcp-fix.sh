#!/usr/bin/env bash
# Watches for the Sony WH-1000XM6 connecting over Bluetooth and re-issues the
# AVRCP profile connect. bluez sometimes loses a startup race between the
# A2DP/HFP/AVRCP profiles ("Operation already in progress" in the bluetooth
# journal), which drops AVRCP absolute-volume sync and leaves audio very
# quiet (headphone volume + PipeWire volume both attenuating independently).
set -u

MAC="58:18:62:35:98:A7"
DEV_PATH="/org/bluez/hci0/dev_58_18_62_35_98_A7"
AVRCP_UUID="0000110c-0000-1000-8000-00805f9b34fb"

echo "$(date -Is) watcher started, listening for ${DEV_PATH}"

dbus-monitor --system \
  "type='signal',interface='org.freedesktop.DBus.Properties',path='${DEV_PATH}',member='PropertiesChanged'" \
  | while IFS= read -r line; do
      case "$line" in
        *'string "Connected"'*) want_bool=1 ;;
        *'boolean true'*)
          if [ "${want_bool:-0}" = 1 ]; then
            want_bool=0
            echo "$(date -Is) saw Connected:yes, waiting 3s then reconnecting AVRCP"
            sleep 3
            if bluetoothctl connect "$MAC" "$AVRCP_UUID" >/tmp/xm6-avrcp-fix-last.log 2>&1; then
              echo "$(date -Is) AVRCP reconnect succeeded"
            else
              echo "$(date -Is) AVRCP reconnect failed, see /tmp/xm6-avrcp-fix-last.log"
            fi
          fi
          ;;
        *'boolean false'*) want_bool=0 ;;
      esac
    done
