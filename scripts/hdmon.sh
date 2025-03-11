#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nvme-cli
# -*- mode: sh -*-

for drive in /dev/nvme?n?; do
    if [ -e "$drive" ]; then
        smart_info=$(sudo nvme smart-log "$drive")
        
        # Obtener datos básicos
        temp=$(echo "$smart_info" | grep "temperature" | head -n1 | cut -f2 -d: | tr -d ' ' | cut -d'(' -f1 | tr -d '°C')
        pct_used=$(echo "$smart_info" | grep "percentage_used" | cut -f2 -d: | tr -d ' ' | cut -d'%' -f1)
        disk_usage=$(df -h "${drive}p2" 2>/dev/null | tail -n1 | awk '{print $5}' || echo "?")
        
        # Obtener horas de encendido y datos de escritura
        power_hours=$(echo "$smart_info" | grep "power_on_hours" | cut -f2 -d: | tr -d ' ')
        data_written=$(echo "$smart_info" | grep "Data Units Written" | cut -f2 -d: | tr -d ' ' | cut -d'(' -f2 | cut -d' ' -f1)
        
        name=$(basename "$drive")
        echo "[$name ${temp}°C ${pct_used}% ${disk_usage} ${power_hours}h ${data_written}]"
    fi
done
