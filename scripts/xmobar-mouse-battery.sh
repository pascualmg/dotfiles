#!/usr/bin/env bash
# =============================================================================
# XMOBAR: Logitech Mouse Battery Monitor (HID++ protocol)
# =============================================================================
# Detecta ratones Logitech con batería via hidpp (Lightspeed/Bluetooth)
# G Pro X Superlight, G Pro Wireless, MX Master, etc.
#
# Si no hay ratón Logitech conectado, no muestra nada.
# =============================================================================

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/xmobar-colors.sh"

# Buscar baterías hidpp (Logitech HID++ protocol)
HIDPP_PATH=$(ls -d /sys/class/power_supply/hidpp_battery_* 2>/dev/null | head -1)

# Si no hay ratón Logitech, mostrar icono gris
if [ -z "$HIDPP_PATH" ]; then
	echo "<fc=#444444><fn=1>󰍽</fn></fc>"
	exit 0
fi

# Obtener batería
BATTERY=$(cat "$HIDPP_PATH/capacity" 2>/dev/null)
[ -z "$BATTERY" ] && exit 0

# Color según nivel (inverso: 100% = verde)
COLOR=$(pct_to_color_inverse "$BATTERY")

# Padding a 3 caracteres
BAT_PAD=$(printf "%3d" "$BATTERY")

# Icono ratón (Nerd Font)
echo "<fc=${COLOR}><fn=1>󰍽</fn>${BAT_PAD}%</fc>"
