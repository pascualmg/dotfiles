#!/usr/bin/env bash
# Intel GPU monitor for xmobar (Iris, UHD, etc)
# Muestra: frecuencia y % uso aproximado

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/xmobar-colors.sh"

# Buscar la tarjeta Intel (puede ser card0 o card1)
for card in /sys/class/drm/card*/gt_cur_freq_mhz; do
    [ -f "$card" ] || continue
    CARD_PATH=$(dirname "$card")
    break
done

# Si no hay GPU Intel, no mostrar nada
[ -z "$CARD_PATH" ] && exit 0

# Leer frecuencias
CUR_FREQ=$(cat "$CARD_PATH/gt_cur_freq_mhz" 2>/dev/null || echo "0")
MAX_FREQ=$(cat "$CARD_PATH/gt_max_freq_mhz" 2>/dev/null || echo "1000")

# Calcular % uso aproximado
if [ "$MAX_FREQ" -gt 0 ]; then
    USAGE=$((CUR_FREQ * 100 / MAX_FREQ))
else
    USAGE=0
fi

# Color según uso
COLOR=$(pct_to_color "$USAGE")
USAGE_PAD=$(printf "%02d" "$USAGE")

# Click abre intel_gpu_top si está disponible, si no nada
echo "<action=\`xterm -e sudo intel_gpu_top\`><fc=${COLOR}><fn=1>󰢮</fn>${USAGE_PAD}%</fc></action>"
