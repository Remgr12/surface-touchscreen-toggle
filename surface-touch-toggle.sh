#!/bin/bash

# Surface Touchscreen Toggle Script for Hyprland
# Usage:
#   ./surface-touch-toggle.sh toggle  - Toggles the touchscreen state
#   ./surface-touch-toggle.sh status  - Outputs JSON for Waybar

# Function to detect the touchscreen device name
get_device_name() {
    # Try to find a device with "IPTS" (common for Surface) or "Touchscreen"
    # We use hyprctl devices to list input devices and grep for likely candidates.
    # We prioritize "IPTS" as it's more specific to Surface.
    
    DEVICE=$(hyprctl devices -j | jq -r '.mice[] | select(.name | contains("IPTS") or contains("Touchscreen") or contains("touchscreen")) | .name' | head -n 1)
    
    # If not found in mice (sometimes touchscreens show up there), check tablets/touch
    if [ -z "$DEVICE" ]; then
         DEVICE=$(hyprctl devices -j | jq -r '.tablets[] | select(.name | contains("IPTS") or contains("Touchscreen") or contains("touchscreen")) | .name' | head -n 1)
    fi
    
    if [ -z "$DEVICE" ]; then
        # Fallback: try to find anything with "touch" in the name from mice/touch/tablets
         DEVICE=$(hyprctl devices -j | jq -r '.touch[] | select(.name | contains("IPTS") or contains("Touchscreen") or contains("touchscreen")) | .name' | head -n 1)
    fi

    echo "$DEVICE"
}

# Function to check current status
get_status() {
    DEVICE=$1
    if [ -z "$DEVICE" ]; then
        echo "unknown"
        return
    fi

    # Check if the device is explicitly disabled in hyprctl config
    # Note: Hyprland doesn't always make it easy to query the *current* enabled state via json if it was toggled via keyword.
    # We might need to track state via a file or rely on hyprctl getoption.
    # However, 'device:enabled' is a per-device config.
    
    # A more robust way for a toggle script is to maintain a state file, 
    # because hyprctl might not reflect dynamic keyword changes in 'getoption' easily for specific devices 
    # without parsing the entire config dump or assuming default is enabled.
    
    # Let's assume default is enabled. If we find a lock file or state file saying disabled, it's disabled.
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
