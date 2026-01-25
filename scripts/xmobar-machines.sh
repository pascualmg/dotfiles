#!/usr/bin/env bash
# =============================================================================
# XMOBAR: Remote Machines Status Monitor
# =============================================================================
# Leyenda: ● = online+SSH, ◐ = online, ○ = offline
# =============================================================================
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/xmobar-colors.sh"

# Máquinas: nombre=host:puerto_ssh
# Red local (piso): 192.168.18.x
# Red local (campo): 192.168.2.x
declare -A MACHINES=(
    ["aurin"]="192.168.2.147:22"
    ["macbook"]="192.168.2.148:22"
    ["vespino"]="192.168.2.149:22"
)

CACHE_FILE="/tmp/xmobar-machines-cache"
CACHE_AGE=30

# Cache
if [ -f "$CACHE_FILE" ]; then
    AGE=$(( $(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0) ))
    [ "$AGE" -lt "$CACHE_AGE" ] && cat "$CACHE_FILE" && exit 0
fi

CURRENT_HOST=$(hostname)
OUTPUT=""

for NAME in "${!MACHINES[@]}"; do
    [ "$NAME" = "$CURRENT_HOST" ] && continue
    
    IFS=':' read -r HOST PORT <<< "${MACHINES[$NAME]}"
    
    # Check SSH directamente (más fiable que ping para hosts remotos)
    if timeout 2 nc -z "$HOST" "$PORT" &>/dev/null; then
        STATUS="<fc=${COLOR_GREEN}>●</fc>"
    else
        STATUS="<fc=${COLOR_RED}>○</fc>"
    fi
    
    OUTPUT="${OUTPUT}${STATUS}${NAME} "
done

# Si no hay output (estamos en la única máquina), no mostrar nada
[ -z "$OUTPUT" ] && echo "" > "$CACHE_FILE" && exit 0

echo "$OUTPUT" | sed 's/ $//' > "$CACHE_FILE"
cat "$CACHE_FILE"
