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
        echo "<fc=${COLOR}>$(xmobar_icon "󰍽") ${BAT}%</fc>"
        exit 0
    fi
fi

# Fallback: detectar ratón Logitech via xinput (sin info de batería)
if xinput list 2>/dev/null | grep -qi "Logitech.*Pro\|G Pro"; then
    # Ratón conectado pero sin info de batería (driver no soporta)
    echo "<fc=${COLOR_GREEN}>$(xmobar_icon "󰍽")</fc>"
else
    # Sin hidpp_battery ni xinput - verificar receptor USB Logitech
    # 046d:c54d = Lightspeed USB Receiver
    if lsusb 2>/dev/null | grep -qi "046d:c54d\|logitech.*receiver"; then
        # Receptor presente pero sin info batería (driver hidpp no activo)
        echo "<fc=${COLOR_CYAN}>$(xmobar_icon "󰍽")</fc>"
    else
        # No hay receptor conectado
        echo "<fc=${COLOR_GRAY}>$(xmobar_icon "󰍾")</fc>"
    fi
fi
