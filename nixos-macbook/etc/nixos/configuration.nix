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

    # nixos-hardware profiles: Se importan via flake.nix extraModules
    # - nixos-hardware.nixosModules.apple-macbook-pro
    # - nixos-hardware.nixosModules.common-pc-ssd
    #
    # Home Manager: Se integra via flake.nix enableHomeManager = true
  ];

  # ===== UNFREE =====
  # Necesario para algunos drivers y firmware
  nixpkgs.config.allowUnfree = true;

  # WiFi BCM43602: Driver wl (broadcom_sta) NO FUNCIONA en kernel 6.x
  # Compila pero falla en runtime. Usar USB WiFi dongle en su lugar.

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

      # Window Manager
      windowManager.xmonad = {
        enable = true;
        enableContribAndExtras = true;
      };

      # Keyboard layout
      xkb = {
        layout = "us,es";
        variant = "";
        # Caps Lock → Escape (workaround Touch Bar sin funcionar)
        options = "caps:escape";
      };
    };

    # Display Manager (opcion movida de xserver)
    displayManager.gdm.enable = true;

    # GNOME Desktop (nueva ubicación, fuera de xserver)
    desktopManager.gnome.enable = true;

    # SSH
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = true;
      };
    };

    # Bluetooth manager (GUI para XMonad)
    blueman.enable = true;

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

  # ===== FONTS =====
  fonts.packages = with pkgs; [
    # Nerd Fonts (para alacritty, xmobar, etc)
    nerd-fonts.hack
    nerd-fonts.monoid
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    # Fuentes básicas
    dejavu_fonts
    liberation_ttf
    noto-fonts
    noto-fonts-color-emoji
  ];

  # ===== SYSTEM PACKAGES =====
  environment.systemPackages = with pkgs; [
    # Terminal
    alacritty  # Ya es unstable via flake
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

    # Bluetooth GUI (para XMonad)
    blueman

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
