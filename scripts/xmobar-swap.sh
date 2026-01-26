#!/usr/bin/env bash
# Swap Usage Monitor - alerta si se usa swap
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/xmobar-colors.sh"

SWAP_TOTAL=$(free | awk '/Swap/{print $2}')
SWAP_USED=$(free | awk '/Swap/{print $3}')

if [ "$SWAP_TOTAL" -eq 0 ]; then
	echo "<fc=#444444><fn=1>󰾴</fn></fc>" # No swap configurado
	exit 0
fi

SWAP_PCT=$((SWAP_USED * 100 / SWAP_TOTAL))
SWAP_MB=$((SWAP_USED / 1024))

if [ "$SWAP_USED" -eq 0 ]; then
	echo "<fc=#444444><fn=1>󰾴</fn></fc>" # No usar swap = mostrar gris
elif [ "$SWAP_PCT" -gt 50 ]; then
	COLOR="$COLOR_RED"
	echo "<fc=${COLOR}>󰾴 ${SWAP_MB}M</fc>"
elif [ "$SWAP_PCT" -gt 20 ]; then
	COLOR="$COLOR_YELLOW"
	echo "<fc=${COLOR}>󰾴 ${SWAP_MB}M</fc>"
else
	COLOR="$COLOR_ORANGE"
	echo "<fc=${COLOR}>󰾴 ${SWAP_MB}M</fc>"
fi
