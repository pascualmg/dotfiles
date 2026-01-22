# OpenCode Configuration

**Status**: 🚧 Work in Progress - Branch `opencode`

OpenCode es un CLI para AI coding agents que soporta múltiples providers (Anthropic, OpenAI, OpenRouter, etc.) con una interfaz TUI moderna.

## FASE 0: Investigación y Hallazgos (2026-01-22)

### ¿Por qué OpenCode?

**Ventajas sobre claude-code**:
- ✅ Mejor interfaz (TUI más moderna y responsive)
- ✅ Multi-provider (Anthropic, OpenAI, OpenRouter, Google, etc.)
- ✅ Soporte nativo MCP (Model Context Protocol)
- ✅ Sistema de plugins extensible
- ✅ Gestión de sesiones más robusta
- ✅ Better continuity con `-c` para continuar conversaciones

**Desventajas**:
- ⚠️ Agentes custom requieren TypeScript (no simples .md como claude-code)
- ⚠️ Más complejo de configurar
- ⚠️ No portable: agentes entre claude-code y opencode (formatos incompatibles)

---

## Arquitectura de OpenCode

### Estructura de Directorios

```
~/.config/opencode/          # Plugins y configuración
├── package.json             # Plugins instalados (@opencode-ai/plugin)
├── bun.lock                 # Lock file
└── node_modules/
    └── @opencode-ai/
        ├── plugin/          # Sistema de plugins
        └── sdk/             # SDK para desarrollar plugins

~/.local/share/opencode/     # State y datos (NO nixificar)
├── auth.json                # Credenciales OAuth (Anthropic, etc.)
└── storage/
    ├── session/             # Sesiones activas
    ├── message/             # Mensajes por sesión
    ├── session_diff/        # Diffs de sesiones
    ├── todo/                # TODOs por sesión
    ├── project/             # Proyectos (worktrees)
    └── part/                # Parts de mensajes
```

### Comandos Principales

```bash
# Instalación efímera (con comma de nix-index)
, opencode

# Comandos básicos
opencode                     # Start TUI
opencode -c                  # Continue last session
opencode run "mensaje"       # One-shot command
opencode --help              # Help

# Gestión de agentes
opencode agent list          # Listar agentes disponibles
opencode agent create        # Crear agente custom (TypeScript)

# MCP Servers
opencode mcp list            # Listar MCP servers
opencode mcp add             # Añadir MCP server

# Auth
opencode auth list           # Listar providers autenticados
opencode auth login          # Login OAuth a provider

# Sessions
opencode session             # Gestionar sesiones

# Stats
opencode stats               # Token usage y costos
```

---

## Agentes Built-in

OpenCode incluye estos agentes predefinidos (no requieren configuración):

### Primary Agents (uso principal)
- **`build`**: Full permissions, modo construcción
- **`plan`**: Planificación de tareas
- **`summary`**: Generación de resúmenes
- **`title`**: Generación de títulos
- **`compaction`**: Compactación de datos

### Subagents (uso específico)
- **`explore`**: Exploración de codebase (grep, glob, read, bash, webfetch)
- **`general`**: General purpose (deny todoread/todowrite)

**Formato**: JSON con sistema de permisos granular por herramienta.

---

## Agentes Custom (TypeScript Plugins)

**IMPORTANTE**: Los agentes de opencode NO son compatibles con los `.md` de claude-code.

### Formato de Agentes

**Claude-code** (`.claude/agents/name.md`):
```markdown
---
name: agent-name
---

System prompt here...
```

**OpenCode** (TypeScript plugin):
```typescript
// @opencode-ai/plugin format
import { defineAgent } from '@opencode-ai/sdk';

export default defineAgent({
  name: 'agent-name',
  permissions: [
    { permission: '*', action: 'allow', pattern: '*' }
  ]
});
```

### Crear Agente Custom

```bash
# En desarrollo
opencode agent create --path . \
  --description "What the agent does" \
  --mode primary \
  --model "anthropic/claude-sonnet-4-20250514"
```

**Nota**: Requiere compilación TypeScript, no editable en markdown.

---

## MCP (Model Context Protocol)

OpenCode soporta MCP servers nativamente:

```bash
# Listar servers
opencode mcp list

# Añadir server
opencode mcp add

# Auth OAuth
opencode mcp auth <name>

# Debug
opencode mcp debug <name>
```

**Estado actual**: No MCP servers configurados.

---

## Providers y Modelos

### Providers Soportados
- Anthropic (OAuth configurado ✅)
- OpenAI
- OpenRouter
- Google (Gemini)
- Perplexity
- Ollama (local)

### Modelos Anthropic Disponibles

```bash
opencode models anthropic
```

Modelos destacados:
- `anthropic/claude-sonnet-4-20250514` (recomendado)
- `anthropic/claude-opus-4-20250514`
- `anthropic/claude-haiku-4-5-20251001`
- `anthropic/claude-3-7-sonnet-latest`

