#!/usr/bin/env bash
# Sincroniza wallpapers desde GitHub
# Uso: sync-wallpapers.sh

REPO="https://github.com/pascualmg/wallpapers.git"
DEST="$HOME/wallpapers"

if [ -d "$DEST/.git" ]; then
    echo "Actualizando wallpapers..."
    git -C "$DEST" pull --ff-only
else
    echo "Clonando wallpapers..."
    git clone "$REPO" "$DEST"
fi

echo "Wallpapers sincronizados: $(find "$DEST" -type f \( -name '*.jpg' -o -name '*.png' -o -name '*.webp' \) | wc -l) imagenes"
