#!/bin/bash
CPU_PATH="/sys/devices/system/cpu/cpu0/cpufreq"
MIN_FREQ=$(cat "$CPU_PATH/cpuinfo_min_freq")
MAX_FREQ=$(cat "$CPU_PATH/cpuinfo_max_freq")

# Echte verfügbare Stufen einlesen und sortieren
mapfile -t STEPS < <(tr ' ' '\n' < "$CPU_PATH/scaling_available_frequencies" | grep -v '^$' | sort -n)
N=${#STEPS[@]}

echo "Verfügbare Frequenzen: ${STEPS[*]}"
echo "Min: $((MIN_FREQ/1000))MHz | Max: $((MAX_FREQ/1000))MHz | Turbo: via Hardware"

trap 'echo ""; for c in /sys/devices/system/cpu/cpu*/cpufreq; do
    echo schedutil > "$c/scaling_governor"   2>/dev/null
    echo "$MIN_FREQ" > "$c/scaling_min_freq" 2>/dev/null
    echo "$MAX_FREQ" > "$c/scaling_max_freq" 2>/dev/null
done; exit' INT TERM

for c in /sys/devices/system/cpu/cpu*/cpufreq; do
    echo schedutil > "$c/scaling_governor"   2>/dev/null
    echo "$MIN_FREQ" > "$c/scaling_min_freq" 2>/dev/null
    echo "$MAX_FREQ" > "$c/scaling_max_freq" 2>/dev/null
done

EMA=0
LAST_MAX=0
# Asymmetrisch: schnell rauf bei echter Last, langsam runter
ALPHA_UP=7
ALPHA_DOWN=2

# Schwellwerte für 3 Stufen (an deine CPU angepasst)
# Stufe 1 (2200): EMA < 30%
# Stufe 2 (3200): EMA 30-70%
# Stufe 3 (3600+Turbo): EMA > 70%
T1=30
T2=70

while true; do
    read -r cpu u1 n1 s1 id1 io1 ir1 so1 st1 _ < /proc/stat
    sleep 0.5
    read -r cpu u2 n2 s2 id2 io2 ir2 so2 st2 _ < /proc/stat

    dt=$(( (u2+n2+s2+id2+io2+ir2+so2+st2) - (u1+n1+s1+id1+io1+ir1+so1+st1) ))
    [ $dt -eq 0 ] && continue
    usage=$(( (dt - (id2+io2-id1-io1)) * 100 / dt ))
    [ $usage -lt 0 ]   && usage=0
    [ $usage -gt 100 ] && usage=100

    # EMA asymmetrisch
    if [ $usage -gt $EMA ]; then
        EMA=$(( (EMA * (10-ALPHA_UP)   + usage * ALPHA_UP)   / 10 ))
    else
        EMA=$(( (EMA * (10-ALPHA_DOWN) + usage * ALPHA_DOWN) / 10 ))
    fi

    # Stufe wählen basierend auf EMA
    if [ $EMA -lt $T1 ]; then
        NEW_MAX=${STEPS[0]}          # 2200MHz
    elif [ $EMA -lt $T2 ]; then
        NEW_MAX=${STEPS[$((N/2))]}   # 3200MHz (mittlere Stufe)
    else
        NEW_MAX=${STEPS[$((N-1))]}   # 3600MHz + Turbo frei
    fi

    # Nur schreiben wenn geändert
    if [ "$NEW_MAX" -ne "$LAST_MAX" ]; then
        for c in /sys/devices/system/cpu/cpu*/cpufreq; do
            echo "$MIN_FREQ" > "$c/scaling_min_freq" 2>/dev/null
            echo "$NEW_MAX"  > "$c/scaling_max_freq" 2>/dev/null
        done
        LAST_MAX=$NEW_MAX
    fi

    cur=$(grep "cpu MHz" /proc/cpuinfo | awk '{s+=$4;n++} END{printf "%0.f",s/n*1000}')
    TURBO=""
    [ "$cur" -gt "$MAX_FREQ" ] && TURBO=" ⚡TURBO"

    echo -ne "\rEcht: $((cur/1000))MHz | Max: $((NEW_MAX/1000))MHz | Last: $usage% (EMA:$EMA%)$TURBO  "
done
