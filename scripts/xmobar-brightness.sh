#!/usr/bin/env bash
# Screen Brightness Monitor
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/xmobar-colors.sh"

# Usar brightnessctl
BRIGHTNESS=$(brightnessctl -m 2>/dev/null | cut -d',' -f4 | tr -d '%')

if [ -z "$BRIGHTNESS" ]; then
	echo "<fc=#444444><fn=1>󰃞</fn></fc>"
	exit 0
fi

# Color según brillo
if [ "$BRIGHTNESS" -gt 70 ]; then
	ICON="󰃠"
	COLOR="$COLOR_YELLOW"
elif [ "$BRIGHTNESS" -gt 30 ]; then
	ICON="󰃟"
	COLOR="$COLOR_GREEN"
else
	ICON="󰃞"
	COLOR="$COLOR_GRAY"
fi

echo "<fc=${COLOR}>${ICON} ${BRIGHTNESS}%</fc>"
