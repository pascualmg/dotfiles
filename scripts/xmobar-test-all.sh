#!/usr/bin/env bash
# =============================================================================
# XMOBAR: Quick system status (for fish greeting)
# =============================================================================
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

# Convertir colores xmobar hex a ANSI truecolor
hex_to_ansi() {
    perl -pe '
        # Primero eliminar tags <fn>, <action> que estan anidados dentro de <fc>
        s/<fn=[0-9]+>//g;
        s/<\/fn>//g;
        s/<action=[^>]*>//g;
        s/<\/action>//g;
        # Ahora convertir colores (ya no hay tags anidados)
        s/<fc=#([0-9a-fA-F]{2})([0-9a-fA-F]{2})([0-9a-fA-F]{2})>([^<]*)<\/fc>/chr(27)."[38;2;".hex($1).";".hex($2).";".hex($3)."m".$4.chr(27)."[0m"/ge;
    '
}

# Ejecutar TODOS los monitores (timeout 1s para evitar cuelgues)
# Monitores que solo muestran si aplica (smart monitors)
vpn=$(timeout 1s "$SCRIPT_DIR/xmobar-vpn.sh" 2>/dev/null | hex_to_ansi)
dock=$(timeout 1s "$SCRIPT_DIR/xmobar-docker.sh" 2>/dev/null | hex_to_ansi)
updates=$(timeout 1s "$SCRIPT_DIR/xmobar-updates.sh" 2>/dev/null | hex_to_ansi)
machines=$(timeout 3s "$SCRIPT_DIR/xmobar-machines.sh" 2>/dev/null | hex_to_ansi)
ssh_mon=$(timeout 1s "$SCRIPT_DIR/xmobar-ssh.sh" 2>/dev/null | hex_to_ansi)
bt=$(timeout 1s "$SCRIPT_DIR/xmobar-bluetooth.sh" 2>/dev/null | hex_to_ansi)
vol=$(timeout 1s "$SCRIPT_DIR/xmobar-volume.sh" 2>/dev/null | hex_to_ansi)
bright=$(timeout 1s "$SCRIPT_DIR/xmobar-brightness.sh" 2>/dev/null | hex_to_ansi)
bat=$(timeout 1s "$SCRIPT_DIR/xmobar-battery.sh" 2>/dev/null | hex_to_ansi)
hhkb=$(timeout 1s "$SCRIPT_DIR/xmobar-hhkb-battery.sh" 2>/dev/null | hex_to_ansi)
mouse=$(timeout 1s "$SCRIPT_DIR/xmobar-mouse-battery.sh" 2>/dev/null | hex_to_ansi)
wifi=$(timeout 1s "$SCRIPT_DIR/xmobar-wifi.sh" 2>/dev/null | hex_to_ansi)
net=$(timeout 1s "$SCRIPT_DIR/xmobar-network.sh" 2>/dev/null | hex_to_ansi)
disk=$(timeout 1s "$SCRIPT_DIR/xmobar-disks.sh" 2>/dev/null | hex_to_ansi)
gpu=$(timeout 1s "$SCRIPT_DIR/xmobar-gpu.sh" 2>/dev/null | hex_to_ansi)
swap=$(timeout 1s "$SCRIPT_DIR/xmobar-swap.sh" 2>/dev/null | hex_to_ansi)
mem=$(timeout 1s "$SCRIPT_DIR/xmobar-memory.sh" 2>/dev/null | hex_to_ansi)
load=$(timeout 1s "$SCRIPT_DIR/xmobar-load.sh" 2>/dev/null | hex_to_ansi)
freq=$(timeout 1s "$SCRIPT_DIR/xmobar-cpu-freq.sh" 2>/dev/null | hex_to_ansi)
cpu=$(timeout 1s "$SCRIPT_DIR/xmobar-cpu.sh" 2>/dev/null | hex_to_ansi)
uptime=$(timeout 1s "$SCRIPT_DIR/xmobar-uptime.sh" 2>/dev/null | hex_to_ansi)

# Output (orden: estado > red > dispositivos > hardware)
out=""
[ -n "$vpn" ] && out+="$vpn  "
[ -n "$dock" ] && out+="$dock  "
[ -n "$updates" ] && out+="$updates  "
[ -n "$machines" ] && out+="$machines  "
[ -n "$ssh_mon" ] && out+="$ssh_mon  "
[ -n "$bt" ] && out+="$bt  "
[ -n "$vol" ] && out+="$vol  "
[ -n "$bright" ] && out+="$bright  "
[ -n "$bat" ] && out+="$bat  "
[ -n "$hhkb" ] && out+="$hhkb  "
[ -n "$mouse" ] && out+="$mouse  "
[ -n "$wifi" ] && out+="$wifi  "
[ -n "$net" ] && out+="$net  "
[ -n "$disk" ] && out+="$disk  "
[ -n "$gpu" ] && out+="$gpu  "
[ -n "$swap" ] && out+="$swap  "
[ -n "$mem" ] && out+="$mem  "
[ -n "$load" ] && out+="$load  "
[ -n "$freq" ] && out+="$freq  "
[ -n "$cpu" ] && out+="$cpu  "
[ -n "$uptime" ] && out+="$uptime"

echo -e "$out"
