#!/usr/bin/env bash
# NixOS Updates Monitor - cuenta paquetes actualizables
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/xmobar-colors.sh"

# Cache file para no checkear constantemente
CACHE_FILE="/tmp/xmobar-updates-cache"
CACHE_AGE=3600  # 1 hora

# Si cache existe y es reciente, usar cache
if [ -f "$CACHE_FILE" ]; then
    CACHE_TIME=$(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0)
    NOW=$(date +%s)
    AGE=$((NOW - CACHE_TIME))
    if [ "$AGE" -lt "$CACHE_AGE" ]; then
        cat "$CACHE_FILE"
        exit 0
    fi
fi

# Contar actualizaciones (en background para no bloquear)
# Simplificado: solo mostrar si flake.lock tiene más de 7 días
FLAKE_LOCK="$HOME/dotfiles/flake.lock"
if [ -f "$FLAKE_LOCK" ]; then
    LOCK_TIME=$(stat -c %Y "$FLAKE_LOCK")
    NOW=$(date +%s)
    DAYS=$(( (NOW - LOCK_TIME) / 86400 ))
    
    if [ "$DAYS" -gt 14 ]; then
        RESULT="<fc=${COLOR_RED}>󰚰 ${DAYS}d</fc>"
    elif [ "$DAYS" -gt 7 ]; then
        RESULT="<fc=${COLOR_YELLOW}>󰚰 ${DAYS}d</fc>"
    else
        RESULT=""  # Reciente, no mostrar
    fi
else
    RESULT=""
fi

echo "$RESULT" > "$CACHE_FILE"
echo "$RESULT"
