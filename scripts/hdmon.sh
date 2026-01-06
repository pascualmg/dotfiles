#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nvme-cli
# -*- mode: sh -*-
#
# NVMe disk monitor for xmobar
# Shows: Temperature, Used% with bar, Hours, Total Written

# Caracter único que representa el nivel (8 niveles)
# Uso: level_char porcentaje
level_char() {
    local pct=$1
    # Bloques verticales Unicode: ▁▂▃▄▅▆▇█
    local chars=("▁" "▂" "▃" "▄" "▅" "▆" "▇" "█")
    local idx=$((pct * 8 / 100))
    [ "$idx" -ge 8 ] && idx=7
    echo "${chars[$idx]}"
}

# Color según porcentaje (para xmobar)
color_by_pct() {
    local pct=$1
    if [ "$pct" -lt 60 ]; then
        echo "#67b11d"  # Verde
    elif [ "$pct" -lt 80 ]; then
        echo "#b1951d"  # Amarillo
    else
        echo "#f2241f"  # Rojo
    fi
}

output=""

for drive in /dev/nvme?n?; do
    if [ -e "$drive" ]; then
        smart_info=$(sudo nvme smart-log "$drive" 2>/dev/null)
        [ -z "$smart_info" ] && continue

        # Reset variables para cada disco
        used_pct=""
        used_size=""
        total_size=""
        disk_info=""

        # Temperatura
        temp=$(echo "$smart_info" | grep "temperature" | head -n1 | cut -f2 -d: | tr -d ' ' | cut -d'(' -f1 | tr -d '°C')

        # Espacio usado en disco (buscar partición montada)
        for part in "${drive}p2" "${drive}p1"; do
            disk_info=$(df -h "$part" 2>/dev/null | tail -n1)
            # Verificar que es una partición real montada (empieza con /dev/)
            if [ -n "$disk_info" ] && [[ "$disk_info" == /dev/* ]]; then
                used_pct=$(echo "$disk_info" | awk '{print $5}' | tr -d '%')
                used_size=$(echo "$disk_info" | awk '{print $3}')
                total_size=$(echo "$disk_info" | awk '{print $2}')
                break
            fi
        done

        # Si no hay partición montada, skip este disco
        [ -z "$used_pct" ] && continue

        # Horas encendido
        hours=$(echo "$smart_info" | grep "power_on_hours" | cut -f2 -d: | tr -d ' ')

        # Datos escritos en vida del disco
        written=$(echo "$smart_info" | grep "Data Units Written" | cut -f2 -d: | tr -d ' ')
        written_tb=$(echo "$written" | cut -d'(' -f2 | cut -d')' -f1 | awk '{print $1}')

        level=$(level_char "$used_pct")
        color=$(color_by_pct "$used_pct")

        # Formato: (usado/total) 🌡temp ⏱horas ✍escrito pct% 💾[barra]
        output+="(${used_size}/${total_size}) 🌡${temp}C ⏱${hours}h ✍${written_tb} ${used_pct}%💾<fc=${color}>${level}</fc> "
    fi
done

# Quitar espacio final y mostrar
echo "${output% }"
