#!/usr/bin/env bash
# =============================================================================
# CPU Frequency & Governor monitor for xmobar
# =============================================================================
# Muestra frecuencia promedio y governor actual
# Click: abre cpupower-gui para cambiar governor al vuelo
# =============================================================================

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/xmobar-colors.sh"

# ===== FRECUENCIA CPU =====
# Calcular frecuencia promedio de todos los cores (en MHz)
FREQ_SUM=0
CORE_COUNT=0
for freq_file in /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq; do
    [ -f "$freq_file" ] || continue
    freq=$(cat "$freq_file" 2>/dev/null)
    FREQ_SUM=$((FREQ_SUM + freq))
    CORE_COUNT=$((CORE_COUNT + 1))
done

if [ "$CORE_COUNT" -gt 0 ]; then
    FREQ_AVG=$((FREQ_SUM / CORE_COUNT))
    # Convertir a GHz con 1 decimal (sin bc)
    FREQ_MHZ=$((FREQ_AVG / 1000))
    FREQ_INT=$((FREQ_MHZ / 1000))
    FREQ_DEC=$(( (FREQ_MHZ % 1000) / 100 ))
    FREQ_GHZ="${FREQ_INT}.${FREQ_DEC}"
else
    FREQ_GHZ="?.?"
fi

# ===== GOVERNOR =====
GOVERNOR=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "unknown")

# ===== COLOR según governor =====
case "$GOVERNOR" in
    performance)
        COLOR="$COLOR_RED"
        ICON="󰓅"  # nf-md-speedometer
        GOV_SHORT="perf"
        ;;
    powersave)
        COLOR="$COLOR_GREEN"
        ICON="󰌪"  # nf-md-leaf
        GOV_SHORT="save"
        ;;
    schedutil|ondemand)
        COLOR="$COLOR_CYAN"
        ICON="󰾅"  # nf-md-auto_fix
        GOV_SHORT="auto"
        ;;
    conservative)
        COLOR="$COLOR_BLUE"
        ICON="󰒲"  # nf-md-sleep
        GOV_SHORT="cons"
        ;;
    *)
        COLOR="$COLOR_YELLOW"
        ICON="󰘚"  # nf-md-chip
        GOV_SHORT="$GOVERNOR"
        ;;
esac

# ===== OUTPUT =====
# Formato: icono frecuencia governor
OUTPUT="<fc=${COLOR}><fn=1>${ICON}</fn>${FREQ_GHZ}GHz ${GOV_SHORT}</fc>"

# Click abre cpupower-gui
echo "<action=\`cpupower-gui\`>$OUTPUT</action>"
