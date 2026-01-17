# =============================================================================
# NixOS Macbook - MacBook Pro 13,2 (2016)
# =============================================================================
# Laptop Apple con Touch Bar para uso movil
#
# Hardware:
#   - CPU: Intel Core i5/i7-6xxx (Skylake)
#   - RAM: 8/16GB
#   - Display: Retina 2560x1600 (227 DPI)
#   - GPU: Intel Iris Graphics 550
#   - Storage: SSD externo 4TB via Thunderbolt 3
#   - Input: SPI Keyboard + Force Touch Trackpad
#   - Touch Bar: OLED con T1 chip
#   - WiFi: Broadcom BCM43602
#   - Ports: 4x Thunderbolt 3 (USB-C)
#
# Perfiles nixos-hardware usados (via flake.nix extraModules):
#   - apple-macbook-pro: Base Apple (mbpfan, facetimehd, Intel CPU/GPU, laptop)
#   - common-pc-ssd: Optimizaciones SSD (fstrim)
#
# Modulos locales:
#   - apple-hardware.nix: Drivers SPI, Touch Bar, Broadcom WiFi, HiDPI
#   - snd-hda-macbookpro.nix: Driver audio CS8409
#
# Modulos compartidos (via flake.nix):
#   - modules/common/*: locale, console, boot, packages, services, users, etc.
#   - modules/desktop/xmonad.nix: Window manager + X11
#   - modules/desktop/hyprland.nix: Wayland compositor
#   - modules/desktop/niri.nix: Wayland compositor
#
# Usuario:
#   - Definido en modules/common/users.nix (compartido)
#
# Instalacion:
#   1. Boot USB NixOS
#   2. Conectar SSD TB3
#   3. Particionar SSD: EFI (512MB) + root (ext4) + swap (opcional)
#   4. Mount y nixos-generate-config
#   5. Copiar esta config + hardware-configuration.nix generado
#   6. nixos-install
#
# Flake:
#   sudo nixos-rebuild switch --flake ~/dotfiles#macbook
# =============================================================================

{ config, pkgs, lib, ... }:

