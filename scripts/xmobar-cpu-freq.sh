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
# Calcular frecuencia promedio de todos los cores
# Metodo 1: sysfs cpufreq (Intel con intel_pstate, AMD con amd-pstate)
# Metodo 2: /proc/cpuinfo (fallback universal)

FREQ_GHZ="?.?"

# Intentar sysfs cpufreq primero
if ls /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq &>/dev/null; then
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
        # Convertir kHz a GHz con 1 decimal
        FREQ_MHZ=$((FREQ_AVG / 1000))
        FREQ_INT=$((FREQ_MHZ / 1000))
        FREQ_DEC=$(( (FREQ_MHZ % 1000) / 100 ))
        FREQ_GHZ="${FREQ_INT}.${FREQ_DEC}"
    fi
else
    # Fallback: /proc/cpuinfo (funciona en todos los sistemas)
    # Extrae "cpu MHz" y calcula promedio
    FREQ_SUM=0
    CORE_COUNT=0
    while read -r mhz; do
        # mhz viene como "1234.567", extraemos parte entera
        mhz_int=${mhz%.*}
        FREQ_SUM=$((FREQ_SUM + mhz_int))
        CORE_COUNT=$((CORE_COUNT + 1))
    done < <(grep "cpu MHz" /proc/cpuinfo | awk '{print $4}')

    if [ "$CORE_COUNT" -gt 0 ]; then
        FREQ_AVG=$((FREQ_SUM / CORE_COUNT))
        # MHz a GHz con 1 decimal
        FREQ_INT=$((FREQ_AVG / 1000))
        FREQ_DEC=$(( (FREQ_AVG % 1000) / 100 ))
        FREQ_GHZ="${FREQ_INT}.${FREQ_DEC}"
    fi
fi

# ===== GOVERNOR =====
# Si no hay cpufreq, no hay governor configurable
if [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]; then
    GOVERNOR=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)
else
    GOVERNOR="none"
fi

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
    none)
        # Sin cpufreq - mostrar solo frecuencia
        COLOR="$COLOR_GRAY"
        ICON="󰘚"  # nf-md-chip
        GOV_SHORT=""
        ;;
    *)
        COLOR="$COLOR_YELLOW"
        ICON="󰘚"  # nf-md-chip
        GOV_SHORT="$GOVERNOR"
        ;;
esac

# ===== OUTPUT =====
# Formato: icono frecuencia [governor]
if [ -n "$GOV_SHORT" ]; then
    OUTPUT="<fc=${COLOR}><fn=1>${ICON}</fn>${FREQ_GHZ}GHz ${GOV_SHORT}</fc>"
else
    OUTPUT="<fc=${COLOR}><fn=1>${ICON}</fn>${FREQ_GHZ}GHz</fc>"
fi

# Click abre cpupower-gui (si hay governor configurable)
if [ "$GOVERNOR" != "none" ]; then
    echo "<action=\`cpupower-gui\`>$OUTPUT</action>"
else
    echo "$OUTPUT"
fi
