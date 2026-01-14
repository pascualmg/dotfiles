#!/usr/bin/env bash
# Docker containers monitor for xmobar

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/xmobar-colors.sh"

# Contar contenedores corriendo
COUNT=$(docker ps -q 2>/dev/null | wc -l)
COUNT_PAD=$(printf "%02d" "$COUNT")

# Click abre lazydocker
echo "<action=\`alacritty -e lazydocker\`><fc=${COLOR_CYAN}><fn=1>󰡨</fn>${COUNT_PAD}</fc></action>"
