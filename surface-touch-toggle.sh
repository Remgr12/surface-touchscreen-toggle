#!/bin/bash

get_device_name() {
    DEVICE=$(hyprctl devices -j | jq -r '.mice[] | select(.name | contains("IPTS") or contains("Touchscreen") or contains("touchscreen")) | .name' | head -n 1)
    
    if [ -z "$DEVICE" ]; then
         DEVICE=$(hyprctl devices -j | jq -r '.tablets[] | select(.name | contains("IPTS") or contains("Touchscreen") or contains("touchscreen")) | .name' | head -n 1)
    fi
    
    if [ -z "$DEVICE" ]; then
         DEVICE=$(hyprctl devices -j | jq -r '.touch[] | select(.name | contains("IPTS") or contains("Touchscreen") or contains("touchscreen")) | .name' | head -n 1)
    fi

    echo "$DEVICE"
}

get_status() {
    DEVICE=$1
    if [ -z "$DEVICE" ]; then
        echo "unknown"
        return
    fi

    STATE_FILE="/tmp/surface_touch_disabled"
    
    if [ -f "$STATE_FILE" ]; then
        echo "disabled"
    else
        echo "enabled"
    fi
}

DEVICE_NAME=$(get_device_name)

if [ -z "$DEVICE_NAME" ]; then
    echo "Error: Could not detect Surface touchscreen device." >&2
    if [ "$1" == "status" ]; then
        echo '{"text": "ERR", "class": "error", "tooltip": "Touchscreen not found"}'
    fi
    exit 1
fi

case "$1" in
    toggle)
        CURRENT_STATUS=$(get_status "$DEVICE_NAME")
        if [ "$CURRENT_STATUS" == "enabled" ]; then
            hyprctl keyword "device[$DEVICE_NAME]:enabled" false
            touch "/tmp/surface_touch_disabled"
            # Send signal to waybar to update if needed (pkill -SIGRTMIN+8 waybar) - optional
        else
            hyprctl keyword "device[$DEVICE_NAME]:enabled" true
            rm -f "/tmp/surface_touch_disabled"
        fi
        ;;
    status)
        CURRENT_STATUS=$(get_status "$DEVICE_NAME")
        if [ "$CURRENT_STATUS" == "enabled" ]; then
            echo '{"text": "Touch: ON", "class": "enabled", "tooltip": "Touchscreen is enabled"}'
        else
            echo '{"text": "Touch: OFF", "class": "disabled", "tooltip": "Touchscreen is disabled"}'
        fi
        ;;
    *)
        echo "Usage: $0 {toggle|status}"
        exit 1
        ;;
esac
