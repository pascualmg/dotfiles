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
    # Batería disponible via hidpp
    BAT=$(cat "$BAT_PATH" 2>/dev/null)
    if [[ -n "$BAT" ]]; then
        COLOR=$(pct_to_color_inverse "$BAT")
        BAT_PAD=$(printf "%02d" "$BAT")
        echo "<fc=${COLOR}><fn=1>󰍽</fn>${BAT_PAD}%</fc>"
        exit 0
    fi
fi

# Fallback: detectar ratón Logitech via xinput (sin info de batería)
if xinput list 2>/dev/null | grep -qi "Logitech.*Pro\|G Pro"; then
    # Ratón conectado pero sin info de batería (driver no soporta)
    echo "<fc=${COLOR_GREEN}>$(xmobar_icon "󰍽")</fc>"
fi
# Si no está conectado, no mostrar nada
