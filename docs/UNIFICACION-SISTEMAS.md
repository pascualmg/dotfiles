# Plan de Unificacion: GDM + GNOME + XMonad + Hyprland

**Fecha creacion**: 2026-01-17
**Estado**: PENDIENTE
**Prioridad**: Media (hacer con calma)

---

## Resumen Ejecutivo

Unificar aurin y macbook para que ambos sistemas tengan:
- **GDM** como display manager (selector de sesion grafico)
- **GNOME** como desktop environment de fallback
- **XMonad** como tiling window manager principal
- **Hyprland/Niri** como opcion Wayland (futuro)

Todo seleccionable desde GDM al iniciar sesion.

---

## Estado Actual (2026-01-17)

### Macbook (funcional pero con workaround)

```
Display Manager: GDM
Sesiones disponibles:
  - GNOME (funciona)
  - XMonad (funciona, config directa en configuration.nix)

Modulo xmonad.nix: NO IMPORTADO (causa conflictos)
```

**Configuracion actual en macbook/configuration.nix:**
```nix
services.xserver = {
  enable = true;
  displayManager.gdm.enable = true;
  desktopManager.gnome.enable = true;

  # XMonad configurado DIRECTAMENTE aqui (no via modulo)
  windowManager.xmonad = {
    enable = true;
    enableContribAndExtras = true;
  };

  xkb = { layout = "us,es"; options = "grp:alt_shift_toggle,caps:escape"; };
};

services.libinput = { ... };
```

### Aurin (funcional, sin GNOME)

```
Display Manager: LightDM (implicito via xmonad.nix)
Sesiones disponibles:
  - XMonad (unica)

Modulo xmonad.nix: IMPORTADO
```

**Configuracion actual en aurin/configuration.nix:**
```nix
imports = [ ../../../modules/desktop/xmonad.nix ];

desktop.xmonad = {
  enable = true;
  displaySetupCommand = "...";
  picomBackend = "egl";
  refreshRate = 120;
};
```

---

## Problema con el Modulo Actual

El modulo `modules/desktop/xmonad.nix` tiene varios componentes que **conflictuan con GDM+GNOME**:

### 1. Picom (Conflicto con Mutter)
```nix
services.picom = {
  enable = true;
  # ...
};
```
**Problema**: GNOME usa Mutter como compositor. Tener picom activo a nivel sistema causa conflictos.

### 2. Variables de Sesion Forzadas
```nix
environment.sessionVariables = {
  XDG_SESSION_TYPE = "x11";
  GDK_BACKEND = "x11";
  QT_QPA_PLATFORM = "xcb";
};
```
**Problema**: Fuerza X11 en TODO el sistema, incluyendo GNOME Wayland.

### 3. displayManager.setupCommands
```nix
displayManager = lib.mkIf (displaySetupCommand != "") {
  setupCommands = ''
    ${displaySetupCommand}
    xset r rate 350 50
  '';
};
```
**Problema**: GDM no soporta bien setupCommands, crea un wrapper que puede fallar.

### 4. XFCE como fallback (comentado pero conceptualmente)
El modulo originalmente tenia XFCE como fallback, que tambien conflictua con GNOME.

---

## Solucion Propuesta

### Fase 1: Refactorizar xmonad.nix (modulo compartido)

El modulo debe ser **minimalista** y compatible con cualquier display manager:

```nix
# modules/desktop/xmonad.nix (NUEVA VERSION)
{ config, pkgs, lib, ... }:

{
  options.desktop.xmonad = {
    enable = lib.mkEnableOption "XMonad window manager";
  };

  config = lib.mkIf config.desktop.xmonad.enable {
    services.xserver.windowManager.xmonad = {
      enable = true;
      enableContribAndExtras = true;
    };

    # Keyboard (compatible con GDM y LightDM)
    services.xserver.xkb = {
      layout = "us,es";
      options = "grp:alt_shift_toggle,caps:escape";
    };

    # Libinput (necesario para ambos sistemas)
    services.libinput = {
      enable = true;
      mouse = {
        accelProfile = "flat";
        accelSpeed = "0";
      };
    };

    # Paquetes necesarios para XMonad
    environment.systemPackages = with pkgs; [
      dmenu
      xclip
      xsel
    ];
  };
}
```

