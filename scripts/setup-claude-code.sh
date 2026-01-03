#!/usr/bin/env bash
# =============================================================================
# Setup Claude Code Configuration in Dotfiles
# =============================================================================
# Este script copia la configuración de Claude Code a dotfiles para
# sincronizar entre máquinas usando GNU Stow.
#
# NOTA: Incluye archivos .local.* para poder continuar conversaciones
# en diferentes máquinas (vespino, macbook, etc.)
# =============================================================================

set -euo pipefail

DOTFILES_DIR="${HOME}/dotfiles"
CLAUDE_CODE_DIR="${DOTFILES_DIR}/claude-code"
SOURCE_CLAUDE_DIR="${HOME}/.claude"
SOURCE_CLAUDE_JSON="${HOME}/.claude.json"

echo "=== Setup Claude Code en Dotfiles ==="
echo

# Crear estructura de directorios
echo "📁 Creando estructura de directorios..."
mkdir -p "${CLAUDE_CODE_DIR}/.claude/agents"

# Copiar CLAUDE.md (instrucciones globales)
if [[ -f "${SOURCE_CLAUDE_DIR}/CLAUDE.md" ]]; then
    echo "📄 Copiando CLAUDE.md..."
    cp "${SOURCE_CLAUDE_DIR}/CLAUDE.md" "${CLAUDE_CODE_DIR}/.claude/"
else
    echo "⚠️  CLAUDE.md no encontrado en ${SOURCE_CLAUDE_DIR}"
fi

# Copiar CLAUDE.local.md si existe (conversaciones locales)
if [[ -f "${SOURCE_CLAUDE_DIR}/CLAUDE.local.md" ]]; then
    echo "📄 Copiando CLAUDE.local.md (conversaciones)..."
    cp "${SOURCE_CLAUDE_DIR}/CLAUDE.local.md" "${CLAUDE_CODE_DIR}/.claude/"
else
    echo "ℹ️  CLAUDE.local.md no encontrado (opcional)"
fi

# Copiar settings.json
if [[ -f "${SOURCE_CLAUDE_DIR}/settings.json" ]]; then
    echo "⚙️  Copiando settings.json..."
    cp "${SOURCE_CLAUDE_DIR}/settings.json" "${CLAUDE_CODE_DIR}/.claude/"
else
    echo "⚠️  settings.json no encontrado"
fi

# Copiar settings.local.json si existe
if [[ -f "${SOURCE_CLAUDE_DIR}/settings.local.json" ]]; then
    echo "⚙️  Copiando settings.local.json..."
    cp "${SOURCE_CLAUDE_DIR}/settings.local.json" "${CLAUDE_CODE_DIR}/.claude/"
else
    echo "ℹ️  settings.local.json no encontrado (opcional)"
fi

# Copiar agentes personalizados
if [[ -d "${SOURCE_CLAUDE_DIR}/agents" ]]; then
    echo "🤖 Copiando agentes personalizados..."
    cp -r "${SOURCE_CLAUDE_DIR}/agents/"* "${CLAUDE_CODE_DIR}/.claude/agents/" 2>/dev/null || echo "ℹ️  No hay agentes personalizados"
else
    echo "ℹ️  Directorio agents no encontrado"
fi

# Copiar .claude.json (preferencias, MCP servers)
if [[ -f "${SOURCE_CLAUDE_JSON}" ]]; then
    echo "🔧 Copiando .claude.json..."
    cp "${SOURCE_CLAUDE_JSON}" "${CLAUDE_CODE_DIR}/"
    echo "⚠️  IMPORTANTE: Revisa .claude.json para eliminar tokens/credenciales sensibles"
else
    echo "ℹ️  .claude.json no encontrado (opcional)"
fi

echo
echo "✅ Configuración de Claude Code copiada a:"
echo "   ${CLAUDE_CODE_DIR}"
echo
echo "📋 Archivos copiados:"
ls -lh "${CLAUDE_CODE_DIR}/.claude/" 2>/dev/null || true
ls -lh "${CLAUDE_CODE_DIR}/.claude.json" 2>/dev/null || true
echo

echo "📝 Próximos pasos:"
echo "1. Revisar archivos copiados"
echo "2. Añadir 'claude-code' al stow en passh.nix"
echo "3. Ejecutar: cd ~/dotfiles && stow -v -R claude-code"
echo "4. Commit y push a git"
echo

echo "🔒 SEGURIDAD:"
echo "- Revisa .claude.json para tokens/credenciales"
echo "- Los archivos .local.* contienen conversaciones - decide si compartirlos"
echo
