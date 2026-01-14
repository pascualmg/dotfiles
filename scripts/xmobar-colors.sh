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

# Convierte porcentaje a color gradiente RGB (0% = verde, 100% = rojo)
# Uso: color=$(pct_to_color 75)
pct_to_color() {
    local pct=${1:-0}
    local r g b

    if [ "$pct" -le 50 ]; then
        # 0-50%: Verde (#98c379) -> Amarillo (#e5c07b)
        r=$((152 + pct * 2))
        g=$((195 - pct / 10))
        b=$((121 + pct / 25))
    else
        # 50-100%: Amarillo (#e5c07b) -> Rojo (#e06c75)
        local p=$((pct - 50))
        r=$((229 - p / 10))
        g=$((192 - p * 17 / 10))
        b=$((123 - p / 10))
    fi

    [ "$r" -gt 255 ] && r=255
    [ "$g" -lt 0 ] && g=0
    printf "#%02x%02x%02x" "$r" "$g" "$b"
}

# Convierte porcentaje a color gradiente RGB invertido (0% = rojo, 100% = verde)
# Útil para: batería, señal wifi, espacio libre
# Uso: color=$(pct_to_color_inverse 75)
pct_to_color_inverse() {
    local pct=${1:-0}
    # Invertir: 100% -> 0%, 0% -> 100%
    pct_to_color $((100 - pct))
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
