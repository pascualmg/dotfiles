#!/usr/bin/env bash
# Network monitor for xmobar - auto-detecta interfaces activas
# Formato: icono pct%(ip) para wifi, icono(ip) para ethernet
# Si desconectado, no muestra nada

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/xmobar-colors.sh"

output=""

# Obtener interfaces activas (excluir lo, docker, veth, br-, virbr)
interfaces=$(ip -o link show up | awk -F': ' '{print $2}' | grep -vE '^(lo|docker|veth|br-|virbr|tun)')

for iface in $interfaces; do
    # Obtener IP - si no hay IP, skip (no mostrar)
    ip_addr=$(ip -4 addr show "$iface" 2>/dev/null | grep -oP 'inet \K[\d.]+' | head -1)
    [ -z "$ip_addr" ] && continue

    # Determinar tipo de interfaz
    # Click abre nm-connection-editor
    # IP siempre en verde hacker
    HACKER_GREEN="#00ff00"
    if [[ "$iface" == wl* ]] || [[ "$iface" == wlan* ]]; then
        # WiFi - señal con gradiente, IP en verde hacker
        signal=$(awk 'NR==3 {printf "%.0f", $3}' /proc/net/wireless 2>/dev/null)
        if [ -n "$signal" ]; then
            COLOR=$(pct_to_color_inverse "$signal")
            SIG_PAD=$(printf "%02d" "$signal")
            output+="<action=\`nm-connection-editor\`><fc=${COLOR}><fn=1>󰖩</fn>${SIG_PAD}%</fc><fc=${HACKER_GREEN}>(${ip_addr})</fc></action> "
        else
            output+="<action=\`nm-connection-editor\`><fc=${HACKER_GREEN}><fn=1>󰖩</fn>(${ip_addr})</fc></action> "
        fi
    elif [[ "$iface" == en* ]] || [[ "$iface" == eth* ]]; then
        # Ethernet - todo en verde hacker
        output+="<action=\`nm-connection-editor\`><fc=${HACKER_GREEN}><fn=1>󰈀</fn>(${ip_addr})</fc></action> "
    fi
done

# Quitar espacio final (si no hay nada, no muestra nada)
echo "${output% }"
