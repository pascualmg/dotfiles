#!/usr/bin/env bash
# Lanza glmatrix como fondo de pantalla
# Encuentra el path dinámicamente para sobrevivir updates de NixOS

GLMATRIX=$(dirname $(readlink -f $(which xscreensaver-command)))/../libexec/xscreensaver/glmatrix

if [ -x "$GLMATRIX" ]; then
    # Mata instancia anterior si existe
    pkill -f "xwinwrap.*glmatrix" 2>/dev/null
    sleep 0.2
    # Lanza glmatrix con xwinwrap
    xwinwrap -ov -fs -- "$GLMATRIX" -window-id WID --speed 1 --density 50 --mode matrix --fog --texture --delay 10000 &
else
    notify-send "glmatrix no encontrado" "$GLMATRIX"
fi
