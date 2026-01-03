# Claude Code Configuration

Este directorio contiene la configuración de Claude Code para sincronizar entre máquinas usando GNU Stow.

## Estructura

```
claude-code/
├── .claude/
│   ├── CLAUDE.md              # Instrucciones globales y memoria
│   ├── CLAUDE.local.md        # Conversaciones locales (opcional)
│   ├── settings.json          # Configuración global
│   ├── settings.local.json    # Configuración local (opcional)
│   └── agents/                # Agentes personalizados
│       ├── nixos-guru.md
│       ├── nixifier.md
│       └── ...
├── .claude.json              # Preferencias y MCP servers
└── README.md                 # Este archivo
```

## Setup Inicial

Para copiar tu configuración actual de Claude Code a dotfiles:

```bash
cd ~/dotfiles
chmod +x scripts/setup-claude-code.sh
./scripts/setup-claude-code.sh
```

Este script copia:
- `~/.claude/CLAUDE.md` → Instrucciones globales
- `~/.claude/CLAUDE.local.md` → Conversaciones (si existe)
- `~/.claude/settings.json` → Configuración
- `~/.claude/settings.local.json` → Config local (si existe)
- `~/.claude/agents/` → Tus agentes personalizados
- `~/.claude.json` → Preferencias y MCP servers

## Aplicar con Stow

```bash
cd ~/dotfiles
stow -v -R claude-code
```

Esto crea symlinks de:
- `~/dotfiles/claude-code/.claude/` → `~/.claude/`
- `~/dotfiles/claude-code/.claude.json` → `~/.claude.json`

## Sincronizar a Otra Máquina

En vespino, macbook, etc:

```bash
# 1. Clonar dotfiles
git clone <repo-url> ~/dotfiles

# 2. Aplicar configuración de Claude Code
cd ~/dotfiles
stow -v -R claude-code

# 3. ¡Listo! Tu configuración de Claude Code está sincronizada
```

## Archivos Incluidos

### CLAUDE.md (Global)
Instrucciones y memoria que aplican en TODAS las máquinas.
Ejemplo: preferencias de estilo, tecnologías usadas, etc.

### CLAUDE.local.md (Local)
**IMPORTANTE**: Este archivo contiene conversaciones y contexto específico.
Se sincroniza entre máquinas para poder continuar conversaciones.

### settings.json (Global)
Configuración de Claude Code que aplica en todas las máquinas.
Ejemplo: `alwaysThinkingEnabled`, permisos, hooks.

### settings.local.json (Local)
Configuración específica de la máquina.
Se sincroniza para mantener preferencias consistentes.

### agents/ (Globales)
Tus agentes personalizados (nixos-guru, nixifier, etc.)
Se comparten entre todas las máquinas.

### .claude.json (Global + Local)
**ADVERTENCIA**: Puede contener tokens y credenciales.
Revisa este archivo antes de hacer commit.

## Seguridad

⚠️ **ANTES DE HACER COMMIT**:

1. Revisa `.claude.json` para tokens/credenciales sensibles
2. Decide si quieres compartir archivos `.local.*` (contienen conversaciones)
3. Añade a `.gitignore` lo que NO quieras subir

## Actualizar Configuración

Después de hacer cambios en Claude Code:

```bash
# Los cambios se aplican automáticamente (son symlinks)
# Solo necesitas commit si quieres sincronizar a otras máquinas

cd ~/dotfiles
git add claude-code/
git commit -m "Update Claude Code configuration"
git push
```

## Notas

- Los archivos son symlinks → cambios instantáneos
- Configuración sincronizada entre aurin, vespino, macbook
- Conversaciones preservadas en `.local.*` files
- Agentes compartidos automáticamente

## Integración con Home-Manager

La configuración de stow para claude-code está en:
`modules/home-manager/passh.nix`

```nix
activation = {
  linkDotfiles = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    ${pkgs.stow}/bin/stow -v -R -t ${config.home.homeDirectory} \
      alacritty composer fish picom xmobar xmonad claude-code
  '';
};
```

---
*Creado: 2026-01-03*
*Sistema: Aurin (NixOS 25.05)*
