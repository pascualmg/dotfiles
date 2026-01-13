#!/usr/bin/env bash
# =============================================================================
# Bootstrap Doom Emacs
# =============================================================================
# Instala Doom Emacs y clona la configuración personal.
# Ejecutar en una máquina nueva después de nixos-rebuild.
#
# Uso: ./bootstrap-doom.sh
# =============================================================================

set -e

DOOM_EMACS_DIR="$HOME/.config/emacs"
DOOM_CONFIG_DIR="$HOME/.config/doom"
DOOM_CONFIG_REPO="git@github.com:pascualmg/doom.git"

echo "=== Bootstrap Doom Emacs ==="
echo ""

# 1. Instalar Doom Emacs framework
if [ -d "$DOOM_EMACS_DIR" ]; then
    echo "[OK] Doom Emacs ya instalado en $DOOM_EMACS_DIR"
else
    echo "[*] Clonando Doom Emacs..."
    git clone --depth 1 https://github.com/doomemacs/doomemacs "$DOOM_EMACS_DIR"
fi

# 2. Clonar configuración personal
if [ -d "$DOOM_CONFIG_DIR" ]; then
    echo "[OK] Config personal ya existe en $DOOM_CONFIG_DIR"
else
    echo "[*] Clonando configuración personal..."
    git clone "$DOOM_CONFIG_REPO" "$DOOM_CONFIG_DIR"
fi

# 3. Instalar Doom
echo ""
echo "[*] Ejecutando doom install..."
"$DOOM_EMACS_DIR/bin/doom" install

echo ""
echo "=== Bootstrap completado ==="
echo ""
echo "Comandos útiles:"
echo "  doom sync     - Sincronizar después de cambios en packages.el"
echo "  doom upgrade  - Actualizar Doom y paquetes"
echo "  doom doctor   - Diagnosticar problemas"
echo "  doom build    - Recompilar"
