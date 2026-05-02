#!/bin/bash

for c in /sys/devices/system/cpu/cpu*/cpufreq; do
    echo performance > "$c/scaling_governor"
done

while true; do
    A=$(cat /proc/stat | head -1)
    T1=$(echo "$A" | awk '{print $2+$3+$4+$5+$6+$7+$8}')
    I1=$(echo "$A" | awk '{print $5+$6}')
    sleep 0.1
    B=$(cat /proc/stat | head -1)
    T2=$(echo "$B" | awk '{print $2+$3+$4+$5+$6+$7+$8}')
    I2=$(echo "$B" | awk '{print $5+$6}')
    
    DT=$((T2-T1))
    DI=$((I2-I1))
    [ $DT -eq 0 ] && U=0 || U=$(( (DT-DI)*100/DT ))
    
    F=$((2400000 + U*2000000/100))
    
    for c in /sys/devices/system/cpu/cpu*/cpufreq; do
        echo $F > "$c/scaling_max_freq"
    done
    
    echo "--- set max=$((F/1000))MHz load=$U% ---"
    
    for c in /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq; do
        echo "$(( $(cat $c) / 1000 ))"
    done | sort -nu | head -1 | xargs echo "cur:"
    sleep 0.5
done