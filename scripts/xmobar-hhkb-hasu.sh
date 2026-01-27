#!/usr/bin/env bash
# =============================================================================
# XMOBAR: HHKB Pro with Hasu Controller Monitor
# =============================================================================
# Monitoriza el HHKB Pro con Hasu USB/BT controller.
# Muestra estado de conexión con icono especial.
#
# Features:
# - Detecta HHKB Pro con Hasu (USB ID 4848:0001)
# - Muestra icono cyan brillante cuando está conectado
# - Muestra info de las 5 interfaces HID al hacer click
# - Distingue entre HHKB Pro (Hasu) y HHKB Hybrid (nativo BT)
#
# El HHKB con Hasu expone 5 interfaces HID:
# - input7: HHKB ANSI (teclado principal)
# - input8: HHKB ANSI Mouse (mouse emulado - layer MOUSE con hold ;)
# - input9: HHKB ANSI System Control (power/sleep/wake)
# - input10: HHKB ANSI Consumer Control (media keys - Fn+media)
# - input11: HHKB ANSI Keyboard (teclado secundario para layers)
#
# Filosofía Hasu: "El teclado es inteligente. Lo conectas y funciona."
# =============================================================================

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/xmobar-colors.sh"

# Colores especiales para HHKB
HHKB_CYAN="#8be9fd" # Cyan brillante (Hasu conectado)
HHKB_GRAY="#444444" # Gris (desconectado)

# Buscar HHKB con Hasu controller (USB ID 4848:0001)
if ! lsusb | grep -q "4848:0001"; then
	# No conectado
	echo "<fc=${HHKB_GRAY}><fn=1>⌨</fn></fc>"
	exit 0
fi

# HHKB Pro con Hasu conectado
# Buscar número de input del teclado principal
KEYBOARD_INPUT=$(grep -l "HHKB ANSI" /sys/class/input/input*/name 2>/dev/null | grep -v "Mouse\|System\|Consumer\|Keyboard" | head -1)

if [ -n "$KEYBOARD_INPUT" ]; then
	INPUT_NUM=$(echo "$KEYBOARD_INPUT" | grep -oP 'input\K[0-9]+')
	# Mostrar con número de input para debug
	echo "<action=\`notify-send 'HHKB Pro (Hasu)' '⌨ Happy Hacking Keyboard Professional\n\n🔌 USB: 4848:0001 (Hasu Controller)\n📍 Input: input${INPUT_NUM}\n\n5 Interfaces HID:\n  • Keyboard (input7) - Main\n  • Mouse Layer (input8) - hold ;\n  • System Control (input9) - Power\n  • Consumer (input10) - Media keys\n  • Keyboard 2 (input11) - Layers\n\n💡 Filosofía Hasu:\n   \"El teclado es inteligente.\n    Lo conectas y funciona.\"\n\n🎨 Keymap: ultimate (5 layers)\n   Base / Fn / Mouse / VI / SpaceFN'\`><fc=${HHKB_CYAN}><fn=1>⌨</fn>Pro</fc></action>"
else
	# Conectado pero sin info detallada
	echo "<action=\`notify-send 'HHKB' 'Pro con Hasu conectado'\`><fc=${HHKB_CYAN}><fn=1>⌨</fn>Pro</fc></action>"
fi
