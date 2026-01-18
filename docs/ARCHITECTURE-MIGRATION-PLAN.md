# Plan de Migracion: Arquitectura NixOS Unificada

> **Fecha**: 2026-01-18
> **Estado**: PLAN REVISADO v2 - CAMBIOS ACORDADOS
> **Autor**: NixOS Guru + passh

---

## La Filosofia: TODAS las Maquinas son Clones Identicos

**Principio fundamental**: No existe "aurin necesita X" o "macbook necesita Y".

**TODAS las maquinas tienen TODO instalado y configurado de forma identica.**

Las UNICAS diferencias permitidas son:
1. `hostname` - El nombre de la maquina
2. `hardware-configuration.nix` - Auto-generado por NixOS
3. Modulos de hardware especifico (nvidia, apple, fiio-k7, etc.)
4. Modulos opt-in explicitos (vocento-vpn, etc.) - importados donde se necesitan

**Fin. No hay mas diferencias.**

### Por que?

- Si Sunshine no tiene sentido en macbook -> no pasa nada, simplemente no lo usas, pero ESTA DISPONIBLE.
- Si GNOME no tiene sentido en aurin -> no pasa nada, usas XMonad, pero ESTA DISPONIBLE.
- Si Steam no corre en macbook (Intel GPU) -> no pasa nada, no lo ejecutas, pero ESTA INSTALADO.

### Beneficios

1. **Reproducibilidad total**: Cualquier maquina puede hacer cualquier cosa
2. **Simplicidad mental**: No hay que recordar "que tiene cada maquina"
3. **Migracion facil**: Cambiar de maquina = enchufar SSD y funciona
4. **Menos codigo**: Un solo `base/` en lugar de configs por maquina

---

## Indice