{
  imports = [
    # Hardware configuration generado por nixos-generate-config
    ./hardware-configuration.nix

    # Modulo hardware especifico MacBook Pro 13,2
    # Incluye: SPI drivers, Touch Bar, Broadcom WiFi, HiDPI, audio quirks
    ./modules/apple-hardware.nix

    # Driver de audio CS8409 para MacBook (reemplaza el del kernel)
    ./modules/snd-hda-macbookpro.nix

    # NOTA: NO importar modules/desktop/xmonad.nix en macbook
    # Ese módulo añade XFCE, picom, y variables X11 que conflictúan con GDM+GNOME
    # XMonad se configura directamente abajo de forma compatible con GNOME

    # nixos-hardware profiles: Se importan via flake.nix extraModules
    # - nixos-hardware.nixosModules.apple-macbook-pro
    # - nixos-hardware.nixosModules.common-pc-ssd
    #
    # Home Manager: Se integra via flake.nix enableHomeManager = true
    # Usuario passh: Definido en modules/common/users.nix (via flake)
  ];

  # ===========================================================================
  # XMONAD CONFIG (configuración directa, sin módulo compartido)
  # ===========================================================================
  # El módulo compartido xmonad.nix conflictúa con GDM+GNOME por:
  # - picom (conflicto con Mutter)
  # - XFCE fallback (añade sesiones que confunden a GDM)
  # - Variables X11 forzadas
  # Aquí solo habilitamos xmonad de forma mínima y compatible

  # ===========================================================================
  # OVERRIDES de modulos comunes (valores especificos de macbook)
  # ===========================================================================

  # Console: HiDPI necesita fuente grande
  common.console.fontSize = "hidpi";

  # WiFi BCM43602: Driver wl (broadcom_sta) NO FUNCIONA en kernel 6.x
  # Compila pero falla en runtime. Usar USB WiFi dongle en su lugar.

  # ===========================================================================
  # CONFIGURACION ESPECIFICA DE MACBOOK
  # ===========================================================================
  # Todo lo que sigue es UNICO de macbook y NO debe estar en modulos comunes

  # ===== NETWORKING =====
  networking = {
    hostName = "macbook";
    networkmanager.enable = true;

    # Firewall basico
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];  # SSH
    };
  };

  # ===== SERVICES (especificos de macbook) =====
  services = {
    # SSH (settings conservadores para laptop)
    openssh.settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;
    };

    # X11 Desktop con GNOME + XMonad
    xserver = {
      enable = true;

      # XMonad como window manager alternativo (seleccionable en GDM)
      windowManager.xmonad = {
        enable = true;
        enableContribAndExtras = true;
      };

      # Keyboard layout
      xkb = {
        layout = "us,es";
        options = "grp:alt_shift_toggle,caps:escape";
      };
    };

    # GDM + GNOME (sesión por defecto)
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
    # NO usar defaultSession - el set-session script rompe GDM

    # keyd: Remapeador de teclas a nivel kernel (funciona en X11 y Wayland)
    # Permite usar Fn + fila numerica como F-keys (workaround Touch Bar)
    keyd = {
      enable = true;
      keyboards = {
        # Configuracion para Apple SPI Keyboard (Spanish ISO)
        apple = {
          ids = [ "0000:0000" ];  # Apple SPI Keyboard especifico
          settings = {
            main = {
              # La tecla Fn del Mac (KEY_FN = scancode 464)
              # Se convierte en modificador que activa la capa "fnlayer"
              "fn" = "layer(fnlayer)";

              # Fix swap de teclas en teclado Apple Spanish ISO
              # La tecla junto al 1 (grave) y la tecla entre Shift-Z (102nd) estan intercambiadas
              # grave produce <> pero deberia producir
              # 102nd produce pero deberia producir <>
              "grave" = "102nd";
              "102nd" = "grave";
            };
            # Capa activada al mantener Fn pulsado
            "fnlayer" = {
              # Fn + (tecla junto al 1 en teclado espanol ISO) = Escape
              # En keyd esta tecla se llama "grave" (posicion fisica, no caracter)
              "grave" = "esc";
              # Tambien la tecla <> (entre Shift izq y Z en ISO) por si acaso
              "102nd" = "esc";
              # Fn + numeros = F-keys
              "1" = "f1";
              "2" = "f2";
              "3" = "f3";
              "4" = "f4";
              "5" = "f5";
              "6" = "f6";
              "7" = "f7";
              "8" = "f8";
              "9" = "f9";
              "0" = "f10";
              "-" = "f11";
              "=" = "f12";
              # Fn + teclas de navegacion
              "backspace" = "delete";
              "left" = "home";
              "right" = "end";
              "up" = "pageup";
              "down" = "pagedown";
            };
          };
        };
      };
    };

    # Syncthing (comentado - habilitar si se quiere sync con otros hosts)
    # syncthing = {
    #   enable = true;
    #   user = "passh";
    #   dataDir = "/home/passh";
    #   openDefaultPorts = true;
    # };

    # lid close: no suspender (el MacBook no se recupera bien)
    logind.settings.Login = {
      HandleLidSwitch = "ignore";
      HandleLidSwitchExternalPower = "ignore";
      HandleLidSwitchDocked = "ignore";
    };
  };

  # ===== VIRTUALIZATION (Docker para desarrollo) =====
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };

  # ===== SECURITY (macbook: laptop, seguridad con password) =====
  security.sudo.wheelNeedsPassword = true;

  # ===== POWER MANAGEMENT =====
  # Deshabilitar suspension - el MacBook no se recupera bien
  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
  };

  # ===== SYSTEM PACKAGES (solo especificos de MacBook) =====
  # Los paquetes comunes estan en modules/common/packages.nix
  environment.systemPackages = with pkgs; [
    # Nada especifico por ahora - todo viene de modulos comunes
  ];

  system.stateVersion = "24.11";
}
