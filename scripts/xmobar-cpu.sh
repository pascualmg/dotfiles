#!/usr/bin/env bash
# CPU monitor for xmobar - icono y valor con color dinámico

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/xmobar-colors.sh"

# Leer uso de CPU usando /proc/stat (dos muestras con 100ms entre ellas)
read -r cpu user1 nice1 system1 idle1 iowait1 irq1 softirq1 _ < /proc/stat
sleep 0.1
read -r cpu user2 nice2 system2 idle2 iowait2 irq2 softirq2 _ < /proc/stat

# Calcular deltas
idle=$((idle2 - idle1))
total=$(( (user2+nice2+system2+idle2+iowait2+irq2+softirq2) - (user1+nice1+system1+idle1+iowait1+irq1+softirq1) ))

# Calcular porcentaje de uso
if [[ $total -gt 0 ]]; then
    CPU=$(( 100 * (total - idle) / total ))
else
    CPU=0
fi

COLOR=$(pct_to_color "$CPU")
# Padding a 2 dígitos para evitar desplazamiento
CPU_PAD=$(printf "%02d" "$CPU")
echo "<fc=${COLOR}>$(xmobar_icon "󰻠")${CPU_PAD}%</fc>"
