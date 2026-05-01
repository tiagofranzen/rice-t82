#!/usr/bin/env bash

get_vpn_data() {
    local active_vpn
    active_vpn=$(LC_ALL=C nmcli -t -f NAME,TYPE connection show --active 2>/dev/null | awk -F: '$2=="vpn" {print $1; exit}')

    if [ -n "$active_vpn" ]; then
        echo "connected|${active_vpn}|󰌆"
    else
        echo "disconnected||󰌊"
    fi
}

IFS='|' read -r status name icon <<< "$(get_vpn_data)"

jq -n -c \
    --arg status "$status" \
    --arg name "$name" \
    --arg icon "$icon" \
    '{status: $status, name: $name, icon: $icon}'
