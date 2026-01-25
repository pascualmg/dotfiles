#!/usr/bin/env bash
# =============================================================================
# XMOBAR: Docker Monitor
# =============================================================================
# Muestra contenedores corriendo. Si docker no esta o no hay containers, nada.
# =============================================================================

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/xmobar-colors.sh"

# Si docker no existe o no responde, no mostrar nada
command -v docker &>/dev/null || exit 0
docker info &>/dev/null || exit 0

# Contar contenedores corriendo
COUNT=$(docker ps -q 2>/dev/null | wc -l)

# Si no hay contenedores, no mostrar nada
[ "$COUNT" -eq 0 ] && exit 0

COUNT_PAD=$(printf "%02d" "$COUNT")

# Click abre lazydocker
echo "<action=\`alacritty -e lazydocker\`><fc=${COLOR_CYAN}><fn=1>󰡨</fn>${COUNT_PAD}</fc></action>"
