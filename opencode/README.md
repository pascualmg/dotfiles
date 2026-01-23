# OpenCode / Crush - AI Coding Agents

**Status**: En transicion - OpenCode archivado, migrando a Crush

---

## IMPORTANTE: OpenCode esta ARCHIVADO

El proyecto **opencode-ai/opencode** fue archivado el 18 Sep 2025.
Ha continuado como **[Crush](https://github.com/charmbracelet/crush)** por Charm (los creadores de Bubble Tea).

### Estado actual en este repo

| Tool | nixpkgs | Version | Estado |
|------|---------|---------|--------|
| `opencode` | `nixpkgs.opencode` | 1.1.23 | Archivado, ultima version |
| `crush` | NUR (charmbracelet) | 0.34.0+ | Activo, recomendado |

---

## Por que Crush sobre Claude Code?

**Ventajas de Crush**:
- Multi-provider (Anthropic, OpenAI, Gemini, Groq, Bedrock, OpenRouter, etc.)
- MCP nativo (stdio, http, sse)
- LSP integration para contexto de codigo
- Session management robusto
- TUI moderna (Bubble Tea)
- Escrito en Go (binario unico, rapido)
- Activamente mantenido por Charm

**Desventajas vs claude-code**:
- Agentes custom mas complejos (no son simples .md)
- No portable: agentes claude-code incompatibles
- Config diferente (.crush.json vs .claude/)

---

## Instalacion

### Opcion 1: OpenCode (version archivada, ya en nixpkgs)

```bash
# Ya instalado en todas las maquinas via home-manager
opencode --version  # 1.1.23
```

### Opcion 2: Crush (recomendado, via NUR)

```nix
# En flake.nix, anadir NUR
inputs.nur.url = "github:nix-community/NUR";

# En home-manager o nixos config
{ nur, ... }:
{
  home.packages = [
    nur.repos.charmbracelet.crush
  ];
}
```

O instalacion manual:
```bash
# Homebrew
brew install charmbracelet/tap/crush

# NPM
npm install -g @charmland/crush

# Nix (efimero)
nix run github:numtide/nix-ai-tools#crush
```

---

## Configuracion

### Estructura de directorios

**Config** (gestionado por usuario):
```
~/.config/crush/crush.json       # Config global
./.crush.json                    # Config por proyecto (prioritario)
crush.json                       # Alternativa por proyecto
```

**State** (NO nixificar, runtime):
```
~/.local/share/crush/            # Unix
├── crush.json                   # State ephemeral
└── ...

~/.local/share/opencode/         # OpenCode legacy
├── auth.json                    # Credenciales OAuth
├── storage/                     # Sessions, mensajes
└── log/                         # Logs
```

### Archivo de configuracion ejemplo

```json
{
  "$schema": "https://charm.land/crush.json",
  "providers": {
    "anthropic": {
      "api_key": "$ANTHROPIC_API_KEY"
    }
  },
  "lsp": {
    "go": { "command": "gopls" },
    "typescript": { "command": "typescript-language-server", "args": ["--stdio"] },
    "nix": { "command": "nil" }
  },
  "mcp": {
    "filesystem": {
      "type": "stdio",
      "command": "mcp-server-filesystem",
      "args": ["/home/passh"]
    }
  },
  "options": {
    "debug": false
  }
}
```

---

## Variables de entorno

| Variable | Provider |
|----------|----------|
| `ANTHROPIC_API_KEY` | Anthropic (Claude) |
| `OPENAI_API_KEY` | OpenAI |
| `OPENROUTER_API_KEY` | OpenRouter |
| `GEMINI_API_KEY` | Google Gemini |
| `GROQ_API_KEY` | Groq |
| `AWS_ACCESS_KEY_ID` | Amazon Bedrock |
| `AWS_SECRET_ACCESS_KEY` | Amazon Bedrock |
| `AWS_REGION` | Amazon Bedrock |

---

## MCP Servers

Crush soporta MCP nativamente. Tipos de transporte:

- **stdio**: Servidores CLI via stdin/stdout
- **http**: Endpoints HTTP
- **sse**: Server-Sent Events

### Ejemplo: GitHub MCP

```json
{
  "mcp": {
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/",
      "headers": {
        "Authorization": "Bearer $GH_PAT"
      }
    }
  }
}
```

### MCP Servers utiles

| Server | Descripcion | Tipo |
|--------|-------------|------|
| `mcp-server-filesystem` | Acceso a sistema de archivos | stdio |
| `mcp-server-git` | Operaciones Git | stdio |
| `mcp-server-github` | GitHub API | http |
| `mcp-server-fetch` | HTTP requests | stdio |

---

## LSP Integration

Crush usa LSPs para contexto adicional (diagnosticos, etc.):

```json
{
  "lsp": {
    "go": { "command": "gopls" },
    "typescript": { "command": "typescript-language-server", "args": ["--stdio"] },
    "php": { "command": "phpactor", "args": ["language-server"] },
    "nix": { "command": "nil" }
  }
}
```

---

## Comandos principales

```bash
# Iniciar TUI
crush

# Continuar ultima sesion
crush -c

# One-shot command
crush -p "Explica este codigo"

# Con debug
crush --debug

# Ver logs
crush logs
crush logs --follow
```

---

## Shortcuts de teclado

### Global
| Shortcut | Accion |
|----------|--------|
| `Ctrl+C` | Salir |
| `Ctrl+?` | Ayuda |
| `Ctrl+L` | Ver logs |
| `Ctrl+A` | Cambiar sesion |
| `Ctrl+K` | Dialogo comandos |
| `Ctrl+O` | Seleccionar modelo |

### Editor
| Shortcut | Accion |
|----------|--------|
| `Ctrl+S` | Enviar mensaje |
| `Ctrl+E` | Editor externo |
| `i` | Modo edicion |
| `Esc` | Salir de edicion |

---

## Custom Commands

Crush soporta comandos custom via archivos Markdown:

```
~/.config/crush/commands/          # Comandos usuario (user:)
./.crush/commands/                 # Comandos proyecto (project:)
```

Ejemplo `~/.config/crush/commands/prime-context.md`:
```markdown
RUN git ls-files
READ README.md
```

Usar con `Ctrl+K` -> `user:prime-context`

---

## Agent Skills

Crush soporta [Agent Skills](https://agentskills.io) para extender capacidades:

```bash
# Instalar skills de ejemplo
mkdir -p ~/.config/crush/skills
cd ~/.config/crush/skills
git clone https://github.com/anthropics/skills.git _temp
mv _temp/skills/* . && rm -rf _temp
```

---

## Comparacion: claude-code vs opencode vs crush

| Aspecto | claude-code | opencode | crush |
|---------|-------------|----------|-------|
| **Estado** | Activo | Archivado | Activo |
| **Providers** | Solo Anthropic | Multi | Multi |
| **MCP** | Si | Si | Si (mejor) |
| **LSP** | No | Si | Si |
| **Agentes custom** | Markdown simple | - | Agent Skills |
| **TUI** | Buena | Buena | Excelente |
| **nixpkgs** | Si | Si | NUR |
| **Mantenimiento** | Anthropic | Abandonado | Charm |

---

## Plan de migracion

### Fase 1: Mantener ambos (actual)
- `opencode` instalado via nixpkgs (legacy)
- `claude-code` para agentes custom simples

### Fase 2: Anadir Crush
- [ ] Anadir NUR a flake.nix
- [ ] Instalar crush via home-manager
- [ ] Configurar `.crush.json` base
- [ ] Migrar configuracion de providers

### Fase 3: Evaluar
- [ ] Probar Crush en workflows reales
- [ ] Comparar experiencia con claude-code
- [ ] Decidir si reemplazar o mantener ambos

### Fase 4: Cleanup
- [ ] Si Crush OK: remover opencode
- [ ] Documentar config final
- [ ] Actualizar CLAUDE.md con preferencias

---

## TODOs

- [ ] Anadir NUR a flake.nix para Crush
- [ ] Crear modulo home-manager para Crush
- [ ] Configurar MCP servers utiles
- [ ] Migrar workflows de claude-code a Crush
- [ ] Documentar Agent Skills custom

---

## Referencias

- **Crush**: https://github.com/charmbracelet/crush
- **OpenCode (archivado)**: https://github.com/opencode-ai/opencode
- **Catwalk (providers)**: https://github.com/charmbracelet/catwalk
- **Agent Skills**: https://agentskills.io
- **MCP Protocol**: https://modelcontextprotocol.io/

---

## Changelog

- **2026-01-22**: Reescrito README - OpenCode archivado, documentado Crush como sucesor
- **2026-01-22**: FASE 0 completada - Investigacion real del ecosistema
