#!/bin/bash

CPU_PATH="/sys/devices/system/cpu/cpu0/cpufreq"
MIN_FREQ=$(cat "$CPU_PATH/cpuinfo_min_freq")
MAX_FREQ=$(cat "$CPU_PATH/scaling_boost_frequencies" 2>/dev/null | tr ' ' '\n' | sort -n | tail -1)
if [ -z "$MAX_FREQ" ] || [ "$MAX_FREQ" -eq 0 ] 2>/dev/null; then
    MAX_FREQ=$(cat "$CPU_PATH/cpuinfo_max_freq")
fi

OLD_GOV=$(cat "$CPU_PATH/scaling_governor")
SCHEDULER=$(cat /sys/block/*/queue/scheduler 2>/dev/null | head -1)
echo "Previous governor: $OLD_GOV"
echo "Scheduler: $SCHEDULER"

STEP=$(( (MAX_FREQ - MIN_FREQ) / 10 ))
[ $STEP -lt 100000 ] && STEP=100000

FREQ_TABLE=()
freq=$MIN_FREQ
while [ $freq -le $MAX_FREQ ]; do
    FREQ_TABLE+=($freq)
    freq=$((freq + STEP))
done
FREQ_TABLE+=($MAX_FREQ)

LAST_IDX=-1

for c in /sys/devices/system/cpu/cpu*/cpufreq; do
    echo userspace > "$c/scaling_governor"
done

while true; do
    read -r cpu u1 n1 s1 id1 io1 ir1 so1 st1 _ < /proc/stat
    t1=$((u1+n1+s1+id1+io1+ir1+so1+st1))
    sleep 1
    read -r cpu u2 n2 s2 id2 io2 ir2 so2 st2 _ < /proc/stat
    t2=$((u2+n2+s2+id2+io2+ir2+so2+st2))
    dt=$((t2-t1))
    [ $dt -eq 0 ] && continue
    usage=$(( ((t2-t1) - (id2+io2-id1-io1)) * 100 / dt ))
    
    idx=$(( usage * ${#FREQ_TABLE[@]} / 100 ))
    [ $idx -ge ${#FREQ_TABLE[@]} ] && idx=$((${#FREQ_TABLE[@]}-1))
    target=${FREQ_TABLE[$idx]}
    
    if [ "$idx" -ne "$LAST_IDX" ]; then
        for c in /sys/devices/system/cpu/cpu*/cpufreq; do
            echo "$target" > "$c/scaling_min_freq"
            echo "$target" > "$c/scaling_max_freq"
        done
        LAST_IDX=$idx
    fi
    echo -ne "\r$((target/1000))MHz $usage%  "
done