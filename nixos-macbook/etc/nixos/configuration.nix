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
# Perfiles nixos-hardware usados:
#   - apple-macbook-pro: Base Apple (mbpfan, facetimehd, Intel CPU/GPU, laptop)
#   - common-pc-ssd: Optimizaciones SSD (fstrim)
#
# Modulos locales:
#   - apple-hardware.nix: Drivers SPI, Touch Bar, Broadcom WiFi, HiDPI
#
# Instalacion:
#   1. Boot USB NixOS
#   2. Conectar SSD TB3
#   3. Particionar SSD: EFI (512MB) + root (ext4) + swap (opcional)
#   4. Mount y nixos-generate-config
#   5. Copiar esta config + hardware-configuration.nix generado
#   6. nixos-install
#
# Stow:
#   sudo stow -v -t / nixos-macbook
#   sudo nixos-rebuild switch
# =============================================================================

{ config, pkgs, lib, ... }:

let
  # Canal unstable para paquetes recientes
  unstable = import (fetchTarball
    "https://github.com/nixos/nixpkgs/archive/nixos-unstable.tar.gz") {
      config = config.nixpkgs.config;
    };
in {
  imports = [
    # Hardware configuration generado por nixos-generate-config
    ./hardware-configuration.nix

    # Modulo hardware especifico MacBook Pro 13,2
    # Incluye: SPI drivers, Touch Bar, Broadcom WiFi, HiDPI, audio quirks
    ./modules/apple-hardware.nix

    # nixos-hardware profiles (importar via nix-channel o flake)
    # OPCION A: Via nix-channel (tradicional)
    #   sudo nix-channel --add https://github.com/NixOS/nixos-hardware/archive/master.tar.gz nixos-hardware
    #   sudo nix-channel --update
    #   Luego descomentar:
    # <nixos-hardware/apple/macbook-pro>
    # <nixos-hardware/common/pc/ssd>

    # OPCION B: Via fetchTarball (sin channels)
    # (Descomentado para uso inmediato)
    "${builtins.fetchTarball "https://github.com/NixOS/nixos-hardware/archive/master.tar.gz"}/apple/macbook-pro"
    "${builtins.fetchTarball "https://github.com/NixOS/nixos-hardware/archive/master.tar.gz"}/common/pc/ssd"

    # Home Manager (opcional - descomentar si usas channels)
    # <home-manager/nixos>
  ];

  # ===== UNFREE =====
  # CRITICO: Necesario para firmware Broadcom WiFi
  nixpkgs.config.allowUnfree = true;

  # ===== CONSOLE =====
  console = {
    earlySetup = true;
    font = "ter-p32n";  # Font grande para HiDPI
    packages = [ pkgs.terminus_font ];
    keyMap = "us";
  };

  # ===== BOOT =====
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

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

  # ===== TIMEZONE & LOCALE =====
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

  # ===== USER =====
  users.users.passh = {
    isNormalUser = true;
    description = "passh";
    extraGroups = [
      "wheel"
      "networkmanager"
      "audio"
      "video"
      "input"
      "docker"
      "libvirtd"
    ];
    shell = pkgs.fish;
  };

  # ===== SERVICES =====
  services = {
    # X11 Desktop
    xserver = {
      enable = true;

      # Display Manager
      displayManager.gdm.enable = true;

      # Desktop (elegir uno)
      # desktopManager.gnome.enable = true;
      windowManager.xmonad = {
        enable = true;
        enableContribAndExtras = true;
      };

      # Keyboard layout
      xkb = {
        layout = "us,es";
        variant = "";
      };
    };

    # SSH
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = true;
      };
    };

    # Printing (opcional)
    # printing.enable = true;

    # Syncthing (opcional - sincronizar org con otros hosts)
    # syncthing = {
    #   enable = true;
    #   user = "passh";
    #   dataDir = "/home/passh";
    #   openDefaultPorts = true;
    # };
  };

  # ===== PROGRAMS =====
  programs = {
    fish.enable = true;
    git.enable = true;

    # nix-ld para binarios dinamicos
    nix-ld = {
      enable = true;
      libraries = with pkgs; [ ];
    };
  };

  # ===== VIRTUALIZATION (opcional) =====
  virtualisation = {
    docker = {
      enable = true;
      autoPrune.enable = true;
    };

    # libvirtd.enable = true;  # Descomentar si necesitas VMs
  };

  # ===== SECURITY =====
  security = {
    polkit.enable = true;
    sudo.wheelNeedsPassword = true;  # Seguridad laptop
  };

  # ===== SYSTEM PACKAGES =====
  environment.systemPackages = with pkgs; [
    # Terminal
    unstable.alacritty
    tmux
    byobu

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

    # System
    htop
    btop
    neofetch

    # Network
    networkmanagerapplet

    # LSP Nix
    nil
    nixd

    # Home Manager
    home-manager
  ];

  # ===== NIX SETTINGS =====
  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };

  system.stateVersion = "24.11";
}
