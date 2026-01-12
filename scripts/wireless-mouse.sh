#!/usr/bin/env bash
# -*- mode: sh -*-
#
# Wireless mouse battery monitor for xmobar
# Shows: Mouse icon + battery percentage
# Supports: Logitech devices via hidpp (HID++)
#
# Siempre visible:
#   - Conectado: icono color + porcentaje
#   - Desconectado: icono gris
#
# Colores (One Dark theme):
#   - Verde (#98c379): >80%
#   - Amarillo (#e5c07b): 20-80%
#   - Rojo (#e06c75): <20%
#   - Gris (#5c6370): desconectado

# Buscar bateria de dispositivo Logitech (hidpp)
BAT_PATH=$(ls /sys/class/power_supply/hidpp_battery_*/capacity 2>/dev/null | head -1)

if [[ -n "$BAT_PATH" && -f "$BAT_PATH" ]]; then
    BAT=$(cat "$BAT_PATH" 2>/dev/null)

    if [[ -n "$BAT" ]]; then
        # Determinar color segun nivel
        if [[ $BAT -gt 80 ]]; then
            COLOR="#98c379"  # Verde
        elif [[ $BAT -gt 20 ]]; then
            COLOR="#e5c07b"  # Amarillo
        else
            COLOR="#e06c75"  # Rojo
        fi
        # Icono de raton conectado (nf-md-mouse U+F037D) + porcentaje
        echo "<fc=$COLOR><fn=1>󰍽</fn> ${BAT}%</fc>"
    else
        # Archivo existe pero sin contenido
        echo "<fc=#5c6370><fn=1>󰍾</fn></fc>"
    fi
else
    # Raton no detectado (icono de raton desconectado nf-md-mouse_off U+F037E)
    echo "<fc=#5c6370><fn=1>󰍾</fn></fc>"
fi
