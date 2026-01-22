# Análisis: Nix-on-Droid (Android) - Estado Actual

**Fecha**: 2026-01-22  
**Status**: 🪦 ABANDONADO - Requiere revisión y decisión

---

## Estado Actual del Config

### Lo que existe

```
droid/
├── common.nix              # Base común (shell, packages básicos)
├── android/
│   └── default.nix         # Device-specific (vacío)
└── ANALISIS.md             # Este archivo

modules/home-manager/machines/
└── android.nix             # Home-manager config (134 líneas)
```

### Paquetes Configurados

**Sistema** (`droid/common.nix`):
- Esenciales: `openssh`, `git`, `vim`
- Utils: `coreutils`, `gnugrep`, `gnused`, `gawk`, `findutils`, `which`, `man`
- Shell: Fish
- Terminal: JetBrains Mono Nerd Font + Solarized Dark

**Home-manager** (`android.nix`):
- TUI: `tmux`, `mosh`, `fzf`, `lazygit`, `ncdu`
- Emacs: `emacs`, `ripgrep`, `fd` (Doom Emacs support)
- **X11 Stack completo**:
  - `xmonad`, `xmonad-contrib`, `xmobar`
  - `alacritty`, `xterm`, `dmenu`
  - `feh`, `picom`, `nitrogen`, `scrot`, `xclip`
  - Scripts: `start-x11`, `x11-run`
- AI: `claude-code` (condicional, desde pkgsMasterArm)

---

## Problemas Identificados

### 1. **Overengineering** 🤯
- **X11 + XMonad en Android**: ¿Realista? ¿Útil?
- Stack completo de desktop (picom, nitrogen, feh) en móvil
- Poco práctico: requiere Termux-X11, pantalla externa, teclado/ratón

### 2. **Paquetes Obsoletos/Rotos**
- `claude-code`: Condicional desde `pkgsMasterArm` (ARM)
- No hay `opencode` (recién nixificado en desktop)
- Doom Emacs sin sync/install automatizado

### 3. **Falta de Uso Real**
- No hay evidencia de uso reciente
- No hay scripts útiles para móvil
- Config "copy-paste" de desktop sin adaptación

### 4. **Mantenimiento**
- No actualizado desde creación inicial
- `nix-on-droid` versión 24.05 (puede estar outdated)
- No hay docs de setup/uso

---

## Casos de Uso Reales para Nix-on-Droid

### ✅ Práctico
1. **Terminal SSH client** (tmux, mosh, fish)
2. **Git client portátil** (lazygit, fzf)
3. **Editor emergencias** (vim, nano)
4. **AI coding en movimiento** (claude-code/opencode)
5. **Scripts personales** (sync, backup, etc.)

### ❌ Impractical
1. **XMonad + X11**: Necesita pantalla externa + periféricos
2. **Doom Emacs**: Pantalla pequeña, input difícil
3. **Stack desktop completo**: Overhead innecesario

---

## Propuestas

### Opción A: **SIMPLIFICAR** (Recomendado)

**Keep**:
- Terminal básico (fish, tmux, mosh)
- Git + lazygit
- AI agents (opencode prioritario)
- Utils TUI (fzf, ncdu, ripgrep, fd)

**Remove**:
- Todo el stack X11/XMonad (xmonad, xmobar, alacritty, picom, etc.)
- Doom Emacs (usar vim o micro para emergencias)
- Scripts start-x11 (no prácticos)

**Add**:
- `opencode` (recién nixificado, mejor que claude-code)
- `micro` o `helix` (editores TUI modernos)
- Scripts útiles móvil:
  - `quick-commit`: Git add+commit+push rápido
  - `sync-dotfiles`: Pull latest dotfiles
  - `android-info`: Info del dispositivo

**Resultado**: Config minimalista, mantenible, útil.

---

### Opción B: **ARCHIVAR**

Si no usas el móvil para desarrollo:
1. Mover `droid/` a `archive/droid/`
2. Documentar "no longer maintained"
3. Mantener en git history por si acaso

---

### Opción C: **MANTENER COMO ESTÁ**

Solo si realmente usas X11 en Android con Termux-X11.

---

## Decisión Requerida

**Preguntas**:
1. ¿Usas actualmente nix-on-droid en tu móvil?
2. ¿Has usado alguna vez X11/XMonad en Android?
3. ¿Qué casos de uso reales tienes para el móvil?

**Recomendación**:
- Si **NO usas**: **Opción B** (archivar)
- Si **usas poco**: **Opción A** (simplificar)
- Si **usas X11**: **Opción C** (mantener)

---

## Config Simplificado Propuesto

Si eliges **Opción A**, esto sería el nuevo `android.nix`:

```nix
{ config, pkgs, lib, hostname, ... }:

{
  imports = [ ../core.nix ];

  home.packages = with pkgs; [
    # Terminal essentials
    tmux
    mosh
    
    # Git workflow
    lazygit
    
    # TUI tools
    fzf
    ncdu
    ripgrep
    fd
    
    # Editor
    micro  # Modern TUI editor (better than vim for mobile)
    
    # AI coding
    opencode  # Nixified, multi-provider
  ];

  programs.fish = {
    enable = true;
    shellAbbrs = {
      g = "git";
      gs = "git status";
      gc = "git commit -m";
      gp = "git push";
      gl = "git log --oneline -10";
      l = "ls -lah";
      ".." = "cd ..";
    };
  };

  programs.tmux = {
    enable = true;
    shortcut = "a";
    terminal = "screen-256color";
    extraConfig = ''
      set -g mouse on
      set -g status-style bg=black,fg=white
    '';
  };
}
```

**Líneas**: ~40 (vs 134 actual)  
**Pragmático**: Todo útil en móvil  
**Mantenible**: Sin dependencies complejas

---

## Siguiente Paso

**Decisión del usuario requerida**:
- [ ] Opción A: Simplificar
- [ ] Opción B: Archivar
- [ ] Opción C: Mantener como está
- [ ] Opción D: Otra idea

Una vez decidido, implementar en rama separada y testear en el móvil real.

---

## Referencias

- Nix-on-Droid: https://github.com/nix-community/nix-on-droid
- F-Droid Nix-on-Droid app: https://f-droid.org/packages/com.termux.nix/
- Termux-X11 (si mantener X11): https://github.com/termux/termux-x11
