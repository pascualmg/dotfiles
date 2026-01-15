#!/usr/bin/env bash
# NVIDIA GPU monitor for xmobar
# Formato: uso temp vram potencia - cada uno con gradiente

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/xmobar-colors.sh"

# Verificar que nvidia-smi existe
if ! command -v nvidia-smi &>/dev/null; then
    exit 0
fi

# Obtener datos de nvidia-smi
GPU_DATA=$(nvidia-smi --query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total,power.draw,power.limit --format=csv,noheader,nounits 2>/dev/null)
[ -z "$GPU_DATA" ] && exit 0

# Parsear: "30, 45, 2048, 8192, 150, 300"
USAGE=$(echo "$GPU_DATA" | awk -F',' '{gsub(/ /,"",$1); print int($1)}')
TEMP=$(echo "$GPU_DATA" | awk -F',' '{gsub(/ /,"",$2); print int($2)}')
MEM_USED=$(echo "$GPU_DATA" | awk -F',' '{gsub(/ /,"",$3); print int($3)}')
MEM_TOTAL=$(echo "$GPU_DATA" | awk -F',' '{gsub(/ /,"",$4); print int($4)}')
POWER=$(echo "$GPU_DATA" | awk -F',' '{gsub(/ /,"",$5); print int($5)}')
POWER_LIMIT=$(echo "$GPU_DATA" | awk -F',' '{gsub(/ /,"",$6); print int($6)}')

# Calcular porcentajes
[ -z "$USAGE" ] && USAGE=0
[ -z "$TEMP" ] && TEMP=0
[ -z "$MEM_USED" ] && MEM_USED=0
[ -z "$MEM_TOTAL" ] && MEM_TOTAL=1
[ -z "$POWER" ] && POWER=0
[ -z "$POWER_LIMIT" ] && POWER_LIMIT=1

MEM_PCT=$((MEM_USED * 100 / MEM_TOTAL))
POWER_PCT=$((POWER * 100 / POWER_LIMIT))
# Temperatura: 30°C=0%, 90°C=100%
TEMP_PCT=$(( (TEMP - 30) * 100 / 60 ))
[ "$TEMP_PCT" -lt 0 ] && TEMP_PCT=0
[ "$TEMP_PCT" -gt 100 ] && TEMP_PCT=100

# Colores con gradiente
COLOR_USAGE=$(pct_to_color "$USAGE")
COLOR_TEMP=$(pct_to_color "$TEMP_PCT")
COLOR_MEM=$(pct_to_color "$MEM_PCT")
COLOR_POWER=$(pct_to_color "$POWER_PCT")

# Formatear valores
USAGE_PAD=$(printf "%02d" "$USAGE")
MEM_GB=$(awk "BEGIN {printf \"%.1f\", $MEM_USED/1024}")

# Click abre nvidia-smi en loop
echo "<action=\`alacritty -e watch -n1 nvidia-smi\`><fc=${COLOR_USAGE}><fn=1>󰢮</fn>${USAGE_PAD}%</fc> <fc=${COLOR_TEMP}><fn=1>󰔐</fn>${TEMP}°</fc> <fc=${COLOR_MEM}><fn=1>󰍛</fn>${MEM_GB}G</fc> <fc=${COLOR_POWER}><fn=1>󰚥</fn>${POWER}W</fc></action>"
