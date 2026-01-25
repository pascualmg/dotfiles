#!/usr/bin/env bash
# Keyboard Layout Monitor - US/ES con icono
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/xmobar-colors.sh"

LAYOUT=$(setxkbmap -query 2>/dev/null | awk '/layout/{print $2}')
GROUP=$(xkblayout-state print %c 2>/dev/null || echo "0")

if [ "$GROUP" = "1" ]; then
    echo "<fc=${COLOR_YELLOW}>ES</fc>"
else
    echo "<fc=${COLOR_CYAN}>US</fc>"
fi
