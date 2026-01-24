# Dotfiles - Instrucciones para Claude

## Contexto del proyecto

Este es el repositorio de dotfiles de passh usando NixOS Flakes con arquitectura **clone-first**.

## Arquitectura Clone-First (2026-01-19)

### Filosofia

**Todas las maquinas son CLONES IDENTICOS.** Solo se diferencian en hardware.

La configuracion se divide en 3 capas:

```
modules/base/       -> Config comun a TODAS las maquinas (desktop, servicios, etc.)
hardware/           -> Config especifica de hardware (nvidia, apple, audio)
hosts/*/            -> Solo servicios y overrides especificos de cada maquina
```

### Estructura de directorios

```
dotfiles/
|-- flake.nix                    # Entry point (mkSystem para clone-first)
|-- modules/
|   |-- base/                    # BASE UNIFICADA (todas las maquinas)
|   |   |-- default.nix          # Imports: core/* + desktop + virtualization
|   |   |-- desktop.nix          # GNOME + XMonad (sesiones)
|   |   |-- greetd.nix           # greetd + tuigreet (login TUI)
|   |   |-- sunshine.nix         # Streaming server (opcional)
|   |   `-- virtualization.nix   # Docker + libvirt
|   |-- core/                    # Modulos core del sistema (boot, locale, packages, etc.)
|   |-- desktop/                 # Wayland: hyprland.nix, niri.nix
|   `-- home-manager/            # Configuracion usuario passh
|-- hardware/                    # MODULOS HARDWARE
|   |-- nvidia/
|   |   |-- rtx5080.nix          # Aurin: RTX 5080 (open drivers)
|   |   `-- rtx2060.nix          # Vespino: RTX 2060
|   |-- apple/
|   |   |-- macbook-pro-13-2.nix # MacBook: keyd, HiDPI, bateria
|   |   `-- snd-hda-macbookpro.nix # MacBook: audio CS8409
|   `-- audio/
|       `-- fiio-k7.nix          # Aurin: DAC/AMP FiiO K7
|-- hosts/                       # HOST-SPECIFIC (solo overrides)
|   |-- aurin/
|   |   |-- hardware-configuration.nix
|   |   `-- default.nix          # VPN bridge, hosts Vocento, etc.
|   |-- macbook/
|   |   |-- hardware-configuration.nix
|   |   `-- default.nix          # Casi vacio (todo viene de base + hardware)
|   `-- vespino/
|       |-- hardware-configuration.nix
|       |-- default.nix          # NFS, Minecraft, VPN VM
|       `-- minecraft.nix        # Servidor Minecraft
```

### Como se construye cada maquina

```nix
# En flake.nix
aurin = mkSystem {
  hostname = "aurin";
  hardware = [
    ./hardware/nvidia/rtx5080.nix
    ./hardware/audio/fiio-k7.nix
  ];
};

macbook = mkSystem {
  hostname = "macbook";
  hardware = [
    nixos-hardware.nixosModules.apple-macbook-pro
    ./hardware/apple/macbook-pro-13-2.nix
    ./hardware/apple/snd-hda-macbookpro.nix
  ];
};

vespino = mkSystem {
  hostname = "vespino";
  hardware = [
    ./hardware/nvidia/rtx2060.nix
  ];
};
```

## Display Managers: GDM -> LightDM -> greetd (RESUELTO 2026-01-24)

### Historia

1. **GDM (2026-01-19)**: Roto con NVIDIA y XMonad puro
2. **LightDM (2026-01-19)**: Funcionaba X11, pero NO soporta Wayland
3. **greetd + tuigreet (2026-01-24)**: Soporta X11 Y Wayland

### Solucion actual: greetd + tuigreet

Configurado en `modules/base/greetd.nix`:

```nix
services.greetd = {
  enable = true;
  settings.default_session = {
    command = ''
      ${pkgs.tuigreet}/bin/tuigreet \
        --time --asterisks --remember --remember-user-session \
        --sessions .../xsessions:.../wayland-sessions \
        --xsession-wrapper "startx ... -- -keeptty"
    '';
    user = "greeter";
  };
};
```

**Nota:** `--remember` guarda el último usuario en `/var/cache/tuigreet`. Primera vez vacío, después recuerda.

### Controles tuigreet

- **Tab**: Siguiente campo
- **F2**: Menu de sesiones
- **F3**: Ciclar sesiones
- **Enter**: Login

### Estado actual

| Maquina | Display Manager | Sesiones | Estado |
|---------|-----------------|----------|--------|
| macbook | greetd | XMonad, GNOME, Hyprland, niri | OK (probado) |
| aurin   | greetd | XMonad, GNOME, Hyprland, niri | Pendiente test |
| vespino | greetd | XMonad, GNOME, Hyprland, niri | Pendiente test |

## Aplicar configuraciones

**IMPORTANTE**: Ejecutar `hostname` primero para saber en que maquina estas.

