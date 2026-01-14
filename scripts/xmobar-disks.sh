#!/usr/bin/env bash
# -*- mode: sh -*-
#
# Generic disk monitor for xmobar
# Supports: NVMe, SATA SSDs, HDDs, USB drives
# Shows: Used/Total, Temperature (if available), visual bar
#
# Dependencies: smartmontools (smartctl), coreutils (df, lsblk)

# Caracter único que representa el nivel (8 niveles)
level_char() {
    local pct=$1
    local chars=("▁" "▂" "▃" "▄" "▅" "▆" "▇" "█")
    local idx=$((pct * 8 / 100))
    [ "$idx" -ge 8 ] && idx=7
    echo "${chars[$idx]}"
}

# Color gradiente RGB según porcentaje (verde -> amarillo -> rojo)
color_by_pct() {
    local pct=$1
    local r g b

    if [ "$pct" -le 50 ]; then
        # 0-50%: Verde (#98c379) -> Amarillo (#e5c07b)
        r=$((152 + pct * 2))        # 152 -> 252
        g=$((195 - pct / 10))       # 195 -> 190
        b=$((121 + pct / 25))       # 121 -> 123
    else
        # 50-100%: Amarillo (#e5c07b) -> Rojo (#e06c75)
        local p=$((pct - 50))
        r=$((229 - p / 10))         # 229 -> 224
        g=$((192 - p * 17 / 10))    # 192 -> 107
        b=$((123 - p / 10))         # 123 -> 118
    fi

    # Clamp values
    [ "$r" -gt 255 ] && r=255
    [ "$g" -lt 0 ] && g=0

    printf "#%02x%02x%02x" "$r" "$g" "$b"
}

output=""

# Obtener lista de discos físicos (excluir loop, ram, etc)
disks=$(lsblk -dno NAME,TYPE 2>/dev/null | awk '$2=="disk" {print $1}')

for disk in $disks; do
    device="/dev/$disk"

    # Verificar que el dispositivo existe
    [ ! -b "$device" ] && continue

    # Buscar la partición más relevante de este disco
    # Prioridad: / (root) > /home > otras montadas > boot
    used_pct=""
    used_size=""
    total_size=""
    mount_point=""
    best_priority=999

    # Buscar particiones montadas (p1, p2 para NVMe; 1, 2 para SATA)
    for suffix in "p1" "p2" "p3" "p4" "1" "2" "3" "4" ""; do
        part="${device}${suffix}"
        [ ! -b "$part" ] && continue

        disk_info=$(df -h "$part" 2>/dev/null | tail -n1)
        # Verificar que está montada (empieza con /dev/)
        if [ -n "$disk_info" ] && [[ "$disk_info" == /dev/* ]]; then
            mp=$(echo "$disk_info" | awk '{print $6}')

            # Asignar prioridad (menor = mejor)
            priority=50
            case "$mp" in
                "/") priority=1 ;;          # Root es lo más importante
                "/home") priority=2 ;;      # Home segundo
                "/boot"*) priority=90 ;;    # Boot último (generalmente pequeño)
                "/nix"*) priority=80 ;;     # Nix store menos relevante
            esac

            # Si esta partición tiene mejor prioridad, usarla
            if [ "$priority" -lt "$best_priority" ]; then
                best_priority=$priority
                used_pct=$(echo "$disk_info" | awk '{print $5}' | tr -d '%')
                used_size=$(echo "$disk_info" | awk '{print $3}')
                total_size=$(echo "$disk_info" | awk '{print $2}')
                mount_point="$mp"
            fi
        fi
    done

    # Si no hay partición montada, skip
    [ -z "$used_pct" ] && continue

    # Obtener temperatura con smartctl (funciona con NVMe y SATA)
    # Intentar sin sudo primero, luego con sudo si falla
    temp=""
    smart_output=$(smartctl -A "$device" 2>/dev/null || sudo smartctl -A "$device" 2>/dev/null)

    if [ -n "$smart_output" ]; then
        # NVMe format: "Temperature:                        42 Celsius"
        # SATA format: "194 Temperature_Celsius     ...    42"
        temp=$(echo "$smart_output" | grep -i "temperature" | head -1 | grep -oE '[0-9]+' | head -1)
    fi

    # Generar salida
    level=$(level_char "$used_pct")
    color=$(color_by_pct "$used_pct")

    # Nombre corto del disco
    disk_name="$disk"
    # Para root, mostrar /
    [ "$mount_point" = "/" ] && disk_name="root"

    # Formato ultra-compacto: icono+pct (color indica nivel)
    # Icono Nerd Font: 󰋊 (disco duro)
    # Padding a 2 dígitos para evitar desplazamiento
    pct_padded=$(printf "%02d" "$used_pct")
    if [ -n "$temp" ]; then
        output+="<fc=${color}><fn=1>󰋊</fn></fc>${pct_padded}% ${temp}° "
    else
        output+="<fc=${color}><fn=1>󰋊</fn></fc>${pct_padded}% "
    fi
done

# Quitar espacio final
echo "${output% }"
