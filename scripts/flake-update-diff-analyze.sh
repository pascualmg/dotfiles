#!/usr/bin/env bash
# flake-update-diff-analyze.sh - Run flake-update-diff + analyze with Ollama
# Wrapper for LLM-powered analysis of NixOS flake updates

set -euo pipefail

# Config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIFF_SCRIPT="$SCRIPT_DIR/flake-update-diff.sh"
OLLAMA_MODEL="${OLLAMA_MODEL:-devstral-small-2:latest}"

# Colors
RESET='\033[0m'
BOLD='\033[1m'
CYAN='\033[0;36m'

# Check if ollama is available
if ! command -v ollama &>/dev/null; then
	echo "Error: ollama not found in PATH" >&2
	exit 1
fi

# Check if diff script exists
if [ ! -x "$DIFF_SCRIPT" ]; then
	echo "Error: $DIFF_SCRIPT not found or not executable" >&2
	exit 1
fi

# Print header
echo -e "${BOLD}${CYAN}================================================================================${RESET}"
echo -e "${BOLD}${CYAN}FLAKE UPDATE ANALYSIS${RESET}"
echo -e "${BOLD}${CYAN}================================================================================${RESET}"
echo ""

# Run diff script and capture output
echo "Generating diff report..."
DIFF_OUTPUT=$("$DIFF_SCRIPT")

# Show the diff
echo "$DIFF_OUTPUT"
echo ""

# Separator before LLM analysis
echo ""
echo -e "${BOLD}${CYAN}================================================================================${RESET}"
echo -e "${BOLD}${CYAN}OLLAMA ANALYSIS (${OLLAMA_MODEL})${RESET}"
echo -e "${BOLD}${CYAN}================================================================================${RESET}"
echo ""

# Prompt for Ollama
PROMPT="Eres un experto en NixOS y administración de sistemas Linux. Analiza este diff de actualización de flake.

CONTEXT: Sistema NixOS actualizado desde profiles 189→190. El diff incluye cambios en flake inputs (nixpkgs, home-manager, etc.) y el closure completo del sistema.

ANALIZA Y RESUME:

1. CAMBIOS CRÍTICOS
   - Kernel, systemd, glibc, openssl, drivers nvidia
   - Navegadores (firefox, chrome)
   - Docker/containers
   - Herramientas de desarrollo

2. PAQUETES NUEVOS IMPORTANTES
   - Qué se añadió que sea relevante (∅ →)
   - Por qué aparecen (nuevas dependencias, features)

3. BREAKING CHANGES / WARNINGS
   - Cambios en APIs/ABIs (glibc, systemd)
   - Paquetes eliminados (→ ∅)
   - Versiones con known issues

4. SEGURIDAD
   - CVEs conocidos en las versiones anteriores
   - Actualizaciones de seguridad destacables

5. IMPACTO EN DISCO
   - +1437 MB es normal o preocupante
   - Qué contribuye más al aumento

6. RECOMENDACIONES POST-UPDATE
   - Qué probar/verificar
   - Servicios a reiniciar
   - Posibles rollbacks

SÉ TÉCNICO, CONCISO Y DIRECTO. Responde en español.

=== DIFF REPORT ===
$DIFF_OUTPUT"

# Run Ollama
echo "$PROMPT" | ollama run "$OLLAMA_MODEL"

# Footer
echo ""
echo -e "${BOLD}${CYAN}================================================================================${RESET}"
echo -e "${BOLD}${CYAN}END OF ANALYSIS${RESET}"
echo -e "${BOLD}${CYAN}================================================================================${RESET}"
