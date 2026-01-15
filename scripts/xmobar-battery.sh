#!/usr/bin/env bash
# Battery monitor for xmobar - icono y carga con color dinámico

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/xmobar-colors.sh"

# Leer batería
BAT_PATH="/sys/class/power_supply/BAT0"
[ ! -d "$BAT_PATH" ] && BAT_PATH="/sys/class/power_supply/BAT1"
[ ! -d "$BAT_PATH" ] && { echo "<fc=$COLOR_GRAY><fn=1>󰂃</fn></fc>N/A"; exit 0; }

# Calcular carga REAL (no battery health)
# charge_now/charge_full = carga actual real
# capacity = charge_now/charge_full_design = battery health (incorrecto para mostrar)
CHARGE_NOW=$(cat "$BAT_PATH/charge_now" 2>/dev/null)
CHARGE_FULL=$(cat "$BAT_PATH/charge_full" 2>/dev/null)

if [ -n "$CHARGE_NOW" ] && [ -n "$CHARGE_FULL" ] && [ "$CHARGE_FULL" -gt 0 ]; then
    CAPACITY=$((CHARGE_NOW * 100 / CHARGE_FULL))
    # Cap at 100%
    [ "$CAPACITY" -gt 100 ] && CAPACITY=100
else
    # Fallback a capacity si no hay charge_now/charge_full
    CAPACITY=$(cat "$BAT_PATH/capacity" 2>/dev/null || echo "0")
fi

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
# Click abre gnome-power-statistics o power settings
echo "<action=\`gnome-control-center power\`><fc=${COLOR}><fn=1>${ICON}</fn>${CAP_PAD}%</fc></action>"
