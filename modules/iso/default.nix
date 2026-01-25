# =============================================================================
# MODULES/ISO - Configuracion para ISO Live booteable
# =============================================================================
# Genera una ISO con TODO tu entorno pre-instalado:
#   - XMonad + xmobar configurados
#   - Fish shell con tus aliases
#   - Todos tus paquetes
#   - Git + acceso al flake para instalacion
#
# GENERAR ISO:
#   nix build .#nixosConfigurations.live.config.system.build.isoImage
#
# RESULTADO:
#   result/iso/nixos-*.iso
#
# USO:
#   1. Grabar en USB con Ventoy o dd
#   2. Bootear en cualquier PC
#   3. Trabajar con tu entorno completo
#   4. Instalar con: sudo nixos-install --flake github:pascualmg/dotfiles#<hostname>
# =============================================================================

{ config, pkgs, lib, ... }:

{
  # NOTA: El modulo de instalacion (installation-cd-graphical-calamares.nix)
  # se importa en flake.nix, no aqui, porque <nixpkgs> no existe en flakes.

  # ---------------------------------------------------------------------------
  # ISO METADATA
  # ---------------------------------------------------------------------------
  image.baseName = "nixos-passh-live";
  isoImage = {
    # Comprimir con zstd (rapido y buena compresion)
    squashfsCompression = "zstd -Xcompression-level 6";
  };

  # ---------------------------------------------------------------------------
  # BOOT
  # ---------------------------------------------------------------------------
  boot = {
    # Kernel estable (latest tiene ZFS roto)
    kernelPackages = pkgs.linuxPackages;
    # Modulos extra para hardware variado
    initrd.kernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "sd_mod" ];
    # Plymouth para boot bonito
    plymouth.enable = true;
    # Desactivar ZFS (roto en kernels recientes)
    supportedFilesystems = lib.mkForce [ "btrfs" "ext4" "vfat" "ntfs" "xfs" ];
  };

  # ---------------------------------------------------------------------------
  # HARDWARE GENERICO
  # ---------------------------------------------------------------------------
  # Firmware para hardware variado
  hardware = {
    enableRedistributableFirmware = true;
    enableAllFirmware = true;
    # GPU generica (funciona con Intel/AMD/NVIDIA nouveau)
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    # Bluetooth
    bluetooth.enable = true;
  };

  # ---------------------------------------------------------------------------
  # NETWORKING
  # ---------------------------------------------------------------------------
  networking = {
    hostName = "nixos-live";
    networkmanager.enable = true;
    wireless.enable = lib.mkForce false;  # Usamos NetworkManager, no wpa_supplicant
  };

  # ---------------------------------------------------------------------------
  # USUARIO LIVE
  # ---------------------------------------------------------------------------
  # Usuario con tu config pero sin password (es un live)
  users.users.passh = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "docker" ];
    # Auto-login
    initialPassword = "";
  };

  # Auto-login en tty1 (override del default "nixos")
  services.getty.autologinUser = lib.mkForce "passh";

  # ---------------------------------------------------------------------------
  # PAQUETES EXTRA PARA INSTALACION
  # ---------------------------------------------------------------------------
  environment.systemPackages = with pkgs; [
    # Herramientas de instalacion
    gparted
    gnome-disk-utility

    # Git para clonar el flake
    git
    gh  # GitHub CLI

    # Editores
    vim
    neovim

    # Red
    networkmanagerapplet

    # Utilidades
    htop
    btop
    neofetch
    fastfetch

    # Terminales
    alacritty
    kitty

    # Navegador
    firefox

    # Archivo
    p7zip
    unzip

    # Hardware info
    pciutils
    usbutils
    lshw
    hwinfo
  ];

  # ---------------------------------------------------------------------------
  # SERVICIOS
  # ---------------------------------------------------------------------------
  services = {
    # SSH para acceso remoto durante instalacion
    openssh = {
      enable = true;
      settings.PermitRootLogin = "yes";
    };

    # Pipewire audio
    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };
  };

  # ---------------------------------------------------------------------------
  # SCRIPT DE BIENVENIDA
  # ---------------------------------------------------------------------------
  environment.etc."motd".text = ''

    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                      NixOS Live - passh's dotfiles                        ║
    ╠═══════════════════════════════════════════════════════════════════════════╣
    ║                                                                           ║
    ║  Tu entorno completo, listo para usar.                                    ║
    ║                                                                           ║
    ║  USAR COMO LIVE:                                                          ║
    ║    - startx  (si no arranca XMonad automaticamente)                       ║
    ║    - Todo tu entorno esta pre-configurado                                 ║
    ║                                                                           ║
    ║  INSTALAR EN DISCO:                                                       ║
    ║    1. sudo -i                                                             ║
    ║    2. Particionar disco (fdisk, parted, gparted)                          ║
    ║    3. Montar en /mnt                                                      ║
    ║    4. nixos-generate-config --root /mnt                                   ║
    ║    5. nixos-install --flake github:pascualmg/dotfiles#<hostname>          ║
    ║                                                                           ║
    ║  Hostnames disponibles: aurin, macbook, vespino                           ║
    ║                                                                           ║
    ╚═══════════════════════════════════════════════════════════════════════════╝

  '';

  # Nix configurado con flakes
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "root" "passh" ];
  };

  # Permitir unfree
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "25.05";
}
