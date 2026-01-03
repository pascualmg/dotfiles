# =============================================================================
# NixOS 24.04 - MacBook Pro 13,2 (2016)
# =============================================================================
# CONFIGURACION OPTIMIZADA PARA NIXOS 24.04 (nixos-24.05 NO ARRANCA)
#
# Hardware:
#   - CPU: Intel Core i5/i7-6xxx (Skylake)
#   - RAM: 8/16GB
#   - Display: Retina 2560x1600 (227 DPI)
#   - GPU: Intel Iris Graphics 550
#   - Storage: USB externo 128GB (para pruebas)
#   - Input: SPI Keyboard + Force Touch Trackpad
#   - Touch Bar: OLED con T1 chip
#   - WiFi: Broadcom BCM43602 (PROBLEMATICO - requiere broadcom_sta)
#   - Ports: 4x Thunderbolt 3 (USB-C)
#
# NOTAS IMPORTANTES:
#   - WiFi Broadcom: Detecta redes pero NO conecta en Live USB
#     -> Usar USB WiFi/Ethernet externo para instalacion
#     -> Despues de instalar, broadcom_sta deberia funcionar
#   - Teclado/Trackpad: Funcionan en Live USB 24.04
#     -> Drivers SPI incluidos en esta config para sistema instalado
#
# INSTALACION:
#   1. Boot USB NixOS 24.04 (24.05 NO funciona)
#   2. Conectar USB 128GB para instalacion
#   3. Conectar USB WiFi/Ethernet para Internet
#   4. Seguir guia de particionado en README.org
#   5. Copiar esta config a /mnt/etc/nixos/configuration.nix
#   6. nixos-install
#
# ARCHIVOS:
#   - configuration-24.04.nix (este archivo) -> /etc/nixos/configuration.nix
#   - hardware-configuration.nix (generar con nixos-generate-config)
#   - modules/apple-hardware.nix -> /etc/nixos/modules/
# =============================================================================

{ config, pkgs, lib, ... }:

let
  # =========================================================================
  # NIXOS-HARDWARE: Perfiles Apple desde repositorio oficial
  # =========================================================================
  # Usamos fetchTarball con revision especifica para reproducibilidad
  # Actualizar revision periodicamente desde:
  #   https://github.com/NixOS/nixos-hardware/commits/master
  #
  # Para NixOS 24.04 usamos una revision compatible (enero 2024)
  nixos-hardware = fetchTarball {
    url = "https://github.com/NixOS/nixos-hardware/archive/936e115319d90c5034c1918bac28ee85455bc5ba.tar.gz";
    # sha256 se puede obtener con:
    #   nix-prefetch-url --unpack <url>
    # Comentado para permitir primera evaluacion:
    # sha256 = "...";
  };

  # Canal unstable para paquetes recientes (opcional)
  # Comentar si causa problemas en 24.04
  unstable = import (fetchTarball {
    url = "https://github.com/nixos/nixpkgs/archive/nixos-unstable.tar.gz";
    # sha256 = "...";  # Descomentar y llenar para reproducibilidad
  }) {
    config = config.nixpkgs.config;
  };

