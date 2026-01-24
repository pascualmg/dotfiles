#!/usr/bin/env bash
# =============================================================================
# XMOBAR: HHKB Hybrid Battery Monitor
# =============================================================================
# Muestra batería del teclado HHKB Hybrid conectado por Bluetooth
# Usa sistema de colores compartido (xmobar-colors.sh)
# =============================================================================

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/xmobar-colors.sh"

HHKB_MAC="E0:09:E7:07:B1:DD"

# Obtener porcentaje
BATTERY=$(bluetoothctl info "$HHKB_MAC" 2>/dev/null | grep "Battery Percentage" | sed 's/.*0x.. (\(.*\))/\1/')

# Si no hay batería o no está conectado
if [ -z "$BATTERY" ]; then
    echo ""
    exit 0
fi

# Icono teclado (Nerd Font)
ICON="⌨"

# Color según nivel (inverso: 100% = verde)
COLOR=$(pct_to_color_inverse "$BATTERY")

# Padding a 3 caracteres para alinear
BAT_PAD=$(printf "%3d" "$BATTERY")

echo "<fc=${COLOR}><fn=1>${ICON}</fn>${BAT_PAD}%</fc>"
