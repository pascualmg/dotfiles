#!/usr/bin/env bash
# Volume monitor for xmobar - icono y nivel con color gradiente

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/xmobar-colors.sh"

# Obtener volumen y estado mute
VOL_INFO=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -oP '\d+%' | head -1 | tr -d '%')
MUTE=$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | grep -oP 'yes|no')

if [ -z "$VOL_INFO" ]; then
    echo "<fc=$COLOR_GRAY><fn=1>󰖁</fn></fc>N/A"
    exit 0
fi

# Icono según estado
if [ "$MUTE" = "yes" ]; then
    ICON="󰖁"
    COLOR="$COLOR_GRAY"
else
    ICON="󰕾"
    COLOR=$(pct_to_color_inverse "$VOL_INFO")
fi

# Padding a 2 dígitos (o 3 si puede ser >99)
VOL_PAD=$(printf "%02d" "$VOL_INFO")
# Click abre pavucontrol
echo "<action=\`pavucontrol\`><fc=${COLOR}><fn=1>${ICON}</fn>${VOL_PAD}%</fc></action>"
