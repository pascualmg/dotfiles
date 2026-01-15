#!/usr/bin/env bash
# CPU monitor for xmobar - uso, temperatura y consumo con gradientes

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/xmobar-colors.sh"

# ===== USO CPU =====
read -r cpu user1 nice1 system1 idle1 iowait1 irq1 softirq1 _ < /proc/stat
sleep 0.1
read -r cpu user2 nice2 system2 idle2 iowait2 irq2 softirq2 _ < /proc/stat

idle=$((idle2 - idle1))
total=$(( (user2+nice2+system2+idle2+iowait2+irq2+softirq2) - (user1+nice1+system1+idle1+iowait1+irq1+softirq1) ))

if [[ $total -gt 0 ]]; then
    CPU=$(( 100 * (total - idle) / total ))
else
    CPU=0
fi

# ===== TEMPERATURA CPU =====
# Leer la temp más alta de las zonas térmicas (en milligrados)
TEMP=0
for tz in /sys/class/thermal/thermal_zone*/temp; do
    [ -f "$tz" ] || continue
    t=$(cat "$tz" 2>/dev/null)
    t=$((t / 1000))
    [ "$t" -gt "$TEMP" ] && TEMP=$t
done

# ===== CONSUMO CPU (RAPL) =====
# Sumar todos los packages Intel (dual socket = 2 packages)
POWER=""
if [ -r "/sys/class/powercap/intel-rapl/intel-rapl:0/energy_uj" ]; then
    # Leer energía inicial
    E1=0
    for pkg in /sys/class/powercap/intel-rapl/intel-rapl:*/energy_uj; do
        [ -r "$pkg" ] || continue
        e=$(cat "$pkg" 2>/dev/null)
        E1=$((E1 + e))
    done
    sleep 0.2
    # Leer energía final
    E2=0
    for pkg in /sys/class/powercap/intel-rapl/intel-rapl:*/energy_uj; do
        [ -r "$pkg" ] || continue
        e=$(cat "$pkg" 2>/dev/null)
        E2=$((E2 + e))
    done
    # Calcular potencia en W (energy_uj = microjoules)
    # P = dE / dt, dt=0.2s, dE en uJ -> W = dE / (dt * 1000000)
    POWER=$(( (E2 - E1) / 200000 ))
fi

# ===== COLORES =====
COLOR_CPU=$(pct_to_color "$CPU")
# Temperatura: 30°C=0%, 90°C=100%
TEMP_PCT=$(( (TEMP - 30) * 100 / 60 ))
[ "$TEMP_PCT" -lt 0 ] && TEMP_PCT=0
[ "$TEMP_PCT" -gt 100 ] && TEMP_PCT=100
COLOR_TEMP=$(pct_to_color "$TEMP_PCT")

# ===== OUTPUT =====
CPU_PAD=$(printf "%02d" "$CPU")
OUTPUT="<fc=${COLOR_CPU}><fn=1>󰻠</fn>${CPU_PAD}%</fc> <fc=${COLOR_TEMP}><fn=1>󰔐</fn>${TEMP}°</fc>"

# Añadir power si está disponible
if [ -n "$POWER" ] && [ "$POWER" -gt 0 ]; then
    # TDP dual Xeon ~290W total, usar 300W como referencia
    POWER_PCT=$((POWER * 100 / 300))
    [ "$POWER_PCT" -gt 100 ] && POWER_PCT=100
    COLOR_POWER=$(pct_to_color "$POWER_PCT")
    OUTPUT="$OUTPUT <fc=${COLOR_POWER}><fn=1>󰚥</fn>${POWER}W</fc>"
fi

echo "<action=\`xterm -e btop\`>$OUTPUT</action>"
