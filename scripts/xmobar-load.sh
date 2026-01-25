#!/usr/bin/env bash
# Load Average Monitor
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/xmobar-colors.sh"

LOAD1=$(cat /proc/loadavg | awk '{print $1}')
LOAD5=$(cat /proc/loadavg | awk '{print $2}')
CORES=$(nproc)

# Color según carga (load > cores = malo)
LOAD_PCT=$(echo "$LOAD1 $CORES" | awk '{printf "%d", ($1/$2)*100}')
if [ "$LOAD_PCT" -gt 100 ]; then
    COLOR="$COLOR_RED"
elif [ "$LOAD_PCT" -gt 70 ]; then
    COLOR="$COLOR_YELLOW"
else
    COLOR="$COLOR_GREEN"
fi

echo "<fc=${COLOR}>󰊚 ${LOAD1}</fc>"