---

## Estrategia de Nixificación

### Qué Nixificar

**Config** (managed by Nix):
```
~/dotfiles/opencode/.config/opencode/
└── package.json    # Plugins a instalar
```

**State** (NOT managed by Nix):
```
~/.local/share/opencode/    # Runtime state
├── auth.json               # Credenciales sensibles
└── storage/                # Sessions, mensajes, cache
```

### Separación Config vs State

| Tipo | Ruta | Nixificado | Razón |
|------|------|------------|-------|
| Config | `~/.config/opencode/` | ✅ Sí | Plugins declarativos |
| State | `~/.local/share/opencode/` | ❌ No | Runtime, credenciales |

### Approach

1. **Symlink** `~/dotfiles/opencode/.config/opencode/` → `~/.config/opencode/`
2. **NO nixificar** `~/.local/share/opencode/` (state runtime)
3. **Instalar** opencode permanentemente (no solo comma)
4. **Setup inicial**: `opencode auth login` (manual, una vez)

---

## Instalación de Opencode (Nixpkgs)

```bash
# Check si está en nixpkgs
nix search nixpkgs opencode

# Si no está, usar comma
, opencode

# O instalar globalmente
nix-env -iA nixpkgs.opencode
```

**Estado**: Investigar si `opencode` está en nixpkgs o usar overlay.

---

## Comparación: claude-code vs opencode

| Aspecto | claude-code | opencode |
|---------|-------------|----------|
| **Interfaz** | TUI básica | TUI moderna ⭐ |
| **Providers** | Solo Anthropic | Multi-provider ⭐ |
| **Agentes custom** | Markdown simple ⭐ | TypeScript compilado |
| **MCP support** | Sí | Sí (mejor integrado) ⭐ |
| **Config** | `~/.claude/` | `~/.config/opencode/` |
| **State** | `~/.claude/` (mixed) | `~/.local/share/opencode/` ⭐ |
| **Nixificado** | ✅ Activo | 🚧 WIP (rama opencode) |
| **Sessions** | Básico | Robusto ⭐ |
| **Continuidad** | `-c` buggy | `-c` funciona bien ⭐ |

**Veredicto**: Opencode mejor para uso diario, claude-code mejor para agentes custom simples.

---

## TODOs

### FASE 1: Nixificación Básica
- [ ] Buscar opencode en nixpkgs o crear derivation
- [ ] Crear módulo `modules/home-manager/programs/ai-agents.nix` (opencode section)
- [ ] Symlink `~/.config/opencode/package.json`
- [ ] Asegurar `~/.local/share/opencode/` se crea (no manage)
- [ ] Testear en aurin

### FASE 2: Configuración
- [ ] Documentar setup inicial (`opencode auth login`)
- [ ] Configurar plugins útiles (si existen)
- [ ] Investigar MCP servers útiles
- [ ] Crear guía de uso para el repo

### FASE 3: Integración
- [ ] Decidir si reemplazar claude-code o usar ambos
- [ ] Actualizar documentación principal (README.org)
- [ ] Aplicar en macbook y vespino
- [ ] Merge a master

### FASE 4: Agentes Custom (futuro)
- [ ] Investigar cómo crear plugins TypeScript para opencode
- [ ] Evaluar si vale la pena portar agentes de claude-code
- [ ] Documentar proceso de desarrollo de agentes

---

## Notas de Investigación

### ¿Comma vs Instalación Permanente?

**Comma** (`, opencode`):
- ✅ No contamina profile
- ✅ Siempre versión latest
- ❌ No persiste config entre invocaciones
- ❌ Overhead de descarga cada vez

**Instalación permanente**:
- ✅ Config persiste
- ✅ Más rápido
- ✅ Nixificable
- ❌ Ocupa espacio en profile

**Decisión**: Instalar permanentemente para nixificar correctamente.

### Auth y Credenciales

`~/.local/share/opencode/auth.json` contiene tokens OAuth:
```json
{
  "providers": {
    "Anthropic": {
      "type": "oauth",
      "token": "..."
    }
  }
}
```

**Seguridad**: NO commitear auth.json, mantener fuera de Nix store.

### Plugins Actuales

```json
{
  "dependencies": {
    "@opencode-ai/plugin": "1.1.23"
  }
}
```

**Investigar**: ¿Qué otros plugins existen? ¿NPM registry?

---

## Referencias

- **OpenCode Repo**: https://github.com/opencode-ai/opencode (investigar)
- **MCP Protocol**: https://modelcontextprotocol.io/
- **Claude-code (comparison)**: `~/dotfiles/claude-code/README.md`

---

## Changelog

- **2026-01-22**: FASE 0 completada - Investigación y hallazgos documentados
- **2026-01-22**: Rama `opencode` creada para desarrollo aislado
