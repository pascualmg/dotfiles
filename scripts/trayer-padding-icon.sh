#!/usr/bin/env bash
# Trayer padding script for xmobar
# Outputs spaces to make room for trayer icons

# Get width of trayer window
trayer_width=$(xprop -name panel 2>/dev/null | grep 'program specified minimum size' | cut -d ' ' -f 5)

if [ -z "$trayer_width" ]; then
    # Trayer not running or no icons
    echo ""
    exit 0
fi

# Calculate padding (approx 8px per space character)
padding=$((trayer_width / 8))

# Output spaces
printf '%*s' "$padding" ""
