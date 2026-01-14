#!/usr/bin/env bash
# WiFi monitor for xmobar - icono y señal con color dinámico

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/xmobar-colors.sh"

# Leer señal WiFi desde /proc/net/wireless
SIGNAL=$(awk 'NR==3 {printf "%.0f", $3}' /proc/net/wireless 2>/dev/null)

if [ -z "$SIGNAL" ] || [ "$SIGNAL" = "0" ]; then
    echo "<fc=$COLOR_GRAY><fn=1>󰖪</fn></fc>N/A"
    exit 0
fi

# Color inverso (100% señal = bueno = verde)
COLOR=$(pct_to_color_inverse "$SIGNAL")
# Padding a 2 dígitos
SIG_PAD=$(printf "%02d" "$SIGNAL")
echo "<fc=${COLOR}><fn=1>󰖩</fn>${SIG_PAD}%</fc>"
