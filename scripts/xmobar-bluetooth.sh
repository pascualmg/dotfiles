#!/usr/bin/env bash
# =============================================================================
# XMOBAR: Bluetooth Connected Devices Monitor
# =============================================================================
# Muestra dispositivos BT conectados. No se cuelga si no hay BT.
# =============================================================================
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/xmobar-colors.sh"

# Si no hay servicio bluetooth activo, mostrar icono gris
if ! systemctl is-active bluetooth.service &>/dev/null; then
	echo "<fc=#444444><fn=1>󰂯</fn></fc>"
	exit 0
fi

# Si no hay adaptador bluetooth, mostrar icono gris
if [ ! -d /sys/class/bluetooth ] || [ -z "$(ls -A /sys/class/bluetooth 2>/dev/null)" ]; then
	echo "<fc=#444444><fn=1>󰂯</fn></fc>"
	exit 0
fi

# Contar dispositivos conectados (con echo para evitar stdin wait)
DEVICES=$(echo "" | bluetoothctl devices Connected 2>/dev/null | wc -l)

if [ "$DEVICES" -eq 0 ]; then
	echo "<fc=#444444><fn=1>󰂯</fn></fc>" # Sin dispositivos = gris
	exit 0
elif [ "$DEVICES" -eq 1 ]; then
	NAME=$(echo "" | bluetoothctl devices Connected 2>/dev/null | head -1 | cut -d' ' -f3-)
	echo "<fc=${COLOR_BLUE}>󰂯 ${NAME}</fc>"
else
	echo "<fc=${COLOR_BLUE}>󰂯 ${DEVICES}</fc>"
fi
