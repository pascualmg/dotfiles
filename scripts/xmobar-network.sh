#!/usr/bin/env bash
# Network monitor for xmobar - auto-detecta interfaces y muestra tráfico en tiempo real
# Formato: icono pct% ↓DOWN ↑UP (IP)
# Si desconectado, no muestra nada

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/xmobar-colors.sh"

# Directorios de cache (un archivo por interfaz)
CACHE_DIR="/tmp/xmobar-network"
mkdir -p "$CACHE_DIR"

# Función para formatear bytes/s a KB/s o MB/s
format_rate() {
	local bytes=$1
	if [ "$bytes" -ge 1048576 ]; then
		# MB/s (si >= 1MB)
		printf "%.1fM" "$(echo "scale=1; $bytes / 1048576" | bc)"
	elif [ "$bytes" -ge 1024 ]; then
		# KB/s (si >= 1KB)
		printf "%dK" "$((bytes / 1024))"
	else
		# B/s (si < 1KB)
		printf "%dB" "$bytes"
	fi
}

# Función para obtener color según tasa (bytes/s)
rate_to_color() {
	local bytes=$1
	local mb=$((bytes / 1048576))

	if [ "$mb" -ge 50 ]; then
		echo "$COLOR_RED" # >50MB/s = rojo (saturado)
	elif [ "$mb" -ge 20 ]; then
		echo "$COLOR_ORANGE" # 20-50MB/s = naranja
	elif [ "$mb" -ge 5 ]; then
		echo "$COLOR_YELLOW" # 5-20MB/s = amarillo
	else
		echo "$COLOR_GREEN" # <5MB/s = verde
	fi
}

output=""

# Obtener interfaces activas (excluir lo, docker, veth, br, virbr, tun, vnet)
interfaces=$(ip -o link show up | awk -F': ' '{print $2}' | grep -vE '^(lo|docker|veth|br|virbr|tun|vnet)')

for iface in $interfaces; do
	# Obtener IP - si no hay IP, skip (no mostrar)
	ip_addr=$(ip -4 addr show "$iface" 2>/dev/null | grep -oP 'inet \K[\d.]+' | head -1)
	[ -z "$ip_addr" ] && continue

	# Leer stats actuales
	rx_bytes=$(cat "/sys/class/net/$iface/statistics/rx_bytes" 2>/dev/null | tr -d '[:space:]')
	tx_bytes=$(cat "/sys/class/net/$iface/statistics/tx_bytes" 2>/dev/null | tr -d '[:space:]')
	current_time=$(date +%s%3N) # Milisegundos para mayor precisión

	# Validar que son números válidos
	[[ ! "$rx_bytes" =~ ^[0-9]+$ ]] && rx_bytes=0
	[[ ! "$tx_bytes" =~ ^[0-9]+$ ]] && tx_bytes=0

	# Archivo de cache específico para esta interfaz
	cache_file="$CACHE_DIR/$iface"

	# Leer stats previas
	if [ -f "$cache_file" ]; then
		read -r prev_rx prev_tx prev_time <"$cache_file"

		# Validar prev_* son números
		[[ ! "$prev_rx" =~ ^[0-9]+$ ]] && prev_rx="$rx_bytes"
		[[ ! "$prev_tx" =~ ^[0-9]+$ ]] && prev_tx="$tx_bytes"
		[[ ! "$prev_time" =~ ^[0-9]+$ ]] && prev_time="$current_time"

		# Calcular delta en milisegundos
		time_diff_ms=$(echo "$current_time - $prev_time" | bc 2>/dev/null || echo 0)

		if [ "$time_diff_ms" -gt 0 ]; then
			# Calcular bytes transferidos
			rx_diff=$(echo "$rx_bytes - $prev_rx" | bc 2>/dev/null || echo 0)
			tx_diff=$(echo "$tx_bytes - $prev_tx" | bc 2>/dev/null || echo 0)

			# Solo calcular rate si diff es positivo (evitar counter reset)
			if [ "${rx_diff:0:1}" != "-" ] && [ "${tx_diff:0:1}" != "-" ]; then
				# Convertir a bytes/s (dividir por segundos)
				time_diff_s=$(echo "scale=3; $time_diff_ms / 1000" | bc)
				rx_rate=$(echo "scale=0; $rx_diff / $time_diff_s" | bc 2>/dev/null || echo 0)
				tx_rate=$(echo "scale=0; $tx_diff / $time_diff_s" | bc 2>/dev/null || echo 0)
			else
				rx_rate=0
				tx_rate=0
			fi
		else
			rx_rate=0
			tx_rate=0
		fi
	else
		rx_rate=0
		tx_rate=0
	fi

	# Guardar estado actual para próxima ejecución
	echo "$rx_bytes $tx_bytes $current_time" >"$cache_file"

	# Formatear tasas
	rx_formatted=$(format_rate "$rx_rate")
	tx_formatted=$(format_rate "$tx_rate")

	# Colores según tasa
	rx_color=$(rate_to_color "$rx_rate")
	tx_color=$(rate_to_color "$tx_rate")

	# Determinar tipo de interfaz e ícono
	HACKER_GREEN="#00ff00"
	if [[ "$iface" == wl* ]] || [[ "$iface" == wlan* ]]; then
		# WiFi - señal con gradiente
		signal=$(awk 'NR==3 {printf "%.0f", $3}' /proc/net/wireless 2>/dev/null)
		if [ -n "$signal" ]; then
			sig_color=$(pct_to_color_inverse "$signal")
			SIG_PAD=$(printf "%02d" "$signal")
			output+="<action=\`nm-connection-editor\`>"
			output+="<fc=${sig_color}><fn=1>󰖩</fn>${SIG_PAD}%</fc> "
			output+="<fc=${rx_color}>󰁞${rx_formatted}</fc> "
			output+="<fc=${tx_color}>󰁆${tx_formatted}</fc> "
			output+="<fc=${HACKER_GREEN}>(${ip_addr})</fc>"
			output+="</action> "
		else
			output+="<action=\`nm-connection-editor\`>"
			output+="<fc=${HACKER_GREEN}><fn=1>󰖩</fn></fc> "
			output+="<fc=${rx_color}>󰁞${rx_formatted}</fc> "
			output+="<fc=${tx_color}>󰁆${tx_formatted}</fc> "
			output+="<fc=${HACKER_GREEN}>(${ip_addr})</fc>"
			output+="</action> "
		fi
	elif [[ "$iface" == en* ]] || [[ "$iface" == eth* ]]; then
		# Ethernet
		output+="<action=\`nm-connection-editor\`>"
		output+="<fc=${HACKER_GREEN}><fn=1>󰈀</fn></fc> "
		output+="<fc=${rx_color}>󰁞${rx_formatted}</fc> "
		output+="<fc=${tx_color}>󰁆${tx_formatted}</fc> "
		output+="<fc=${HACKER_GREEN}>(${ip_addr})</fc>"
		output+="</action> "
	fi
done

# Quitar espacio final (si no hay nada, no muestra nada)
echo "${output% }"