**LO QUE SE QUITA:**
- [ ] `services.picom` (mover a modulo separado o home-manager)
- [ ] `environment.sessionVariables` (X11 forzado)
- [ ] `displayManager.setupCommands` (problematico con GDM)
- [ ] `displaySetupCommand` option (ya no necesario)
- [ ] `picomBackend` option (mover a picom.nix)
- [ ] `refreshRate` option (mover a picom.nix)

### Fase 2: Crear modulo picom.nix separado (opcional)

Para maquinas que quieran picom (standalone XMonad sin GNOME):

```nix
# modules/desktop/picom.nix
{ config, lib, ... }:

{
  options.desktop.picom = {
    enable = lib.mkEnableOption "Picom compositor";
    backend = lib.mkOption {
      type = lib.types.str;
      default = "glx";
    };
    refreshRate = lib.mkOption {
      type = lib.types.int;
      default = 60;
    };
  };

  config = lib.mkIf config.desktop.picom.enable {
    services.picom = {
      enable = true;
      settings = {
        backend = config.desktop.picom.backend;
        vsync = true;
        refresh-rate = config.desktop.picom.refreshRate;
        # ... resto de config
      };
    };
  };
}
```

### Fase 3: Modificar configuraciones por maquina

**Macbook (ya tiene GDM+GNOME):**
```nix
imports = [
  ../../../modules/desktop/xmonad.nix
  # NO importar picom.nix (GNOME usa Mutter)
];

desktop.xmonad.enable = true;
# picom NO habilitado

services.xserver = {
  displayManager.gdm.enable = true;
  desktopManager.gnome.enable = true;
};
```

**Aurin (migrar de LightDM a GDM):**
```nix
imports = [
  ../../../modules/desktop/xmonad.nix
  ../../../modules/desktop/picom.nix  # Opcional si quiere picom standalone
];

desktop.xmonad.enable = true;
desktop.picom.enable = true;  # Solo cuando use XMonad standalone

services.xserver = {
  displayManager.gdm.enable = true;
  desktopManager.gnome.enable = true;
};
```

---

## Orden de Operaciones (Seguro)

### Prerequisitos

```bash
# Verificar hostname
hostname

# Asegurar que tienes generacion funcional
sudo nix-env --list-generations -p /nix/var/nix/profiles/system | tail -5

# Nota: Si algo falla, SIEMPRE puedes:
sudo nixos-rebuild switch --rollback
```

### Paso 1: Probar en Macbook (ya tiene GDM)

Macbook es el sistema de pruebas natural porque:
- Ya tiene GDM funcionando
- Ya tiene GNOME funcionando
- Solo necesita que xmonad.nix sea compatible

```bash
# 1. Hacer dry-build primero (no cambia nada)
sudo nixos-rebuild dry-build --flake ~/dotfiles#macbook --impure

# 2. Si dry-build OK, hacer test (aplica pero no hace boot default)
sudo nixos-rebuild test --flake ~/dotfiles#macbook --impure

# 3. Verificar:
#    - GDM aparece al reiniciar sesion?
#    - GNOME aparece como opcion?
#    - XMonad aparece como opcion?
#    - Ambos funcionan?

# 4. Si todo OK, hacer switch (hace boot default)
sudo nixos-rebuild switch --flake ~/dotfiles#macbook --impure
```

**Que probar despues de cada cambio en macbook:**
- [ ] `loginctl` - Ver sesiones activas
- [ ] Logout y verificar que GDM aparece
- [ ] Seleccionar GNOME - funciona?
- [ ] Seleccionar XMonad - funciona?
- [ ] En XMonad: Mod+p (dmenu), Mod+Shift+Enter (terminal)
- [ ] En GNOME: Apps funcionan? Settings?

### Paso 2: Anadir GDM+GNOME a Aurin

**IMPORTANTE: Aurin es produccion. Extremar precauciones.**

```bash
# 1. ANTES de tocar nada, verificar generacion actual
sudo nix-env --list-generations -p /nix/var/nix/profiles/system | tail -3

# 2. Dry-build (no cambia nada)
sudo nixos-rebuild dry-build --flake ~/dotfiles#aurin --impure

# 3. Test (aplica temporalmente)
sudo nixos-rebuild test --flake ~/dotfiles#aurin --impure

# 4. Verificar TODO antes de switch:
#    - nvidia-smi funciona?
#    - Sunshine funciona?
#    - Audio FiiO K7 funciona?
#    - Docker funciona?

# 5. Solo si TODO funciona:
sudo nixos-rebuild switch --flake ~/dotfiles#aurin --impure
```

