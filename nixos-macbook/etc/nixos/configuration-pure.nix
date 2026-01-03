# =============================================================================
# NixOS Configuration - MacBook Pro 13,2 (2016) - PURE FLAKE
# =============================================================================
# Configuración pura sin fetchTarball ni channels
#
# Hardware: MacBook Pro 13" 2016 con Touch Bar
# - CPU: Intel Core i5/i7 Skylake
# - Display: Retina 2560x1600 (227 DPI)
# - GPU: Intel Iris Graphics 550
# - WiFi: Broadcom BCM43602
# - Touch Bar: OLED con T1 chip
#
# Instalación target: USB 128GB (para probar)
#
# nixos-hardware (via flake inputs):
#   - apple-macbook-pro: Base Apple + Intel + laptop
#   - common-pc-ssd: Optimizaciones SSD
#
# Módulos locales compartidos:
#   - desktop/xmonad.nix: XMonad + X11
#   - common/*: packages, services, users
#   - home-manager: Usuario passh
#
# Módulo específico macbook:
#   - modules/apple-hardware.nix: WiFi Broadcom, SPI, Touch Bar, HiDPI
#
# Build:
#   sudo nixos-rebuild switch --flake ~/dotfiles#macbook
# =============================================================================

{ config, pkgs, lib, ... }:

{
  # ===========================================================================
  # IMPORTS
  # ===========================================================================
  imports = [
    # Hardware configuration (generado por nixos-generate-config)
    ./hardware-configuration.nix

    # Módulo hardware específico MacBook Pro 13,2
    ./modules/apple-hardware.nix

    # Módulos compartidos (common)
    ../../modules/common/packages.nix
    ../../modules/common/services.nix
    ../../modules/common/users.nix

    # Desktop environment: XMonad
    ../../modules/desktop/xmonad.nix

    # Home Manager se integra via flake (no usa <home-manager/nixos>)
  ];

  # ===========================================================================
  # SYSTEM CONFIG
  # ===========================================================================
  networking.hostName = "macbook";

  # Timezone
  time.timeZone = "Europe/Madrid";

  # Locale
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
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

  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # ===========================================================================
  # BOOT
  # ===========================================================================
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  # ===========================================================================
  # NETWORKING
  # ===========================================================================
  networking.networkmanager.enable = true;

  # ===========================================================================
  # XMONAD CONFIG
  # ===========================================================================
  # Configuración específica del display MacBook Pro 13,2
  desktop.xmonad = {
    enable = true;

    # Retina 2560x1600 @ 60Hz con HiDPI (scaling x2 = 1280x800 efectivo)
    displaySetupCommand = ''
      ${pkgs.xorg.xrandr}/bin/xrandr --output eDP-1 --mode 2560x1600 --rate 60 --primary --dpi 227
    '';

    # Intel graphics usa xrender
    picomBackend = "xrender";

    refreshRate = 60;
  };

  # ===========================================================================
  # NIX CONFIG
  # ===========================================================================
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };

    # Garbage collection semanal
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  # ===========================================================================
  # STATEVERSION
  # ===========================================================================
  # NO CAMBIAR ESTE VALOR
  # https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion
  system.stateVersion = "24.05";
}
