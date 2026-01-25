#!/usr/bin/env bash
# =============================================================================
# XMOBAR: HHKB Hybrid Battery Monitor
# =============================================================================
# Muestra bateria de teclados HHKB Hybrid conectados por Bluetooth.
# Auto-detecta cualquier HHKB conectado (no usa MAC hardcodeada).
#
# HHKB con Hasu controller (USB) no tiene bateria, no mostrara nada.
# Solo el HHKB Hybrid (Bluetooth) tiene bateria.
# =============================================================================

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/xmobar-colors.sh"

# Buscar dispositivos HHKB conectados por Bluetooth
# Formato bluetoothctl devices: "Device XX:XX:XX:XX:XX:XX HHKB-Hybrid_1"
HHKB_MACS=$(bluetoothctl devices 2>/dev/null | grep -i "HHKB" | awk '{print $2}')

# Si no hay HHKB por Bluetooth, no mostrar nada
[ -z "$HHKB_MACS" ] && exit 0

output=""
for MAC in $HHKB_MACS; do
    # Verificar que esta conectado y obtener bateria
    BATTERY=$(bluetoothctl info "$MAC" 2>/dev/null | grep "Battery Percentage" | sed 's/.*0x.. (\(.*\))/\1/')

    # Si no tiene bateria o no esta conectado, skip
    [ -z "$BATTERY" ] && continue

    # Color segun nivel (inverso: 100% = verde)
    COLOR=$(pct_to_color_inverse "$BATTERY")

    # Padding a 3 caracteres
    BAT_PAD=$(printf "%3d" "$BATTERY")

    # Icono teclado (Nerd Font)
    output+="<fc=${COLOR}><fn=1>⌨</fn>${BAT_PAD}%</fc> "
done

# Quitar espacio final, si no hay nada no muestra nada
echo "${output% }"