**Que probar despues del cambio en aurin:**
- [ ] `nvidia-smi` - GPU detectada?
- [ ] `pactl list sinks` - FiiO K7 aparece?
- [ ] `docker ps` - Docker funciona?
- [ ] `systemctl status sunshine` - Streaming OK?
- [ ] Logout - GDM aparece?
- [ ] XMonad funciona igual que antes?
- [ ] GNOME funciona?
- [ ] Monitor 5120x1440@120Hz funciona en ambos?

---

## Rollback de Emergencia

Si algo falla catastroficamente:

### Desde GUI (si hay display manager)
1. Reiniciar
2. En GRUB, seleccionar generacion anterior
3. Boot en sistema funcional

### Desde TTY (si GUI no funciona)
```bash
# Ctrl+Alt+F2 para TTY2
# Login como root o tu usuario

# Ver generaciones disponibles
sudo nix-env --list-generations -p /nix/var/nix/profiles/system

# Rollback a la anterior
sudo nixos-rebuild switch --rollback

# O rollback a una especifica
sudo nix-env --switch-generation 42 -p /nix/var/nix/profiles/system
sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch
```

### Desde Live USB (peor caso)
1. Boot NixOS live USB
2. Montar particiones
3. Chroot
4. nixos-rebuild switch --rollback

---

## Checklist Pre-Cambio

Antes de hacer CUALQUIER cambio a xmonad.nix o gnome.nix:

- [ ] He verificado el hostname (`hostname`)
- [ ] He hecho `git status` y no hay cambios sin commit importantes
- [ ] He verificado que tengo generaciones anteriores funcionales
- [ ] He hecho dry-build primero
- [ ] He hecho test antes de switch
- [ ] Tengo acceso a TTY si GUI falla (Ctrl+Alt+F2)
- [ ] Conozco el comando de rollback

---

## Archivos Relevantes

```
dotfiles/
  modules/desktop/
    xmonad.nix      # Modulo compartido (A REFACTORIZAR)
    gnome.nix       # Modulo GNOME existente (NO en uso actualmente)
    picom.nix       # A CREAR (separar de xmonad.nix)
    hyprland.nix    # Futuro (Wayland)
    niri.nix        # Futuro (Wayland)

  nixos-aurin/etc/nixos/
    configuration.nix   # Config aurin (IMPORTA xmonad.nix)

  nixos-macbook/etc/nixos/
    configuration.nix   # Config macbook (NO importa xmonad.nix)
```

---

## Timeline Sugerido

1. **Dia 1**: Refactorizar xmonad.nix (quitar picom, sessionVariables, etc.)
2. **Dia 1**: Probar en macbook (ya tiene GDM)
3. **Dia 2**: Si macbook OK, crear picom.nix separado
4. **Dia 2**: Anadir GDM+GNOME a aurin
5. **Dia 3**: Limpiar codigo legacy, documentar

**No hay prisa. Mejor lento y seguro que rapido y roto.**

---

## Notas del Problema Original

El 2026-01-17 pasamos horas arreglando macbook porque:

1. Importaba `modules/desktop/xmonad.nix`
2. El modulo habilitaba picom (conflicto con Mutter/GNOME)
3. El modulo forzaba variables X11 (rompia GNOME Wayland)
4. El modulo usaba displayManager.setupCommands (incompatible con GDM)

**Solucion temporal**: Macbook NO importa el modulo y configura xmonad directamente.

**Solucion definitiva**: Refactorizar el modulo para que sea compatible con ambos escenarios.

---

## Referencias

- [NixOS Manual - Display Managers](https://nixos.org/manual/nixos/stable/#sec-x11-display-managers)
- [NixOS Wiki - XMonad](https://nixos.wiki/wiki/XMonad)
- [NixOS Wiki - GNOME](https://nixos.wiki/wiki/GNOME)
- [Arch Wiki - Picom](https://wiki.archlinux.org/title/Picom)

---

*Ultima actualizacion: 2026-01-17*
