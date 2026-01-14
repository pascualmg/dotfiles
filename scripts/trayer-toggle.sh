#!/usr/bin/env bash
# Toggle trayer - show/hide systray

if pgrep -x trayer > /dev/null; then
    # Trayer corriendo -> matar
    killall trayer
else
    # Trayer no corriendo -> lanzar (abajo derecha)
    trayer --edge bottom --align right \
           --widthtype request --padding 6 \
           --SetDockType true --SetPartialStrut false \
           --expand true --monitor 0 \
           --transparent true --alpha 0 --tint 0x282c34 \
           --height 28 &
fi
