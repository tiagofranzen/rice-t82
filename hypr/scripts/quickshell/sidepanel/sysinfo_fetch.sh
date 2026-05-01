#!/usr/bin/env bash
# Fetch CPU%, RAM%, temps, net speeds in one shot → JSON

# CPU usage (1s sample)
cpu=$(awk 'NR==1{u=$2+$4; t=$2+$3+$4+$5+$6+$7+$8; print u, t}' /proc/stat; sleep 1; awk 'NR==1{u=$2+$4; t=$2+$3+$4+$5+$6+$7+$8; print u, t}' /proc/stat)
cpu_u1=$(echo "$cpu" | awk 'NR==1{print $1}')
cpu_t1=$(echo "$cpu" | awk 'NR==1{print $2}')
cpu_u2=$(echo "$cpu" | awk 'NR==2{print $1}')
cpu_t2=$(echo "$cpu" | awk 'NR==2{print $2}')
cpu_pct=$(awk "BEGIN{d=$cpu_t2-$cpu_t1; if(d>0) printf \"%.0f\", ($cpu_u2-$cpu_u1)*100/d; else print 0}")

# RAM
read total avail <<< $(awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{print t, a}' /proc/meminfo)
ram_used=$(( (total - avail) / 1024 ))
ram_total=$(( total / 1024 ))
ram_pct=$(awk "BEGIN{printf \"%.0f\", ($ram_used/$ram_total)*100}")

# Temperature - highest CPU core
temp=0
for f in /sys/class/thermal/thermal_zone*/temp; do
    type_file="${f%temp}type"
    type=$(cat "$type_file" 2>/dev/null)
    [[ "$type" == *cpu* || "$type" == *cpuss* ]] || continue
    val=$(cat "$f" 2>/dev/null)
    t=$(( val / 1000 ))
    [ "$t" -gt "$temp" ] && temp=$t
done
[ "$temp" -eq 0 ] && temp=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null | awk '{printf "%.0f",$1/1000}')

# Network speeds
iface=$(ip route show default 2>/dev/null | awk '/default/{print $5; exit}')
if [ -n "$iface" ] && [ -f "/sys/class/net/$iface/statistics/rx_bytes" ]; then
    rx1=$(cat /sys/class/net/$iface/statistics/rx_bytes)
    tx1=$(cat /sys/class/net/$iface/statistics/tx_bytes)
    sleep 1
    rx2=$(cat /sys/class/net/$iface/statistics/rx_bytes)
    tx2=$(cat /sys/class/net/$iface/statistics/tx_bytes)
    rx_kbs=$(( (rx2 - rx1) / 1024 ))
    tx_kbs=$(( (tx2 - tx1) / 1024 ))
else
    rx_kbs=0; tx_kbs=0
fi

# Format speed: show MB/s if >= 1000 KB/s
fmt_speed() {
    local kb=$1
    if [ "$kb" -ge 1024 ]; then
        awk "BEGIN{printf \"%.1f MB/s\", $kb/1024}"
    else
        echo "${kb} KB/s"
    fi
}

jq -n -c \
    --argjson cpu "$cpu_pct" \
    --argjson ram_used "$ram_used" \
    --argjson ram_total "$ram_total" \
    --argjson ram_pct "$ram_pct" \
    --argjson temp "$temp" \
    --arg rx "$(fmt_speed $rx_kbs)" \
    --arg tx "$(fmt_speed $tx_kbs)" \
    --arg iface "${iface:-none}" \
    '{cpu:$cpu, ram_used:$ram_used, ram_total:$ram_total, ram_pct:$ram_pct, temp:$temp, rx:$rx, tx:$tx, iface:$iface}'
