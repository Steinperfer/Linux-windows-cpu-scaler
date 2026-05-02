#!/bin/bash

CPU_PATH="/sys/devices/system/cpu/cpu0/cpufreq"
MIN_FREQ=$(cat "$CPU_PATH/cpuinfo_min_freq")
MAX_FREQ=$(cat "$CPU_PATH/scaling_boost_frequencies" 2>/dev/null | tr ' ' '\n' | sort -n | tail -1)
if [ -z "$MAX_FREQ" ] || [ "$MAX_FREQ" -eq 0 ] 2>/dev/null; then
    MAX_FREQ=$(cat "$CPU_PATH/cpuinfo_max_freq")
fi

LAST_FREQ=0

for c in /sys/devices/system/cpu/cpu*/cpufreq; do
    echo userspace > "$c/scaling_governor"
done
echo "set governor=userspace"

while true; do
    read -r cpu u1 n1 s1 id1 io1 ir1 so1 st1 _ < /proc/stat
    t1=$((u1+n1+s1+id1+io1+ir1+so1+st1))
    sleep 0.1
    read -r cpu u2 n2 s2 id2 io2 ir2 so2 st2 _ < /proc/stat
    t2=$((u2+n2+s2+id2+io2+ir2+so2+st2))
    dt=$((t2-t1))
    [ $dt -eq 0 ] && continue
    usage=$(( ((t2-t1) - (id2+io2-id1-io1)) * 100 / dt ))
    
    target=$(( MIN_FREQ + usage * (MAX_FREQ - MIN_FREQ) / 100 ))
    [ $target -lt $MIN_FREQ ] && target=$MIN_FREQ
    [ $target -gt $MAX_FREQ ] && target=$MAX_FREQ
    
    if [ "$target" -ne "$LAST_FREQ" ]; then
        for c in /sys/devices/system/cpu/cpu*/cpufreq; do
            echo "$target" > "$c/scaling_min_freq"
            echo "$target" > "$c/scaling_max_freq"
        done
        LAST_FREQ=$target
        echo "set min=$((target/1000))MHz max=$((target/1000))MHz (load=$usage%)"
    fi
done