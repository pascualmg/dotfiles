#!/usr/bin/env bash
# Battery monitor for xmobar - icono y carga con color dinámico

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/xmobar-colors.sh"

# Leer batería
BAT_PATH="/sys/class/power_supply/BAT0"
[ ! -d "$BAT_PATH" ] && BAT_PATH="/sys/class/power_supply/BAT1"
[ ! -d "$BAT_PATH" ] && { echo "<fc=$COLOR_GRAY><fn=1>󰂃</fn></fc>N/A"; exit 0; }

CAPACITY=$(cat "$BAT_PATH/capacity" 2>/dev/null || echo "0")
STATUS=$(cat "$BAT_PATH/status" 2>/dev/null || echo "Unknown")

# Icono según estado
case "$STATUS" in
    Charging)    ICON="󰂄" ;;
    Discharging) ICON="󰁿" ;;
    Full)        ICON="󰁹" ;;
    *)           ICON="󰂃" ;;
esac

# Color inverso (100% = bueno = verde)
COLOR=$(pct_to_color_inverse "$CAPACITY")
# Padding a 2 dígitos
CAP_PAD=$(printf "%02d" "$CAPACITY")
echo "<fc=${COLOR}><fn=1>${ICON}</fn></fc>${CAP_PAD}%"
