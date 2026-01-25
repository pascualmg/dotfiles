#!/usr/bin/env bash
# =============================================================================
# XMOBAR: GPU Monitor (Auto-detect NVIDIA / Intel / AMD)
# =============================================================================
# Detecta automaticamente el tipo de GPU y muestra info relevante.
# Si no hay GPU soportada, no muestra nada.
#
# Soporta:
#   - NVIDIA: uso, temp, VRAM, potencia (via nvidia-smi)
#   - Intel: frecuencia y uso aproximado (via sysfs)
#   - AMD: TODO (via radeontop)
# =============================================================================

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/xmobar-colors.sh"

# =============================================================================
# NVIDIA GPU (si nvidia-smi existe y funciona)
# =============================================================================
nvidia_gpu() {
    command -v nvidia-smi &>/dev/null || return 1

    GPU_DATA=$(nvidia-smi --query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total,power.draw,power.limit --format=csv,noheader,nounits 2>/dev/null)
    [ -z "$GPU_DATA" ] && return 1

    # Parsear: "30, 45, 2048, 8192, 150, 300"
    USAGE=$(echo "$GPU_DATA" | awk -F',' '{gsub(/ /,"",$1); print int($1)}')
    TEMP=$(echo "$GPU_DATA" | awk -F',' '{gsub(/ /,"",$2); print int($2)}')
    MEM_USED=$(echo "$GPU_DATA" | awk -F',' '{gsub(/ /,"",$3); print int($3)}')
    MEM_TOTAL=$(echo "$GPU_DATA" | awk -F',' '{gsub(/ /,"",$4); print int($4)}')
    POWER=$(echo "$GPU_DATA" | awk -F',' '{gsub(/ /,"",$5); print int($5)}')
    POWER_LIMIT=$(echo "$GPU_DATA" | awk -F',' '{gsub(/ /,"",$6); print int($6)}')

    # Defaults
    : "${USAGE:=0}" "${TEMP:=0}" "${MEM_USED:=0}" "${MEM_TOTAL:=1}" "${POWER:=0}" "${POWER_LIMIT:=1}"

    # Calcular porcentajes
    MEM_PCT=$((MEM_USED * 100 / MEM_TOTAL))
    POWER_PCT=$((POWER * 100 / POWER_LIMIT))
    # Temperatura: 30C=0%, 90C=100%
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
    return 0
}

# =============================================================================
# Intel GPU (si hay sysfs de Intel)
# =============================================================================
intel_gpu() {
    local card_path=""

    # Buscar tarjeta Intel (puede ser card0 o card1)
    for card in /sys/class/drm/card*/gt_cur_freq_mhz; do
        [ -f "$card" ] || continue
        card_path=$(dirname "$card")
        break
    done

    [ -z "$card_path" ] && return 1

    # Leer frecuencias
    CUR_FREQ=$(cat "$card_path/gt_cur_freq_mhz" 2>/dev/null || echo "0")
    MAX_FREQ=$(cat "$card_path/gt_max_freq_mhz" 2>/dev/null || echo "1000")

    # Calcular % uso aproximado
    if [ "$MAX_FREQ" -gt 0 ]; then
        USAGE=$((CUR_FREQ * 100 / MAX_FREQ))
    else
        USAGE=0
    fi

    # Color segun uso
    COLOR=$(pct_to_color "$USAGE")
    USAGE_PAD=$(printf "%02d" "$USAGE")

    # Click abre intel_gpu_top
    echo "<action=\`alacritty -e sudo intel_gpu_top\`><fc=${COLOR}><fn=1>󰢮</fn>${USAGE_PAD}%</fc></action>"
    return 0
}

# =============================================================================
# AMD GPU (TODO)
# =============================================================================
amd_gpu() {
    # Placeholder para AMD (radeontop)
    return 1
}

# =============================================================================
# MAIN: Detectar y ejecutar
# =============================================================================
# Orden de prioridad: NVIDIA > AMD > Intel
nvidia_gpu && exit 0
amd_gpu && exit 0
intel_gpu && exit 0

# Si no hay GPU soportada, no mostrar nada
exit 0
