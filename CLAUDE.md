# Dotfiles - Instrucciones para Claude

## Contexto del proyecto

Este es el repositorio de dotfiles de passh@aurin usando GNU Stow para gestión de enlaces simbólicos.

## Configuraciones principales

- **home-manager/**: Gestión de paquetes con Nix Home Manager
- **nixos-aurin/**: Configuración NixOS específica de Aurin (ver nixos-aurin/README.org)
- **xmonad/**: Window manager (XMonad + Haskell)
- **picom/**: Compositor X11
- **fish/**: Shell principal
- **alacritty/**: Terminal emulator

Ver **README.org** para documentación completa.

## Historia importante: Limpieza de wallpapers (2025-11-22)

El repo tenía 880MB en `.git/` debido a 219 wallpapers AI (785MB) versionados en git.

**Solución aplicada:**
1. Wallpapers removidos del tracking git (añadidos a .gitignore)
2. Historial git reescrito con `git filter-branch`
3. Repo compactado con `git gc --aggressive`
4. **Resultado**: .git/ reducido de 880MB a 98MB

**IMPORTANTE**: El historial fue reescrito y pusheado con `--force` al origin.

## Si clonas este repo en otra máquina y ves problemas

Si al clonar encuentras que el repo es muy grande (>500MB) o hay conflictos con wallpapers:

```bash
cd ~/dotfiles

# Opción 1: Forzar actualización (recomendado)
git fetch origin
git reset --hard origin/master
git clean -fdx

# Opción 2: Re-clonar desde cero (más seguro)
cd ~
mv dotfiles dotfiles.backup
git clone <repo-url> dotfiles
```

**Nota**: Los wallpapers (785MB) NO están en git, solo locales en aurin:/home/passh/dotfiles/wallpapers/

## Aplicar configuraciones (FLAKES)

**IMPORTANTE**: Este repo usa NixOS Flakes. Home-manager está integrado en NixOS, NO es un comando separado.

```bash
# Aurin - SIEMPRE usar --impure (necesario para hosts Vocento)
sudo nixos-rebuild switch --flake ~/dotfiles#aurin --impure

# Macbook
sudo nixos-rebuild switch --flake ~/dotfiles#macbook

# Actualizar flake.lock
nix flake update
```

**NO usar** `home-manager switch` - no existe como comando separado, está integrado en nixos-rebuild.

### Stow (solo para configs NO migradas a home-manager)

```bash
cd ~/dotfiles
stow -v xmonad   # XMonad aún usa stow
```

## Estructura de carpetas ignoradas

Estas carpetas NO están en git (ver .gitignore):
- `wallpapers/` - Fondos de pantalla locales (785MB)
- `.aider*` - Cache de aider
- `*.swp`, `*.swo` - Archivos temporales de vim

## Hardware de Input - Filosofía "Hardware-First"

Filosofía HHKB aplicada a todo el input: **el hardware manda, no el software**.

### Teclados
- **HHKB original** con Hasu controller (QMK)
- **HHKB Hybrid** (BT + USB-C) - Topre switches

### Layout de teclado - US/ES

Configuración dual US (default) + ES con toggle:

- **Layout por defecto**: US (para programar con HHKB)
- **Layout alternativo**: ES (para chats ocasionales)
- **Toggle**: **Alt+Shift** cambia entre US y ES
- **Caps Lock → Escape** (útil para Vim/Emacs)

Configurado en 3 lugares (redundancia para robustez):
1. **NixOS xkb** (`modules/desktop/xmonad.nix`): Sistema base
2. **XMonad startup** (`xmonad.hs`): Aplica en cada Mod+q
3. **Máquinas individuales**: vespino, macbook configs

```nix
# Configuración xkb en todas las máquinas
services.xserver.xkb = {
  layout = "us,es";
  options = "grp:alt_shift_toggle,caps:escape";
};
```

```bash
# Aplicar manualmente (sesión actual)
setxkbmap us,es -option grp:alt_shift_toggle,caps:escape

# Verificar configuración actual
setxkbmap -query
```

### Ratón
- **Logitech G Pro X Superlight 2** (nuevo) - DPI configurado via G Hub en Windows, guardado en onboard memory
- **Logitech G Pro** (viejo) - DPI configurable via ratbagctl en Linux
- **libinput configurado en flat** (raw input) en todas las máquinas NixOS
- Sin aceleración del sistema - movimiento 1:1 con el DPI del ratón
- **DPI recomendado**: 1000 (equilibrio gaming/escritorio)

```nix
# Configuración aplicada en todas las máquinas (aurin, macbook, vespino)
services.libinput = {
  enable = true;
  mouse = {
    accelProfile = "flat";  # Raw input
    accelSpeed = "0";       # Respeta DPI del ratón
  };
};
```

#### Configuración DPI con ratbagctl

**G Pro viejo** - Soportado por libratbag/ratbagd:
```bash
ratbagctl list                        # Ver dispositivos (ej: "singing-hare")
ratbagctl "singing-hare" info         # Ver DPI actual y perfiles
ratbagctl "singing-hare" dpi get      # DPI activo
ratbagctl "singing-hare" dpi set 1000 # Cambiar DPI
```

**G Pro X Superlight 2** - NO soportado por libratbag 0.18 ni solaar 1.1.16 (ratón muy nuevo, 2023):
- Usar **G Hub en Windows** para configurar DPI
- Activar **Onboard Memory Mode** para guardar en el ratón
- Configurar los 3 perfiles (Lightspeed, USB, Bluetooth) con el mismo DPI para consistencia

#### Herramientas instaladas
- **ratbagd** - Daemon para configurar ratones gaming (habilitado en services.nix)
- **piper** - GUI para ratbagd (útil para ratones soportados)

### Indicador batería en xmobar
- Script `scripts/wireless-mouse.sh` lee batería via `/sys/class/power_supply/hidpp_battery_*`
- Opción `dotfiles.xmobar.showWirelessMouse = true` (default)
- Siempre visible: icono color + % si conectado, gris si desconectado
- Colores: verde >80%, amarillo 20-80%, rojo <20%

## Notas para Claude

- **NO versionar archivos grandes** (imágenes, binarios, etc.) en git
- Usar `.gitignore` para excluir wallpapers, caches, temporales
- **Home-manager está integrado en NixOS flake** - NO usar `home-manager switch`
- Para aplicar cambios: `sudo nixos-rebuild switch --flake ~/dotfiles#aurin --impure`
- Configs migradas a home-manager: alacritty, fish, picom, xmobar
- Configs aún con stow: xmonad
- El sistema es NixOS 25.05 en Aurin (Dual Xeon + RTX 5080)

## Comandos útiles del sistema

Ver `README.org` para lista completa, pero los principales:

```bash
aurin-info          # Info del sistema
fiio-k7-test        # Test audio FiiO K7
sunshine-test       # Test streaming
xeon-stress         # Stress test CPU
numa-info           # Info NUMA dual socket
```

## Referencias

- README.org (raíz) - Documentación completa de dotfiles
- nixos-aurin/README.org - Documentación NixOS Aurin específica
- .gitignore - Lista de archivos/carpetas ignorados

---

**Última actualización**: 2026-01-12
**Sistema**: Aurin (NixOS 25.05, Dual Xeon E5-2699v3, RTX 5080)
