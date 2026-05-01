#!/usr/bin/env bash

# Copy current wallpaper to lock screen background
WALL=$(cat ~/.cache/current_wallpaper 2>/dev/null)
if [ -f "$WALL" ]; then
    cp "$WALL" /tmp/lock_bg.png
else
    # fallback: take a screenshot
    grim /tmp/lock_bg.png 2>/dev/null
fi

pidof hyprlock || hyprlock