1. [Estructura Objetivo](#1-estructura-objetivo)
2. [El Flake Final](#2-el-flake-final)
3. [Ciclo de Vida de Modulos](#3-ciclo-de-vida-de-modulos)
4. [Resolucion de Conflictos Actuales](#4-resolucion-de-conflictos-actuales)
5. [Plan de Migracion](#5-plan-de-migracion)
6. [Rollback y Recuperacion](#6-rollback-y-recuperacion)

---

## 1. Estructura Objetivo

```
dotfiles/
├── flake.nix                    # Punto de entrada - muy simple
├── modules/
│   ├── base/                    # TODO lo que TODAS las maquinas tienen
│   │   ├── default.nix          # Importa todo lo de abajo
│   │   ├── boot.nix             # systemd-boot base
│   │   ├── locale.nix           # Timezone, locale
│   │   ├── console.nix          # TTY config
│   │   ├── nix-settings.nix     # Flakes, GC, auto-optimise
│   │   ├── security.nix         # Polkit, RTKit, sudo
│   │   ├── packages.nix         # TODOS los paquetes (incluido Steam, Thunar, etc.)
│   │   ├── services.nix         # TODOS los servicios (Sunshine, Syncthing, Docker, etc.)
│   │   ├── desktop.nix          # GDM + GNOME + XMonad + Hyprland + Niri (TODO disponible)
│   │   ├── users.nix            # Usuario passh
│   │   ├── networking.nix       # NetworkManager base (SIN VPN)
│   │   └── virtualization.nix   # Docker + libvirt para todos
│   └── vocento-vpn.nix          # VPN Vocento - MODULO OPT-IN (no en base/)
├── hardware/                    # SOLO drivers especificos de hardware
│   ├── nvidia/
│   │   ├── rtx5080.nix          # RTX 5080 (open=true, CUDA optimizations)
│   │   └── rtx2060.nix          # RTX 2060 (open=false, stable drivers)
│   ├── apple/
│   │   ├── macbook-pro-13-2.nix # MacBook Pro 13,2 (Touch Bar, SPI, WiFi, HiDPI)
│   │   └── snd-hda-macbookpro.nix # Driver audio CS8409
│   └── audio/
│       └── fiio-k7.nix          # FiiO K7 DAC/AMP
├── experimental/                # Modulos en desarrollo/prueba
│   └── minecraft.nix            # Servidor Minecraft (probando en vespino)
├── hosts/                       # Solo hardware-configuration.nix por maquina
│   ├── aurin/
│   │   └── hardware-configuration.nix
│   ├── macbook/
│   │   └── hardware-configuration.nix
│   └── vespino/
│       └── hardware-configuration.nix
└── home-manager/                # Config de usuario
    ├── default.nix
    ├── passh.nix                # TODO lo compartido (igual para TODAS)
    ├── core.nix
    ├── programs/                # Configs por programa
    │   ├── picom.nix            # Picom en HOME-MANAGER (no NixOS)
    │   ├── xmobar.nix
    │   ├── alacritty.nix
    │   └── ...
    └── machines/                # MINIMO - Solo opciones dependientes del hardware
        ├── aurin.nix            # { dotfiles.picom.backend = "glx"; dotfiles.xmobar.dpi = 96; }
        ├── macbook.nix          # { dotfiles.picom.backend = "xrender"; dotfiles.xmobar.dpi = 227; }
        └── vespino.nix          # { dotfiles.picom.backend = "glx"; dotfiles.xmobar.dpi = 96; }
```

### Que va donde?

| Tipo | Ubicacion | Ejemplo |
|------|-----------|---------|
| Paquetes del sistema | `base/packages.nix` | vim, git, steam, thunar |
| Servicios del sistema | `base/services.nix` | SSH, Syncthing, Ollama, Sunshine |
| Display managers/desktops | `base/desktop.nix` | GDM, GNOME, XMonad, Hyprland |
| Drivers de GPU | `hardware/nvidia/*.nix` | NVIDIA proprietary/open |
| Drivers de audio especial | `hardware/audio/fiio-k7.nix` | FiiO K7 DAC |
| Drivers Apple | `hardware/apple/*.nix` | Touch Bar, SPI |
| Modulos en prueba | `experimental/` | Minecraft, nuevo servicio |
| **VPN Vocento** | `modules/vocento-vpn.nix` | **OPT-IN, NO en base/** |
| Compositor (picom) | `home-manager/programs/picom.nix` | Picom config |
| Configs personales | `home-manager/` | Alacritty, Fish, Emacs |
| **Preferencias de hardware** | `home-manager/machines/*.nix` | **SOLO picom backend, xmobar dpi** |

### home-manager/machines/*.nix - MINIMAS

Estas carpetas deben contener **SOLO** opciones que dependen del hardware:

```nix
# home-manager/machines/aurin.nix - SOLO preferencias de hardware
{
  dotfiles.picom.backend = "glx";      # NVIDIA soporta GLX
  dotfiles.xmobar.dpi = 96;            # Monitor 5120x1440 a DPI normal
}

# home-manager/machines/macbook.nix - SOLO preferencias de hardware
{
  dotfiles.picom.backend = "xrender";  # Intel NO soporta GLX bien
  dotfiles.xmobar.dpi = 227;           # Retina display HiDPI
}

# home-manager/machines/vespino.nix - SOLO preferencias de hardware
{
  dotfiles.picom.backend = "glx";      # NVIDIA soporta GLX
  dotfiles.xmobar.dpi = 96;            # Monitor normal
}
```

**Todo lo demas va en `home-manager/passh.nix`** - igual para todos.

---

## 2. El Flake Final

```nix
# flake.nix - SIMPLICIDAD MAXIMA, SIN FLAGS
{
  outputs = { self, nixpkgs, home-manager, nixos-hardware, ... }@inputs:
    let
      # Funcion helper para crear sistemas
      mkSystem = {
        hostname,
        hardware ? [],      # Modulos de hardware (nvidia, apple, etc.)
        extra ? [],         # Modulos adicionales OPT-IN (vocento-vpn, etc.)
      }:
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; inherit hostname; };
          modules = [
            # 1. Base IDENTICA para TODAS las maquinas
            ./modules/base

            # 2. Hardware-configuration auto-generado
            ./hosts/${hostname}/hardware-configuration.nix

            # 3. Solo el hostname
            { networking.hostName = hostname; }

            # 4. Modulos de hardware especifico
          ] ++ hardware ++ extra ++ [
            # 5. Home Manager integrado
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = { inherit inputs hostname; };
                users.passh = import ./modules/home-manager;
              };
            }
          ];
        };
    in
    {
      nixosConfigurations = {
        # ===== AURIN - Produccion (ULTIMA en testing) =====
        aurin = mkSystem {
          hostname = "aurin";
          hardware = [
            ./hardware/nvidia/rtx5080.nix
            ./hardware/audio/fiio-k7.nix
          ];
          extra = [
            ./modules/vocento-vpn.nix  # OPT-IN: Tiene la VM Ubuntu
          ];
        };

        # ===== MACBOOK - Laptop (PRIMERA en testing) =====
        macbook = mkSystem {
          hostname = "macbook";
          hardware = [
            ./hardware/apple/macbook-pro-13-2.nix
            ./hardware/apple/snd-hda-macbookpro.nix
            nixos-hardware.nixosModules.apple-macbook-pro
            nixos-hardware.nixosModules.common-pc-ssd
          ];
          # NO tiene vocento-vpn.nix - no tiene la VM Ubuntu
        };

        # ===== VESPINO - Testing Ground (SEGUNDA en testing) =====
        vespino = mkSystem {
          hostname = "vespino";
          hardware = [
            ./hardware/nvidia/rtx2060.nix
          ];
          extra = [
            ./modules/vocento-vpn.nix  # OPT-IN: Tiene la VM Ubuntu
            ./experimental/minecraft.nix
          ];
        };
      };
    };
}
```

### Observa la simplicidad:

- **SIN FLAGS** - No hay `enableVocentoVPN = true`
- Modulos OPT-IN via `extra = [ ./modules/vocento-vpn.nix ]`
- Anadir maquina nueva = 6 lineas
- Probar modulo nuevo = anadir a `experimental`
- Modulo maduro = mover a `base/`
- NO HAY configuracion duplicada entre maquinas
- macbook simplemente **NO importa** vocento-vpn.nix porque no tiene la VM

---

## 3. Ciclo de Vida de Modulos

### Fase 1: Experimental

```
1. Crear modulo en experimental/wow.nix
2. Anadir a UNA maquina:
   vespino = mkSystem {
     extra = [ ./experimental/wow.nix ];
   };
3. Probar: sudo nixos-rebuild switch --flake ~/dotfiles#vespino --impure
```

### Fase 2: Validacion

```
4. Si funciona en vespino, probar en macbook (si aplica):
   macbook = mkSystem {
     extra = [ ./experimental/wow.nix ];
   };
5. Probar en macbook
```

### Fase 3: Promocion a Base

```
6. Cuando esta maduro, mover a modules/base/:
   mv experimental/wow.nix modules/base/wow.nix

7. Importar en modules/base/default.nix:
   imports = [
     ./wow.nix  # NUEVO
   ];

8. Quitar de extra en todas las maquinas:
   vespino = mkSystem {
     # extra ya no tiene wow.nix
   };

9. TODAS las maquinas lo tienen automaticamente
```

### Modulos que NUNCA van a base/ (OPT-IN permanente)

Algunos modulos **por su naturaleza** no deben ir a base/:

- **vocento-vpn.nix** - Requiere VM Ubuntu corriendo, no todas las maquinas la tienen
- Otros modulos que requieren hardware/software especifico no universalmente presente

Estos modulos van en `modules/` (no en `base/`) y se importan via `extra = []`.

---

## 4. Resolucion de Conflictos Actuales

### 4.1 Conflicto Picom vs GNOME/Mutter

**Problema actual**: `modules/desktop/xmonad.nix` habilita `services.picom` a nivel NixOS. Esto conflictua con Mutter (compositor de GNOME).

**Solucion**: Picom va en HOME-MANAGER, no en NixOS.

```
NixOS (modules/base/desktop.nix):
  - Habilita GDM, GNOME, XMonad, Hyprland, Niri
  - NO habilita picom

Home-Manager (modules/home-manager/programs/picom.nix):
  - YA EXISTE y funciona
  - Se activa solo cuando el usuario lo necesita
  - Cada sesion decide: XMonad usa picom, GNOME no
```

**Implementacion**: El modulo picom de home-manager ya genera `~/.config/picom/picom.conf`. Solo hay que:

1. Eliminar `services.picom` de NixOS
2. Ejecutar picom manualmente o via xmonad.hs al iniciar XMonad:
   ```haskell
   -- En xmonad.hs startupHook:
   spawnOnce "picom --config ~/.config/picom/picom.conf"
   ```

### 4.2 Variables de Sesion X11

**Problema actual**: `xmonad.nix` fuerza estas variables globalmente:
```nix
environment.sessionVariables = {
  XDG_SESSION_TYPE = "x11";
  GDK_BACKEND = "x11";
  QT_QPA_PLATFORM = "xcb";
};
```

Esto rompe Wayland (GNOME, Hyprland, Niri).

**Solucion**: Estas variables NO deben estar en NixOS. Si XMonad las necesita, van en:
- `~/.xsession` (para sesiones X11)
- O en `xmonad.hs` via `setEnv`

En el nuevo `base/desktop.nix`, NO ponemos estas variables.

### 4.3 DisplaySetupCommand (xrandr) - TODOS LOS HARDWARE

**Principio**: Cada modulo de hardware define SU setup de display. **TODAS las maquinas** que usan XMonad necesitan su xrandr configurado.

```nix
# hardware/nvidia/rtx5080.nix (aurin)
{
  # ...drivers nvidia...

  services.xserver.displayManager.setupCommands = ''
    ${pkgs.xorg.xrandr}/bin/xrandr --output DP-4 --mode 5120x1440 --rate 120 --primary --dpi 96
    ${pkgs.xorg.xset}/bin/xset r rate 350 50
  '';
}

# hardware/nvidia/rtx2060.nix (vespino)
{
  # ...drivers nvidia...

  services.xserver.displayManager.setupCommands = ''
    ${pkgs.xorg.xrandr}/bin/xrandr --output DP-0 --mode 5120x1440 --rate 120 --primary --dpi 96
    ${pkgs.xorg.xset}/bin/xset r rate 350 50
  '';
}

# hardware/apple/macbook-pro-13-2.nix (macbook) - SI TIENE xrandr!
{
  # ...drivers apple...

  # Macbook TAMBIEN usa XMonad, asi que necesita su xrandr
  services.xserver.displayManager.setupCommands = ''
    ${pkgs.xorg.xrandr}/bin/xrandr --output eDP-1 --mode 2560x1600 --rate 60 --dpi 227
    ${pkgs.xorg.xset}/bin/xset r rate 350 50
  '';
}
```

**Nota sobre macbook**: Aunque GDM maneje la sesion GNOME nativa, cuando el usuario selecciona XMonad en GDM, este xrandr se aplica. **Todos los hardware modules que soporten XMonad deben tener displaySetupCommand**.

### 4.4 VPN Vocento - MODULO OPT-IN (SIN FLAGS)

**Filosofia**: No usamos flags como `enableVocentoVPN = true`. En su lugar, el modulo se importa explicitamente solo donde se necesita.

**Ubicacion**: `modules/vocento-vpn.nix` (NO en `modules/base/`)

```nix
# modules/vocento-vpn.nix - Modulo OPT-IN
{ config, lib, pkgs, ... }:

{
  # Bridge br0 para VMs
  networking.bridges.br0.interfaces = [];
  networking.interfaces.br0 = {
    ipv4.addresses = [{ address = "192.168.53.10"; prefixLength = 24; }];
  };

  # Rutas estaticas via VM Ubuntu (192.168.53.12)
  networking.interfaces.br0.ipv4.routes = [
    { address = "10.180.0.0"; prefixLength = 16; via = "192.168.53.12"; }
    { address = "10.182.0.0"; prefixLength = 16; via = "192.168.53.12"; }
    { address = "192.168.196.0"; prefixLength = 24; via = "192.168.53.12"; }
    { address = "10.200.26.0"; prefixLength = 24; via = "192.168.53.12"; }
    { address = "10.184.0.0"; prefixLength = 16; via = "192.168.53.12"; }
    { address = "10.186.0.0"; prefixLength = 16; via = "192.168.53.12"; }
    { address = "34.175.0.0"; prefixLength = 16; via = "192.168.53.12"; }
    { address = "34.13.0.0"; prefixLength = 16; via = "192.168.53.12"; }
  ];

  # NAT para subnet de VMs
  networking.nat = {
    enable = true;
    internalInterfaces = [ "br0" ];
    externalInterface = "enp7s0";  # Ajustar segun maquina
    extraCommands = ''
      iptables -t nat -A POSTROUTING -s 192.168.53.0/24 -j MASQUERADE
    '';
  };

  # DNS pointing to VM
  environment.etc."resolv.conf" = {
    text = ''
      nameserver 192.168.53.12
      nameserver 8.8.8.8
      search grupo.vocento
      options timeout:1 attempts:1 rotate
    '';
  };
}
```

**Uso en flake.nix**:

```nix
# Maquinas CON VPN (tienen la VM Ubuntu corriendo)
aurin = mkSystem {
  hostname = "aurin";
  hardware = [ ./hardware/nvidia/rtx5080.nix ];
  extra = [ ./modules/vocento-vpn.nix ];  # Importa el modulo
};

vespino = mkSystem {
  hostname = "vespino";
  hardware = [ ./hardware/nvidia/rtx2060.nix ];
  extra = [ ./modules/vocento-vpn.nix ];  # Importa el modulo
};

# Maquinas SIN VPN (no tienen la VM Ubuntu)
macbook = mkSystem {
  hostname = "macbook";
  hardware = [ ./hardware/apple/macbook-pro-13-2.nix ];
  # NO importa vocento-vpn.nix
};
```

**Ventajas sobre flags**:
- Mas explicito: ves exactamente que modulos carga cada maquina
- Sin magia: no hay condicionales ocultos en los modulos
- Filosofia NixOS pura: composicion de modulos, no configuracion condicional

### 4.5 Paquetes/Servicios "Especificos"

**Problema aparente**: "Steam solo tiene sentido en maquinas con GPU potente"

**Respuesta filosofica**: Steam va en `base/packages.nix`. TODAS las maquinas lo tienen.

- En aurin: Lo usas, funciona genial con RTX 5080
- En macbook: Lo tienes instalado, pero no lo ejecutas (o corre lento)
- En vespino: Lo tienes, funciona con RTX 2060

**El coste de tener Steam instalado pero no usarlo es ~0.** El beneficio de tenerlo disponible cuando lo necesitas es alto.

Lo mismo aplica a:
- Sunshine: Instalado en todas, solo lo usas donde tiene sentido
- Ollama: Instalado en todas, funciona mejor donde hay GPU
- Syncthing: Instalado en todas, configuras los folders que quieras

---

## 5. Plan de Migracion

### ORDEN DE TESTING CRITICO

```
1. macbook  PRIMERO  - No tiene VPN, imposible romper aurin
2. vespino  SEGUNDO  - Testing ground, tiene VPN pero no es produccion
3. aurin    ULTIMO   - Produccion, VPN SAGRADA
```

**La configuracion VPN de aurin NO SE TOCA hasta que todo lo demas este probado y funcionando.**

---

### FASE 0: Preparacion (sin cambios de codigo)

```bash
# 1. Backup del estado actual
cd ~/dotfiles
git stash  # Si hay cambios locales
git checkout -b refactor/unified-base
git log --oneline -1  # Anotar commit actual

# 2. En cada maquina, guardar generacion
sudo nix-env --list-generations -p /nix/var/nix/profiles/system | tail -3

# 3. Backup de VM Ubuntu VPN (solo aurin/vespino)
virsh snapshot-create-as ubuntu-vpn "pre-refactor-$(date +%Y%m%d)"
```

**Validacion**:
- [ ] Branch `refactor/unified-base` creado
- [ ] Commit actual anotado
- [ ] Generaciones guardadas
- [ ] Snapshot VM (si aplica)

---

### FASE 1: Crear estructura de directorios

```bash
cd ~/dotfiles

# Crear nueva estructura
mkdir -p modules/base
mkdir -p hardware/nvidia
mkdir -p hardware/apple
mkdir -p hardware/audio
mkdir -p experimental
mkdir -p hosts/{aurin,macbook,vespino}
```

**Validacion**:
- [ ] Directorios creados

---

### FASE 2: Crear modules/base/default.nix

Este es el modulo maestro que importa todo lo base.

```nix
# modules/base/default.nix
{ ... }:

{
  imports = [
    ./boot.nix
    ./locale.nix
    ./console.nix
    ./nix-settings.nix
    ./security.nix
    ./packages.nix
    ./services.nix
    ./desktop.nix
    ./users.nix
    ./networking.nix       # SIN VPN - solo NetworkManager base
    ./virtualization.nix
  ];
}
```

**NOTA**: `networking.nix` solo contiene NetworkManager base, SIN configuracion VPN.

**Accion**: Copiar/mover los modulos actuales de `modules/common/` a `modules/base/`, y agregar los nuevos.

**Validacion**:
- [ ] `modules/base/default.nix` creado
- [ ] Todos los .nix movidos
- [ ] `networking.nix` NO tiene VPN

---

### FASE 3: Crear modules/vocento-vpn.nix (OPT-IN)

```nix
# modules/vocento-vpn.nix - MODULO OPT-IN (no en base/)
{ config, lib, pkgs, ... }:

{
  # Toda la config VPN aqui (bridge, rutas, NAT, DNS)
  # Ver seccion 4.4 para contenido completo
}
```

**Validacion**:
- [ ] `modules/vocento-vpn.nix` creado
- [ ] NO esta en `modules/base/`
- [ ] Contiene toda la config VPN extraida de aurin/vespino

---

### FASE 4: Crear modules/base/desktop.nix unificado

```nix
# modules/base/desktop.nix
# TODOS los desktops disponibles en TODAS las maquinas
{ config, pkgs, lib, ... }:

{
  services = {
    # Display Manager - GDM para todos (funciona con GNOME, XMonad, Hyprland, Niri)
    displayManager.gdm.enable = true;

    # X.Org base
    xserver = {
      enable = true;

      # Keyboard layout compartido
      xkb = {
        layout = "us,es";
        options = "grp:alt_shift_toggle,caps:escape";
      };

      # XMonad disponible
      windowManager.xmonad = {
        enable = true;
        enableContribAndExtras = true;
      };
    };

    # GNOME disponible
    desktopManager.gnome.enable = true;

    # Libinput para raton gaming
    libinput = {
      enable = true;
      mouse = {
        accelProfile = "flat";
        accelSpeed = "0";
      };
    };

    # NOTA: NO habilitar picom aqui
    # Picom se gestiona en home-manager y se lanza desde xmonad.hs
  };

  # Hyprland disponible
  programs.hyprland.enable = true;

  # Niri disponible (si existe el modulo)
  # programs.niri.enable = true;

  # NO forzar variables X11/Wayland - cada sesion decide
}
```

**Validacion**:
- [ ] `modules/base/desktop.nix` creado
- [ ] NO tiene picom
- [ ] NO tiene sessionVariables de X11
- [ ] Tiene GDM, GNOME, XMonad, Hyprland

---

### FASE 5: Mover hardware a hardware/

```bash
# Mover modulos de hardware
mv nixos-aurin/etc/nixos/modules/nvidia-rtx5080.nix hardware/nvidia/rtx5080.nix
mv nixos-aurin/etc/nixos/modules/audio-fiio-k7.nix hardware/audio/fiio-k7.nix
mv nixos-macbook/etc/nixos/modules/apple-hardware.nix hardware/apple/macbook-pro-13-2.nix
mv nixos-macbook/etc/nixos/modules/snd-hda-macbookpro.nix hardware/apple/

# Mover hardware-configuration.nix
mv nixos-aurin/etc/nixos/hardware-configuration.nix hosts/aurin/
mv nixos-macbook/etc/nixos/hardware-configuration.nix hosts/macbook/
mv nixos-vespino/etc/nixos/hardware-configuration.nix hosts/vespino/
```

**IMPORTANTE**: Anadir displaySetupCommand a TODOS los modulos de hardware:

```nix
# hardware/apple/macbook-pro-13-2.nix - INCLUYE xrandr!
{
  # ... config Apple ...

  services.xserver.displayManager.setupCommands = ''
    ${pkgs.xorg.xrandr}/bin/xrandr --output eDP-1 --mode 2560x1600 --rate 60 --dpi 227
    ${pkgs.xorg.xset}/bin/xset r rate 350 50
  '';
}
```

**Validacion**:
- [ ] Modulos de hardware en `hardware/`
- [ ] `hardware-configuration.nix` en `hosts/<hostname>/`
- [ ] TODOS los hardware modules tienen displaySetupCommand (incluido macbook)

---

### FASE 6: Crear modulo nvidia-rtx2060.nix para vespino

Vespino tiene la config NVIDIA inline. Extraerla a modulo:

```nix
# hardware/nvidia/rtx2060.nix
{ config, pkgs, lib, ... }:

{
  # NVIDIA RTX 2060 - Drivers propietarios (no open, GPU antigua)
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    nvidia = {
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      modesetting.enable = true;
      open = false;  # GPU antigua, usar propietario
      nvidiaSettings = true;
      forceFullCompositionPipeline = true;
    };
  };

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };

  # Display setup para este hardware
  services.xserver.displayManager.setupCommands = ''
    ${pkgs.xorg.xrandr}/bin/xrandr --output DP-0 --mode 5120x1440 --rate 120 --primary --dpi 96
    ${pkgs.xorg.xset}/bin/xset r rate 350 50
  '';
}
```

**Validacion**:
- [ ] `hardware/nvidia/rtx2060.nix` creado
- [ ] Tiene displaySetupCommand

---

### FASE 7: Crear home-manager/machines/*.nix MINIMOS

```nix
# home-manager/machines/aurin.nix - SOLO preferencias de hardware
{
  dotfiles.picom.backend = "glx";
  dotfiles.xmobar.dpi = 96;
}

# home-manager/machines/macbook.nix - SOLO preferencias de hardware
{
  dotfiles.picom.backend = "xrender";
  dotfiles.xmobar.dpi = 227;
}

# home-manager/machines/vespino.nix - SOLO preferencias de hardware
{
  dotfiles.picom.backend = "glx";
  dotfiles.xmobar.dpi = 96;
}
```

**TODO lo demas va en `home-manager/passh.nix`**.

**Validacion**:
- [ ] `home-manager/machines/*.nix` son MINIMOS
- [ ] Solo contienen opciones dependientes del hardware
- [ ] Todo lo demas esta en `passh.nix`

---

### FASE 8: Mover minecraft.nix a experimental/

```bash
mv nixos-vespino/etc/nixos/minecraft.nix experimental/
```

**Validacion**:
- [ ] `experimental/minecraft.nix` existe

---

### FASE 9: Actualizar flake.nix

Reemplazar el flake.nix actual con la version simplificada (ver seccion 2).

**IMPORTANTE**: Orden de testing:

```bash
# 1. MACBOOK PRIMERO (no tiene VPN, imposible romper aurin)
sudo nixos-rebuild test --flake ~/dotfiles#macbook --impure

# Si funciona:
sudo nixos-rebuild switch --flake ~/dotfiles#macbook --impure

# Si falla:
sudo nixos-rebuild switch --rollback

# 2. VESPINO SEGUNDO (testing ground con VPN)
sudo nixos-rebuild test --flake ~/dotfiles#vespino --impure

# Si funciona:
sudo nixos-rebuild switch --flake ~/dotfiles#vespino --impure

# 3. AURIN ULTIMO (produccion, VPN sagrada)
# SOLO despues de que macbook y vespino funcionen perfectamente
sudo nixos-rebuild test --flake ~/dotfiles#aurin --impure

# Si funciona:
sudo nixos-rebuild switch --flake ~/dotfiles#aurin --impure
```

**Validacion**:
- [ ] macbook funciona (PRIMERO)
- [ ] vespino funciona (SEGUNDO)
- [ ] aurin funciona (ULTIMO)
- [ ] Commit: "refactor: unified base architecture"

---

### FASE 10: Limpiar estructura antigua

Una vez todo funciona:

```bash
# Eliminar configurations.nix antiguos (ya no se usan)
rm -rf nixos-aurin/etc/nixos/
rm -rf nixos-macbook/etc/nixos/
rm -rf nixos-vespino/etc/nixos/

# Eliminar modules/common/ (ahora es modules/base/)
rm -rf modules/common/

# Eliminar modules/desktop/ antiguo (ahora esta en base/desktop.nix)
rm -rf modules/desktop/
```

**Validacion**:
- [ ] Solo queda la estructura nueva
- [ ] Commit: "cleanup: remove legacy configuration structure"

---

### FASE 11: Verificar picom en home-manager

Asegurarse de que xmonad.hs lanza picom:

```haskell
-- xmonad/.config/xmonad/xmonad.hs
import XMonad.Util.SpawnOnce

myStartupHook :: X ()
myStartupHook = do
  spawnOnce "picom --config ~/.config/picom/picom.conf &"
  -- ... resto del startup ...
```

**Validacion**:
- [ ] xmonad.hs lanza picom
- [ ] Picom funciona en sesion XMonad
- [ ] GNOME funciona sin conflictos

---

## 6. Rollback y Recuperacion

### Rollback Inmediato

```bash
# Si algo falla despues de switch:
sudo nixos-rebuild switch --rollback
```

### Rollback a Generacion Especifica

```bash
# Listar generaciones:
sudo nix-env --list-generations -p /nix/var/nix/profiles/system

# Rollback a generacion N:
sudo nix-env --switch-generation N -p /nix/var/nix/profiles/system
sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch
```

### Rollback de Git

```bash
cd ~/dotfiles
git log --oneline -10
git checkout <commit-anterior>
sudo nixos-rebuild switch --flake ~/dotfiles#<hostname> --impure
```

### Recuperacion de Emergencia (Boot Viejo)

1. Reiniciar y en GRUB seleccionar generacion anterior
2. Una vez dentro: `sudo nixos-rebuild switch --rollback`

### Recuperacion VPN

Si VPN deja de funcionar:

```bash
# 1. Verificar VM
virsh list --all
virsh start ubuntu-vpn

# 2. Verificar rutas
ip route | grep 192.168.53

# 3. Si falla, restaurar snapshot
virsh snapshot-revert ubuntu-vpn pre-refactor-YYYYMMDD

# 4. Rollback NixOS
sudo nixos-rebuild switch --rollback
```

---

## Resumen Visual

```
ANTES (complejo, duplicado):
+-----------------------------------------------------------------+
| flake.nix                                                       |
|   +-- nixos-aurin/configuration.nix (~520 lineas)               |
|   |     +-- imports locales + logica especifica                 |
|   +-- nixos-macbook/configuration.nix (~230 lineas)             |
|   |     +-- workarounds manuales                                |
|   +-- nixos-vespino/configuration.nix (~440 lineas)             |
|         +-- duplicacion con aurin                               |
+-----------------------------------------------------------------+

DESPUES (simple, unificado):
+-----------------------------------------------------------------+
| flake.nix (SIN FLAGS)                                           |
|   +-- modules/base/ (TODO identico para TODAS)                  |
|   |     +-- packages, services, desktop, users, networking      |
|   +-- modules/vocento-vpn.nix (OPT-IN via extra=[])             |
|   +-- hardware/ (SOLO drivers, cada uno con displaySetupCommand)|
|   |     +-- nvidia/rtx5080, nvidia/rtx2060, apple/macbook-pro   |
|   +-- hosts/<hostname>/ (SOLO hardware-configuration.nix)       |
|   +-- home-manager/machines/*.nix (MINIMO: picom backend, dpi)  |
+-----------------------------------------------------------------+

Resultado: 3 maquinas IDENTICAS, solo difieren en hardware.
           VPN es modulo OPT-IN, no flag.
           macbook TAMBIEN tiene xrandr en hardware module.
           Testing: macbook -> vespino -> aurin (SIEMPRE este orden).
```

---

## Preguntas Respondidas

### 1. El conflicto picom/GNOME: Debe picom ir en home-manager?

**SI.** Picom ya esta en `modules/home-manager/programs/picom.nix` y funciona. Solo hay que:
- Quitar `services.picom` de NixOS
- Lanzar picom desde xmonad.hs con `spawnOnce`

### 2. Que hacemos con las configuraciones VPN de Vocento?

**Modulo OPT-IN sin flags.** `modules/vocento-vpn.nix` se importa via `extra = []` en las maquinas que tienen la VM Ubuntu (aurin, vespino). Macbook simplemente no lo importa.

### 3. DisplaySetupCommand (xrandr) debe ir en hardware o en otro sitio?

**En hardware, TODAS las maquinas.** Cada modulo de hardware define su propio `displayManager.setupCommands`. **Macbook tambien**, ya que usa XMonad y necesita su xrandr configurado (2560x1600@60Hz, DPI 227).

### 4. Que debe contener home-manager/machines/*.nix?

**MINIMO - solo opciones dependientes del hardware:**
- `dotfiles.picom.backend` (glx para NVIDIA, xrender para Intel)
- `dotfiles.xmobar.dpi` (96 para monitores normales, 227 para HiDPI)

Todo lo demas va en `home-manager/passh.nix` (igual para todas las maquinas).

### 5. Cual es el orden de testing?

**macbook -> vespino -> aurin (SIEMPRE)**
1. macbook primero: No tiene VPN, imposible romper aurin
2. vespino segundo: Testing ground, tiene VPN pero no es produccion
3. aurin ultimo: Produccion, VPN sagrada

---

## Comandos de Referencia

```bash
# Rebuild y test (SIEMPRE --impure para hosts Vocento)
sudo nixos-rebuild test --flake ~/dotfiles#<hostname> --impure
sudo nixos-rebuild switch --flake ~/dotfiles#<hostname> --impure
sudo nixos-rebuild dry-build --flake ~/dotfiles#<hostname> --impure

# Rollback
sudo nixos-rebuild switch --rollback

# Ver generaciones
sudo nix-env --list-generations -p /nix/var/nix/profiles/system

# Git
git status
git log --oneline -5
git checkout <commit>
```

---

**Ultima actualizacion**: 2026-01-18 (v2 - cambios acordados)
