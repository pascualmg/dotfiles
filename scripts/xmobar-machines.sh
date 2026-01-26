#!/usr/bin/env bash
# =============================================================================
# XMOBAR: Remote Machines Status Monitor
# =============================================================================
# Leyenda: ● = online+SSH, ◐ = online, ○ = offline
# =============================================================================
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/xmobar-colors.sh"

# =============================================================================
# MÁQUINAS A MONITOREAR
# =============================================================================
# Formato: ["nombre"]="host:puerto"
# - Usa DDNS/hostname para acceso remoto (campo.zapto.org)
# - Usa IP local si solo acceso LAN (192.168.x.x)
# - Puerto SSH (22 por defecto, o el que tengas en port forwarding)
# =============================================================================
declare -A MACHINES=(
	["aurin"]="campo.zapto.org:2222" # DDNS + puerto SSH externo
	# ["vespino"]="192.168.2.149:22"    # Solo LAN campo
	# ["vps"]="mi-vps.com:22"           # Ejemplo VPS
)

CACHE_FILE="/tmp/xmobar-machines-cache"
CACHE_AGE=30

# Cache
if [ -f "$CACHE_FILE" ]; then
	AGE=$(($(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0)))
	[ "$AGE" -lt "$CACHE_AGE" ] && cat "$CACHE_FILE" && exit 0
fi

CURRENT_HOST=$(hostname)
OUTPUT=""

for NAME in "${!MACHINES[@]}"; do
	[ "$NAME" = "$CURRENT_HOST" ] && continue

	IFS=':' read -r HOST PORT <<<"${MACHINES[$NAME]}"

	# Check SSH directamente (más fiable que ping para hosts remotos)
	if timeout 2 nc -z "$HOST" "$PORT" &>/dev/null; then
		STATUS="<fc=${COLOR_GREEN}>●</fc>"
	else
		STATUS="<fc=${COLOR_RED}>○</fc>"
	fi

	OUTPUT="${OUTPUT}${STATUS}${NAME} "
done

# Si no hay output (estamos en la única máquina), mostrar icono gris
if [ -z "$OUTPUT" ]; then
	echo "<fc=#444444><fn=1>󰆧</fn></fc>" >"$CACHE_FILE"
	cat "$CACHE_FILE"
	exit 0
fi

echo "$OUTPUT" | sed 's/ $//' >"$CACHE_FILE"
cat "$CACHE_FILE"
