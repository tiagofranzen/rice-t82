#!/bin/bash
# Windows-style window snapping for Hyprland
# Usage: snap-window.sh left|right|maximize|restore

DIRECTION=$1

# Get focused monitor logical dimensions
read -r MW MH MX MY < <(hyprctl monitors -j | python3 -c "
import sys, json
for m in json.load(sys.stdin):
    if m['focused']:
        lw = int(m['width'] / m['scale'])
        lh = int(m['height'] / m['scale'])
        print(lw, lh, m['x'], m['y'])
        break
")

HALF_W=$((MW / 2))

case "$DIRECTION" in
    left)
        hyprctl dispatch setfloating active
        hyprctl dispatch resizewindowpixel exact "${HALF_W}" "${MH}", active
        hyprctl dispatch movewindowpixel exact "${MX}" "${MY}", active
        ;;
    right)
        hyprctl dispatch setfloating active
        hyprctl dispatch resizewindowpixel exact "${HALF_W}" "${MH}", active
        hyprctl dispatch movewindowpixel exact "$((MX + HALF_W))" "${MY}", active
        ;;
    maximize)
        hyprctl dispatch fullscreen 1
        ;;
    restore)
        FM=$(hyprctl activewindow -j | python3 -c "import sys,json; w=json.load(sys.stdin); print(w.get('fullscreenMode', 'None'))")
        if [ "$FM" != "None" ] && [ "$FM" != "0" ]; then
            hyprctl dispatch fullscreen 1
        else
            # Restore to centered ~60% of screen
            RW=$((MW * 3 / 5))
            RH=$((MH * 3 / 5))
            RX=$((MX + (MW - RW) / 2))
            RY=$((MY + (MH - RH) / 2))
            hyprctl dispatch setfloating active
            hyprctl dispatch resizewindowpixel exact "${RW}" "${RH}", active
            hyprctl dispatch movewindowpixel exact "${RX}" "${RY}", active
        fi
        ;;
esac
