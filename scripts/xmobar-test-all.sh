#!/usr/bin/env bash
# =============================================================================
# XMOBAR: Quick system status (for fish greeting)
# =============================================================================
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

# Colores
G='\033[0;32m'
C='\033[0;36m'
Y='\033[0;33m'
N='\033[0m'

# Limpiar tags xmobar
strip() { sed -E 's/<[^>]+>//g'; }

# Ejecutar monitores (rapidos, ~0.3s total)
gpu=$("$SCRIPT_DIR/xmobar-gpu.sh" 2>/dev/null | strip)
cpu=$("$SCRIPT_DIR/xmobar-cpu.sh" 2>/dev/null | strip)
mem=$("$SCRIPT_DIR/xmobar-memory.sh" 2>/dev/null | strip)
net=$("$SCRIPT_DIR/xmobar-network.sh" 2>/dev/null | strip)
disk=$("$SCRIPT_DIR/xmobar-disks.sh" 2>/dev/null | strip)
dock=$("$SCRIPT_DIR/xmobar-docker.sh" 2>/dev/null | strip)

# Output compacto una linea
out=""
[ -n "$gpu" ] && out+="${G}GPU${N}$gpu "
[ -n "$cpu" ] && out+="${G}CPU${N}$cpu "
[ -n "$mem" ] && out+="${G}MEM${N}$mem "
[ -n "$disk" ] && out+="${G}DSK${N}$disk "
[ -n "$dock" ] && out+="${Y}🐳${N}$dock "
[ -n "$net" ] && out+="${C}NET${N}$net"

echo -e "$out"
