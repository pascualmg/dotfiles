#!/usr/bin/env bash
# Active SSH Sessions Monitor
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/xmobar-colors.sh"

# Contar sesiones SSH entrantes (otros conectados a mí)
INCOMING=$(ss -tn state established '( dport = :22 )' 2>/dev/null | tail -n +2 | wc -l)
# Contar conexiones SSH salientes (yo conectado a otros)
OUTGOING=$(ss -tn state established '( sport = :22 )' 2>/dev/null | tail -n +2 | wc -l)

TOTAL=$((INCOMING + OUTGOING))

if [ "$TOTAL" -eq 0 ]; then
    echo ""
elif [ "$INCOMING" -gt 0 ] && [ "$OUTGOING" -gt 0 ]; then
    echo "<fc=${COLOR_CYAN}>󰣀 ↓${INCOMING}↑${OUTGOING}</fc>"
elif [ "$INCOMING" -gt 0 ]; then
    echo "<fc=${COLOR_YELLOW}>󰣀 ↓${INCOMING}</fc>"
else
    echo "<fc=${COLOR_CYAN}>󰣀 ↑${OUTGOING}</fc>"
fi
