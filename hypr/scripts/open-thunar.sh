#!/usr/bin/env bash
# open-thunar.sh — focus existing Thunar window or launch a new one

EXISTING=$(hyprctl clients -j | python3 -c "
import sys, json
for c in json.load(sys.stdin):
    if 'thunar' in c.get('class','').lower() or 'thunar' in c.get('title','').lower():
        print(c['address'])
        break
" 2>/dev/null)

if [ -n "$EXISTING" ]; then
    hyprctl dispatch focuswindow "address:$EXISTING"
else
    thunar &
fi