in {
  imports = [
    # Hardware-configuration generado por nixos-generate-config
    # CRITICO: Reemplazar con el generado durante instalacion
    ./hardware-configuration.nix

    # Modulo hardware especifico MacBook Pro 13,2
    # Contiene: SPI drivers, Touch Bar, Broadcom WiFi, HiDPI, audio
    ./modules/apple-hardware.nix

    # nixos-hardware profiles
    # - apple-macbook-pro: Base Apple (mbpfan, facetimehd, Intel, laptop)
    # - common-pc-ssd: Optimizaciones SSD (fstrim timer)
    "${nixos-hardware}/apple/macbook-pro"
    "${nixos-hardware}/common/pc/ssd"
  ];

  # ===========================================================================
  # NIXPKGS CONFIG
  # ===========================================================================
  # CRITICO: allowUnfree REQUERIDO para:
  #   - broadcom_sta (WiFi driver)
  #   - Intel microcode
  #   - Firmware propietario
  nixpkgs.config.allowUnfree = true;

  # ===========================================================================
  # CONSOLE (antes de X11)
  # ===========================================================================
  console = {
    earlySetup = true;
    font = "ter-p32n";  # Font grande para HiDPI (Retina)
    packages = [ pkgs.terminus_font ];
    keyMap = "us";
  };

  # ===========================================================================
  # BOOT
  # ===========================================================================
  boot.loader = {
    # systemd-boot es mas simple y funciona bien con MacBook
    systemd-boot = {
      enable = true;
      # Mostrar menu por defecto (util para debug)
      consoleMode = "max";
      # Timeout antes de auto-boot
      timeout = 5;
    };
    efi.canTouchEfiVariables = true;
  };

  # ===========================================================================
  # NETWORKING
  # ===========================================================================
  networking = {
    hostName = "macbook";

    # NetworkManager es mas amigable para laptops
    networkmanager = {
      enable = true;
      # WiFi backend (wpa_supplicant por defecto, iwd es alternativa)
      wifi.backend = "wpa_supplicant";
    };

    # Firewall basico
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];  # SSH
      # Puertos adicionales si necesitas
      # allowedTCPPorts = [ 22 80 443 8080 ];
    };
  };

  # ===========================================================================
  # TIMEZONE & LOCALE
  # ===========================================================================
  time.timeZone = "Europe/Madrid";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "es_ES.UTF-8";
      LC_IDENTIFICATION = "es_ES.UTF-8";
      LC_MEASUREMENT = "es_ES.UTF-8";
      LC_MONETARY = "es_ES.UTF-8";
      LC_NAME = "es_ES.UTF-8";
      LC_NUMERIC = "es_ES.UTF-8";
      LC_PAPER = "es_ES.UTF-8";
      LC_TELEPHONE = "es_ES.UTF-8";
      LC_TIME = "es_ES.UTF-8";
    };
  };

  # ===========================================================================
  # USER
  # ===========================================================================
  users.users.passh = {
    isNormalUser = true;
    description = "passh";
    extraGroups = [
      "wheel"           # sudo
      "networkmanager"  # WiFi control
      "audio"           # Audio devices
      "video"           # GPU, backlight
      "input"           # Input devices (teclado/trackpad)
      "docker"          # Docker (si lo usas)
    ];
    shell = pkgs.fish;
    # Password inicial (cambiar despues con passwd)
    # initialPassword = "nixos";  # Descomentar para primer boot
  };

  # ===========================================================================
  # SERVICES
  # ===========================================================================
  services = {
    # X11 Desktop
    xserver = {
      enable = true;

      # Display Manager: GDM (funciona bien con HiDPI)
      displayManager.gdm = {
        enable = true;
        wayland = false;  # X11 por defecto (mas estable en MacBook)
      };

      # Window Manager: XMonad
      windowManager.xmonad = {
        enable = true;
        enableContribAndExtras = true;
      };

      # Alternativa: GNOME (descomentar si prefieres)
      # desktopManager.gnome.enable = true;

      # Keyboard layout
      xkb = {
        layout = "us,es";
        variant = "";
        options = "grp:alt_shift_toggle";  # Alt+Shift para cambiar layout
      };
    };

    # SSH Server
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = true;  # Cambiar a false cuando configures keys
      };
    };

    # Printing (opcional)
    printing.enable = true;

    # Avahi para descubrimiento de red
    avahi = {
      enable = true;
      nssmdns4 = true;
    };
  };

  # ===========================================================================
  # PROGRAMS
  # ===========================================================================
  programs = {
    # Fish shell
    fish.enable = true;

    # Git
    git.enable = true;

    # nix-ld para binarios dinamicos
    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        stdenv.cc.cc.lib
        zlib
        openssl
      ];
    };

    # Light para control de backlight (alternativa a brightnessctl)
    light.enable = true;
  };

  # ===========================================================================
  # VIRTUALIZATION (opcional)
  # ===========================================================================
  virtualisation = {
    docker = {
      enable = true;
      autoPrune.enable = true;
    };
  };

  # ===========================================================================
  # SECURITY
  # ===========================================================================
  security = {
    polkit.enable = true;
    sudo.wheelNeedsPassword = true;  # Seguridad para laptop
  };

  # ===========================================================================
  # SYSTEM PACKAGES
  # ===========================================================================
  environment.systemPackages = with pkgs; [
    # Terminal
    alacritty
    tmux

    # Editors
    vim
    emacs

    # Dev tools
    git
    curl
    wget
    tree
    unzip
    ripgrep
    fd
    jq
    htop
    btop

    # Network tools (importantes para debug WiFi)
    networkmanagerapplet
    wpa_supplicant_gui  # GUI para WiFi
    iw
    wirelesstools

    # System info
    neofetch
    inxi
    lshw
    pciutils
    usbutils

    # LSP Nix
    nil
    nixd

    # Home Manager
    home-manager

    # Extras
    file
    which
    gnumake
    gcc
  ];

  # ===========================================================================
  # NIX SETTINGS
  # ===========================================================================
  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
      # Trusted users para operaciones nix
      trusted-users = [ "root" "passh" ];
    };

    # Garbage collection semanal
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };

  # ===========================================================================
  # STATE VERSION
  # ===========================================================================
  # CRITICO: Debe coincidir con la version de NixOS instalada
  # Para NixOS 24.04, usar "24.05" (el .05 es la convencion de NixOS)
  # NO cambiar despues de instalar
  system.stateVersion = "24.05";
}
