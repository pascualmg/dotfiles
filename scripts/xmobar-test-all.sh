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

# Ejecutar TODOS los monitores (con timeout para evitar cuelgues)
dock=$(timeout 1s "$SCRIPT_DIR/xmobar-docker.sh" 2>/dev/null | strip)
vol=$(timeout 1s "$SCRIPT_DIR/xmobar-volume.sh" 2>/dev/null | strip)
bat=$(timeout 1s "$SCRIPT_DIR/xmobar-battery.sh" 2>/dev/null | strip)
hhkb=$(timeout 1s "$SCRIPT_DIR/xmobar-hhkb-battery.sh" 2>/dev/null | strip)
wifi=$(timeout 1s "$SCRIPT_DIR/xmobar-wifi.sh" 2>/dev/null | strip)
net=$(timeout 1s "$SCRIPT_DIR/xmobar-network.sh" 2>/dev/null | strip)
disk=$(timeout 1s "$SCRIPT_DIR/xmobar-disks.sh" 2>/dev/null | strip)
gpu=$(timeout 1s "$SCRIPT_DIR/xmobar-gpu.sh" 2>/dev/null | strip)
mem=$(timeout 1s "$SCRIPT_DIR/xmobar-memory.sh" 2>/dev/null | strip)
freq=$(timeout 1s "$SCRIPT_DIR/xmobar-cpu-freq.sh" 2>/dev/null | strip)
cpu=$(timeout 1s "$SCRIPT_DIR/xmobar-cpu.sh" 2>/dev/null | strip)

# Output - solo iconos y valores (si N/A no aparece)
out=""
[ -n "$dock" ] && out+="$dock  "
[ -n "$vol" ] && out+="$vol  "
[ -n "$bat" ] && out+="$bat  "
[ -n "$hhkb" ] && out+="$hhkb  "
[ -n "$wifi" ] && out+="$wifi  "
[ -n "$net" ] && out+="$net  "
[ -n "$disk" ] && out+="$disk  "
[ -n "$gpu" ] && out+="$gpu  "
[ -n "$mem" ] && out+="$mem  "
[ -n "$freq" ] && out+="$freq  "
[ -n "$cpu" ] && out+="$cpu"

echo -e "$out"
