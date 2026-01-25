#!/usr/bin/env bash
# Bluetooth Connected Devices Monitor
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/xmobar-colors.sh"

# Contar dispositivos conectados
DEVICES=$(bluetoothctl devices Connected 2>/dev/null | wc -l)

if [ "$DEVICES" -eq 0 ]; then
    echo ""  # No mostrar si no hay dispositivos
elif [ "$DEVICES" -eq 1 ]; then
    NAME=$(bluetoothctl devices Connected | head -1 | cut -d' ' -f3-)
    echo "<fc=${COLOR_BLUE}>󰂯 ${NAME}</fc>"
else
    echo "<fc=${COLOR_BLUE}>󰂯 ${DEVICES}</fc>"
fi
