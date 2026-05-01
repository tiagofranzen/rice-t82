#!/usr/bin/env bash
WALLPAPER="$1"
if [ -z "$WALLPAPER" ]; then
    WALLPAPER=$(swww query 2>/dev/null | awk -F'image: ' '{print $2}' | head -n 1)
fi
if [ -z "$WALLPAPER" ]; then
    WALLPAPER="$HOME/Pictures/wallpapers/mountain-forest.jpg"
fi
matugen image "$WALLPAPER" --source-color-index 0 --mode dark
HYPRLAND_INSTANCE_SIGNATURE=$(ls /run/user/1000/hypr/ 2>/dev/null | head -1)
if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    HYPRLAND_INSTANCE_SIGNATURE=$HYPRLAND_INSTANCE_SIGNATURE hyprctl reload
fi
# Reload kitty
for pid in $(pgrep kitty 2>/dev/null); do kill -USR1 $pid 2>/dev/null; done
# Reload cava
if pgrep -x cava >/dev/null 2>&1; then
    cat ~/.config/cava/config_base ~/.config/cava/colors > ~/.config/cava/config 2>/dev/null
    for pid in $(pgrep cava 2>/dev/null); do kill -USR1 $pid 2>/dev/null; done
fi
# GTK live-reload
if command -v gsettings &>/dev/null; then
    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita'
    sleep 0.05
    gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
    gsettings set org.gnome.desktop.interface color-scheme 'default'
    sleep 0.05
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
fi
