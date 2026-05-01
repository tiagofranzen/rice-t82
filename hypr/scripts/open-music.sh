#!/usr/bin/env bash
# open-music.sh — focus existing Apple Music window or open it as a PWA
# Works via Firefox profile named "music" or falls back to regular Firefox

MUSIC_URL="https://music.apple.com"

# Check if a Firefox window with Apple Music is already open
EXISTING=$(hyprctl clients -j | python3 -c "
import sys, json
clients = json.load(sys.stdin)
for c in clients:
    title = c.get('title', '').lower()
    cls   = c.get('class', '').lower()
    if 'apple music' in title or ('music.apple' in title and 'firefox' in cls):
        print(c['address'])
        break
" 2>/dev/null)

if [ -n "$EXISTING" ]; then
    hyprctl dispatch focuswindow "address:$EXISTING"
else
    # Try launching as Firefox PWA/webapp; fall back to plain Firefox tab
    if firefox --help 2>/dev/null | grep -q "\-\-class"; then
        firefox --class="AppleMusic" --name="AppleMusic" \
            --profile="$HOME/.mozilla/firefox/music" \
            "$MUSIC_URL" 2>/dev/null &
    else
        firefox "$MUSIC_URL" &
    fi
fi
