#!/usr/bin/env bash
# =============================================================================
# XMOBAR: Test all monitors
# =============================================================================
# Ejecuta todos los monitores y muestra el resultado en consola.
# Util para debugging y ver que esta mostrando cada monitor.
#
# Uso: xmobar-test-all.sh [--raw]
#   --raw: muestra output sin procesar (con tags xmobar)
#   sin args: muestra tabla formateada
# =============================================================================

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

# Monitores en uso en xmobar-full.hs
MONITORS_ACTIVE=(
    "gpu"
    "cpu"
    "cpu-freq"
    "memory"
    "network"
    "disks"
    "docker"
    "volume"
    "battery"
)

# Monitores disponibles pero NO en xmobar actualmente
MONITORS_AVAILABLE=(
    "wifi"
    "hhkb-battery"
)

# Todos los monitores
MONITORS=("${MONITORS_ACTIVE[@]}" "${MONITORS_AVAILABLE[@]}")

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Funcion para limpiar tags xmobar y mostrar texto plano
strip_xmobar_tags() {
    # Quitar <action>...</action>, <fc>...</fc>, <fn>...</fn>
    sed -E 's/<action=[^>]*>//g; s/<\/action>//g; s/<fc=[^>]*>//g; s/<\/fc>//g; s/<fn=[0-9]+>//g; s/<\/fn>//g'
}

# Funcion para ejecutar y mostrar monitor
run_monitor() {
    local monitor="$1"
    local script="${SCRIPT_DIR}/xmobar-${monitor}.sh"

    if [ -x "$script" ]; then
        output=$(timeout 5s "$script" 2>/dev/null)

        if [ -n "$output" ]; then
            if [ "$1" = "--raw" ]; then
                printf "${GREEN}%-15s${NC} %s\n" "$monitor:" "$output"
            else
                clean=$(echo "$output" | strip_xmobar_tags)
                printf "${GREEN}%-15s${NC} %s\n" "$monitor:" "$clean"
            fi
        else
            printf "${YELLOW}%-15s${NC} %s\n" "$monitor:" "(N/A)"
        fi
    else
        printf "${RED}%-15s${NC} %s\n" "$monitor:" "(not found)"
    fi
}

# Header
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  XMOBAR MONITORS TEST - $(hostname)${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"

# Monitores activos
echo ""
echo -e "${GREEN}▶ ACTIVOS EN XMOBAR${NC}"
echo -e "${CYAN}───────────────────────────────────────────────────────────────${NC}"
for monitor in "${MONITORS_ACTIVE[@]}"; do
    run_monitor "$monitor"
done

# Monitores disponibles
echo ""
echo -e "${YELLOW}▶ DISPONIBLES (no en xmobar)${NC}"
echo -e "${CYAN}───────────────────────────────────────────────────────────────${NC}"
for monitor in "${MONITORS_AVAILABLE[@]}"; do
    run_monitor "$monitor"
done

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "  Use ${YELLOW}--raw${NC} to see xmobar tags"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
