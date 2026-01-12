#!/usr/bin/env bash
# -*- mode: sh -*-
# Wireless mouse battery monitor for xmobar
# Siempre visible: color según nivel si conectado, gris si desconectado

# Cargar funciones de color compartidas
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/xmobar-colors.sh"

# Buscar batería de dispositivo Logitech (hidpp)
BAT_PATH=$(ls /sys/class/power_supply/hidpp_battery_*/capacity 2>/dev/null | head -1)

if [[ -n "$BAT_PATH" && -f "$BAT_PATH" ]]; then
    BAT=$(cat "$BAT_PATH" 2>/dev/null)

    if [[ -n "$BAT" ]]; then
        COLOR=$(pct_to_color_inverse "$BAT")
        echo "<fc=${COLOR}>$(xmobar_icon "󰍽") ${BAT}%</fc>"
    else
        echo "<fc=${COLOR_GRAY}>$(xmobar_icon "󰍾")</fc>"
    fi
else
    echo "<fc=${COLOR_GRAY}>$(xmobar_icon "󰍾")</fc>"
fi
