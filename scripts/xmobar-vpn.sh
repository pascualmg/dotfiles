#!/usr/bin/env bash
# VPN (Pulse Secure) Monitor
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/xmobar-colors.sh"

# Buscar interfaz tun de Pulse
if ip link show tun0 &>/dev/null || pgrep -x "pulseUI" &>/dev/null; then
	# Verificar si realmente está conectado
	if ip addr show tun0 2>/dev/null | grep -q "inet "; then
		echo "<action=\`nm-connection-editor\`><fc=${COLOR_GREEN}><fn=1>󰖂</fn></fc></action>"
	else
		echo "<action=\`nm-connection-editor\`><fc=${COLOR_YELLOW}><fn=1>󰖂</fn>...</fc></action>"
	fi
else
	# No conectado - mostrar icono gris
	echo "<action=\`nm-connection-editor\`><fc=#444444><fn=1>󰖂</fn></fc></action>"
fi