```bash
# Aurin - necesita --impure (hosts Vocento)
sudo nixos-rebuild switch --flake ~/dotfiles#aurin --impure

# MacBook
sudo nixos-rebuild switch --flake ~/dotfiles#macbook

# Vespino - necesita --impure (hosts Vocento)
sudo nixos-rebuild switch --flake ~/dotfiles#vespino --impure

# Test sin aplicar cambios permanentes
sudo nixos-rebuild test --flake ~/dotfiles#aurin --impure

# Rollback de emergencia
sudo nixos-rebuild switch --rollback
```

## Maquinas

### Aurin (PRODUCCION CRITICA)
- **Hardware**: Dual Xeon E5-2699v3 (72 threads), 128GB RAM, RTX 5080
- **Rol**: Workstation principal, desarrollo, streaming (Sunshine)
- **Ubicacion config**: `hosts/aurin/` + `hardware/nvidia/rtx5080.nix` + `hardware/audio/fiio-k7.nix`
- **NUNCA** aplicar cambios sin testear primero

### MacBook (Laptop)
- **Hardware**: MacBook Pro 13,2 (2016), Intel Skylake, pantalla HiDPI
- **Rol**: Laptop para movilidad
- **Ubicacion config**: `hosts/macbook/` + `hardware/apple/`
- **Notas**: WiFi NO funciona (usar dongle USB), Touch Bar NO funciona (chip T1 en recovery)

### Vespino (Testing)
- **Hardware**: AMD CPU, RTX 2060
- **Rol**: Servidor secundario, Minecraft, NFS, testing de cambios
- **Ubicacion config**: `hosts/vespino/` + `hardware/nvidia/rtx2060.nix`
- **USAR** para probar cambios antes de aplicar a aurin

## Picom: por que no esta en desktop.nix

Picom NO se habilita en `modules/base/desktop.nix` porque conflictua con Mutter (GNOME).

**Solucion implementada:**
1. Picom se configura en home-manager (`modules/home-manager/programs/picom.nix`)
2. `xmonad.hs` lo lanza en `startupHook: spawnOnce "picom"`
3. Cuando usas GNOME, picom NO corre (Mutter hace de compositor)
4. Cuando usas XMonad, picom SI corre

## Historia importante: Limpieza de wallpapers (2025-11-22)

El repo tenia 880MB en `.git/` debido a 219 wallpapers AI (785MB) versionados.

**Solucion aplicada:**
1. Wallpapers removidos del tracking git (a .gitignore)
2. Historial reescrito con `git filter-branch`
3. Repo compactado: .git/ reducido de 880MB a 98MB

**Nota**: Los wallpapers (785MB) NO estan en git, solo locales en aurin:/home/passh/dotfiles/wallpapers/

## Hardware de Input - Filosofia "Hardware-First"

Filosofia HHKB: **el hardware manda, no el software**.

### Teclados
- **HHKB original** con Hasu controller (QMK)
- **HHKB Hybrid** (BT + USB-C) - Topre switches

### Layout de teclado - US/ES
- **Layout por defecto**: US (para programar)
- **Layout alternativo**: ES (para chats)
- **Toggle**: **Alt+Shift**
- **Caps Lock -> Escape**

Configurado en `modules/base/desktop.nix`:
```nix
services.xserver.xkb = {
  layout = "us,es";
  options = "grp:alt_shift_toggle,caps:escape";
};
```

### Raton
- **Logitech G Pro X Superlight 2** - DPI en onboard memory
- **libinput flat** (raw input) en todas las maquinas

## Notas para Claude

- **SIEMPRE ejecutar `hostname`** antes de recomendar comandos nixos-rebuild
- **Home-manager esta integrado en NixOS flake** - NO usar `home-manager switch`
- Para aplicar cambios: `sudo nixos-rebuild switch --flake ~/dotfiles#<hostname> --impure`
- El comando correcto es: `sudo nixos-rebuild switch --flake ~/dotfiles#<hostname> --impure`
- Configs migradas a home-manager: alacritty, fish, picom, xmobar, xmonad, ai-agents (claude-code)
- **Configs aun con stow** (en transicion):
  - `xmonad` - source files en `xmonad/.config/xmonad/` (hot-reload con `.source`)
  - `composer` - CRÍTICO PROD (Vocento Toran repo) - **NO TOCAR**

## Comandos utiles

```bash
aurin-info          # Info del sistema
fiio-k7-test        # Test audio FiiO K7
sunshine-test       # Test streaming
xeon-stress         # Stress test CPU
numa-info           # Info NUMA dual socket
```

## Referencias

- README.org (raiz) - Documentacion completa
- docs/MACBOOK-INSTALL-GUIDE.org - Guia instalacion MacBook

---

**Ultima actualizacion**: 2026-01-24
**Arquitectura**: Clone-First (mkSystem)
**Display Manager**: greetd + tuigreet (todas las maquinas)
**Sistemas**: Aurin, MacBook, Vespino (NixOS 25.05)
