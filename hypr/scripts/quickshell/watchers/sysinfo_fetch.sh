#!/usr/bin/env bash
read_cpu_stats() {
    awk '/^cpu /{s=0; for(i=2;i<=NF;i++) s+=$i; idle=$5+$6; print s, idle}' /proc/stat
}
s1=$(read_cpu_stats); sleep 0.8; s2=$(read_cpu_stats)
t1=$(echo $s1 | cut -d' ' -f1); i1=$(echo $s1 | cut -d' ' -f2)
t2=$(echo $s2 | cut -d' ' -f1); i2=$(echo $s2 | cut -d' ' -f2)
dt=$((t2-t1)); di=$((i2-i1))
cpu=0; [ "$dt" -gt 0 ] && cpu=$(( (dt-di)*100/dt ))

mem_total=$(awk '/MemTotal/{print $2}' /proc/meminfo)
mem_avail=$(awk '/MemAvailable/{print $2}' /proc/meminfo)
ram_mb=$(( (mem_total - mem_avail) / 1024 ))
ram_int=$(( ram_mb / 1024 ))
ram_dec=$(( (ram_mb % 1024) * 10 / 1024 ))

temp_sum=0; temp_n=0
for f in /sys/class/thermal/thermal_zone*/type; do
    [[ "$(cat "$f" 2>/dev/null)" == cpuss*-top* ]] || continue
    v=$(cat "${f/type/temp}" 2>/dev/null)
    temp_sum=$((temp_sum + v)); temp_n=$((temp_n + 1))
done
temp=0; [ "$temp_n" -gt 0 ] && temp=$((temp_sum / temp_n / 1000))

printf '{"cpu":%d,"ram":"%d.%d","temp":%d}\n' "$cpu" "$ram_int" "$ram_dec" "$temp"
