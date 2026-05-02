#!/bin/bash
# Setzt CPU auf Turbo via performance Governor

init() {
    for c in /sys/devices/system/cpu/cpu*/cpufreq; do
        [ -d "$c" ] && echo performance > "$c/scaling_governor"
    done
}

[ "$EUID" -ne 0 ] && exit 1
init
echo "Turbo aktiviert - CPU läuft auf Max"

while true; do
    sleep 999999
done