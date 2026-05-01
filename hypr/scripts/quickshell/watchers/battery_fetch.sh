#!/usr/bin/env bash
BAT=/sys/class/power_supply/qcom-battmgr-bat
get_battery_percent() {
    local now full retries=3
    for i in $(seq 1 $retries); do
        now=$(cat "$BAT/energy_now" 2>/dev/null)
        full=$(cat "$BAT/energy_full" 2>/dev/null)
        if [ -n "$now" ] && [ -n "$full" ] && [ "$full" -gt 0 ] && [ "$now" -gt 0 ]; then
            echo $(( now * 100 / full ))
            return
        fi
        [ $i -lt $retries ] && sleep 0.5
    done
    # If energy_now is 0 but full is known, something is wrong - return last known or 0
    if [ -n "$full" ] && [ "$full" -gt 0 ]; then
        echo $(( ${now:-0} * 100 / full ))
    else
        echo "0"
    fi
}
get_battery_status() { LC_ALL=C cat "$BAT/status" 2>/dev/null | head -n1 || echo "Full"; }
get_battery_icon() {
    local percent=$(get_battery_percent)
    local status=$(get_battery_status)
    if [ "$status" = "Charging" ] || [ "$status" = "Full" ]; then
        if [ "$percent" -ge 90 ]; then echo "󰂅"
        elif [ "$percent" -ge 80 ]; then echo "󰂋"
        elif [ "$percent" -ge 60 ]; then echo "󰂊"
        elif [ "$percent" -ge 40 ]; then echo "󰢞"
        elif [ "$percent" -ge 20 ]; then echo "󰂆"
        else echo "󰢜"; fi
    else
        if [ "$percent" -ge 90 ]; then echo "󰁹"
        elif [ "$percent" -ge 80 ]; then echo "󰂂"
        elif [ "$percent" -ge 70 ]; then echo "󰂁"
        elif [ "$percent" -ge 60 ]; then echo "󰂀"
        elif [ "$percent" -ge 50 ]; then echo "󰁿"
        elif [ "$percent" -ge 40 ]; then echo "󰁾"
        elif [ "$percent" -ge 30 ]; then echo "󰁽"
        elif [ "$percent" -ge 20 ]; then echo "󰁼"
        elif [ "$percent" -ge 10 ]; then echo "󰁻"
        else echo "󰁺"; fi
    fi
}
jq -n -c --arg percent "$(get_battery_percent)" --arg status "$(get_battery_status)" --arg icon "$(get_battery_icon)" '{percent: $percent, status: $status, icon: $icon}'
