#!/usr/bin/env bash
# NixOS Updates Monitor - muestra días desde último flake update
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/xmobar-colors.sh"

# Cache file para no checkear constantemente
CACHE_FILE="/tmp/xmobar-updates-cache"
CACHE_AGE=3600 # 1 hora

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

# Calcular días desde último flake update
FLAKE_LOCK="$HOME/dotfiles/flake.lock"
if [ -f "$FLAKE_LOCK" ]; then
	LOCK_TIME=$(stat -c %Y "$FLAKE_LOCK")
	NOW=$(date +%s)
	DAYS=$(((NOW - LOCK_TIME) / 86400))

	# Colores: verde <7d, amarillo 7-10d, rojo >10d
	if [ "$DAYS" -gt 10 ]; then
		RESULT="<fc=${COLOR_RED}><fn=1>󰚰</fn>${DAYS}d</fc>"
	elif [ "$DAYS" -gt 7 ]; then
		RESULT="<fc=${COLOR_YELLOW}><fn=1>󰚰</fn>${DAYS}d</fc>"
	else
		RESULT="<fc=${COLOR_GREEN}><fn=1>󰚰</fn>${DAYS}d</fc>"
	fi
else
	# Si no existe flake.lock, mostrar en gris
	RESULT="<fc=#444444><fn=1>󰚰</fn>?</fc>"
fi

echo "$RESULT" >"$CACHE_FILE"
echo "$RESULT"
