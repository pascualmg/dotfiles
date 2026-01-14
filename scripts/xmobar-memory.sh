#!/usr/bin/env bash
# Memory monitor for xmobar - icono y valor con color dinámico

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/xmobar-colors.sh"

# Leer memoria desde /proc/meminfo
eval $(awk '/^MemTotal:/ {total=$2} /^MemAvailable:/ {available=$2} END {printf "TOTAL=%d\nAVAIL=%d", total, available}' /proc/meminfo)

# Calcular porcentaje usado
if [[ $TOTAL -gt 0 ]]; then
    USED_PCT=$(( 100 * (TOTAL - AVAIL) / TOTAL ))
else
    USED_PCT=0
fi

COLOR=$(pct_to_color "$USED_PCT")
# Padding a 2 dígitos para evitar desplazamiento
MEM_PAD=$(printf "%02d" "$USED_PCT")
echo "<fc=${COLOR}>$(xmobar_icon "󰍛")${MEM_PAD}%</fc>"
