#!/bin/bash

# Windows-like CPU frequency scaling for Linux
# Mimics Windows PPM: 100ms sampling, linear load→frequency mapping

CPU_PATH="/sys/devices/system/cpu/cpu0/cpufreq"
MIN_FREQ=0
MAX_FREQ=0
LAST_FREQ=0

# Detect min/max frequencies from kernel interfaces
detect_frequencies() {
    [ -d "$CPU_PATH" ] || { echo "Error: cpufreq not available"; exit 1; }

    # Enable boost if disabled
    for f in boost cpb; do
        if [ -f "$CPU_PATH/$f" ]; then
            val=$(cat "$CPU_PATH/$f" 2>/dev/null)
            [ "$val" = "0" ] && echo 1 > "$CPU_PATH/$f" 2>/dev/null
        fi
    done

    # Get min freq
    MIN_FREQ=$(cat "$CPU_PATH/cpuinfo_min_freq" 2>/dev/null)
    [ -z "$MIN_FREQ" ] && { echo "Error: Cannot read min freq"; exit 1; }

    # Get max freq - try multiple sources
    MAX_FREQ=""
    if [ -s "$CPU_PATH/scaling_boost_frequencies" ]; then
        MAX_FREQ=$(cat "$CPU_PATH/scaling_boost_frequencies" | tr ' ' '\n' | sort -n | tail -1)
    fi
    if [ -z "$MAX_FREQ" ] || [ "$MAX_FREQ" = "0" ]; then
        MAX_FREQ=$(cat "$CPU_PATH/cpuinfo_max_freq" 2>/dev/null)
    fi
    if [ -z "$MAX_FREQ" ] || [ "$MAX_FREQ" = "0" ]; then
        MAX_FREQ=$(cat "$CPU_PATH/scaling_max_freq" 2>/dev/null)
    fi
    [ -z "$MAX_FREQ" ] && { echo "Error: Cannot detect max freq"; exit 1; }

    echo "Detected: Min=$((MIN_FREQ/1000))MHz, Max=$((MAX_FREQ/1000))MHz"
}

# Set userspace governor
set_governor() {
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq; do
        [ -d "$cpu" ] || continue
        echo "userspace" > "$cpu/scaling_governor" 2>/dev/null
    done
}

# Get CPU usage over 100ms
get_usage() {
    read -r cpu u1 n1 s1 id1 io1 ir1 so1 st1 _ < /proc/stat
    t1=$((u1+n1+s1+id1+io1+ir1+so1+st1))
    sleep 0.1
    read -r cpu u2 n2 s2 id2 io2 ir2 so2 st2 _ < /proc/stat
    t2=$((u2+n2+s2+id2+io2+ir2+so2+st2))
    dt=$((t2-t1))
    [ $dt -eq 0 ] && { echo 0; return; }
    echo $(( ((t2-t1) - (id2+io2-id1-io1)) * 100 / dt ))
}

# Set frequency on all CPUs
set_freq() {
    local freq=$1
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq; do
        [ -d "$cpu" ] || continue
        echo "$freq" > "$cpu/scaling_min_freq" 2>/dev/null
        echo "$freq" > "$cpu/scaling_max_freq" 2>/dev/null
    done
    LAST_FREQ=$freq
}

main() {
    [ "$EUID" -ne 0 ] && { echo "Run as root (sudo)"; exit 1; }
    
    detect_frequencies
    set_governor
    
    echo "Windows-like CPU scaling started (100ms sampling)"
    echo "Press Ctrl+C to stop"
    
    while true; do
        usage=$(get_usage)
        # Linear scaling like Windows PPM
        range=$((MAX_FREQ - MIN_FREQ))
        target=$(( MIN_FREQ + usage * range / 100 ))
        [ $target -lt $MIN_FREQ ] && target=$MIN_FREQ
        [ $target -gt $MAX_FREQ ] && target=$MAX_FREQ
        
        if [ "$target" -ne "$LAST_FREQ" ]; then
            set_freq $target
            echo "$(date +%H:%M:%S) Usage: ${usage}% → $((target/1000))MHz"
        fi
    done
}

main "$@"
