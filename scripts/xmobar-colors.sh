#!/usr/bin/env bash
# =============================================================================
# Funciones de color para xmobar
# =============================================================================
# Uso: source este archivo desde otros scripts de xmobar
#
# Funciones:
#   pct_to_color <pct>           - Devuelve color hex según porcentaje (0-100)
#   pct_to_color_inverse <pct>   - Igual pero invertido (100% = verde)
#   xmobar_color <color> <text>  - Envuelve texto en <fc=#color>...</fc>
#
# Colores (One Dark theme):
#   Verde:   #98c379 (bueno)
#   Amarillo: #e5c07b (warning)
#   Naranja: #d19a66 (alto)
#   Rojo:    #e06c75 (crítico)
#   Gris:    #5c6370 (inactivo)
# =============================================================================

# Colores One Dark
COLOR_GREEN="#98c379"
COLOR_YELLOW="#e5c07b"
COLOR_ORANGE="#d19a66"
COLOR_RED="#e06c75"
COLOR_GRAY="#5c6370"
COLOR_CYAN="#56b6c2"
COLOR_BLUE="#61afef"

# Convierte porcentaje a color (0% = verde, 100% = rojo)
# Uso: color=$(pct_to_color 75)
pct_to_color() {
    local pct=${1:-0}
    if [[ $pct -le 30 ]]; then
        echo "$COLOR_GREEN"
    elif [[ $pct -le 60 ]]; then
        echo "$COLOR_YELLOW"
    elif [[ $pct -le 85 ]]; then
        echo "$COLOR_ORANGE"
    else
        echo "$COLOR_RED"
    fi
}

# Convierte porcentaje a color invertido (100% = verde, 0% = rojo)
# Útil para: batería, espacio libre, etc.
# Uso: color=$(pct_to_color_inverse 75)
pct_to_color_inverse() {
    local pct=${1:-0}
    if [[ $pct -gt 80 ]]; then
        echo "$COLOR_GREEN"
    elif [[ $pct -gt 40 ]]; then
        echo "$COLOR_YELLOW"
    elif [[ $pct -gt 20 ]]; then
        echo "$COLOR_ORANGE"
    else
        echo "$COLOR_RED"
    fi
}

# Envuelve texto en formato de color xmobar
# Uso: echo $(xmobar_color "#98c379" "texto")
xmobar_color() {
    local color="$1"
    local text="$2"
    echo "<fc=${color}>${text}</fc>"
}

# Envuelve texto en font alternativa (iconos más grandes)
# Uso: echo $(xmobar_icon "󰍽")
xmobar_icon() {
    local icon="$1"
    echo "<fn=1>${icon}</fn>"
}
