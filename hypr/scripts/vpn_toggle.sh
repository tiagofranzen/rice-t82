#!/usr/bin/env bash
# Toggle the VPN connection on/off

VPN_NAME="VPN_ME"

ACTIVE=$(nmcli -t -f NAME,TYPE connection show --active 2>/dev/null | awk -F: '$2=="vpn" {print $1; exit}')

if [ -n "$ACTIVE" ]; then
    nmcli connection down "$ACTIVE" && notify-send -u low "VPN" "Disconnected from $ACTIVE"
else
    nmcli connection up "$VPN_NAME" && notify-send -u low "VPN" "Connected to $VPN_NAME" || notify-send -u critical "VPN" "Failed to connect to $VPN_NAME"
fi
