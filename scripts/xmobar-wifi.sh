#!/usr/bin/env bash
# =============================================================================
# XMOBAR: WiFi Monitor (laptops/wifi only)
# =============================================================================
# Muestra senal WiFi solo si hay conexion. En desktops sin wifi no muestra nada.
# =============================================================================

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/xmobar-colors.sh"

# Leer senal WiFi desde /proc/net/wireless
SIGNAL=$(awk 'NR==3 {printf "%.0f", $3}' /proc/net/wireless 2>/dev/null)

# Si no hay wifi o no hay senal, mostrar icono gris
if [ -z "$SIGNAL" ] || [ "$SIGNAL" = "0" ]; then
	echo "<fc=#444444><fn=1>󰖩</fn></fc>"
	exit 0
fi

# Color inverso (100% señal = bueno = verde)
COLOR=$(pct_to_color_inverse "$SIGNAL")
# Padding a 2 dígitos
SIG_PAD=$(printf "%02d" "$SIGNAL")
echo "<fc=${COLOR}><fn=1>󰖩</fn>${SIG_PAD}%</fc>"
