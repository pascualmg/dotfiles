#!/usr/bin/env bash
# Uptime Monitor
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/xmobar-colors.sh"

UPTIME=$(uptime -p | sed 's/up //' | sed 's/ hours\?/h/' | sed 's/ minutes\?/m/' | sed 's/ days\?/d/' | sed 's/, //g')

echo "<fc=${COLOR_GRAY}>󰅐 ${UPTIME}</fc>"
