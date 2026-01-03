# =============================================================================
# MODULO COMPARTIDO: Paquetes Comunes del Sistema
# =============================================================================
# Paquetes que AMBAS máquinas (aurin + macbook) necesitan a nivel de sistema
#
# NOTA: Paquetes de usuario van en modules/home-manager/passh.nix
# =============================================================================

{ config, pkgs, lib, ... }:

{
  # ===== PERMITIR PAQUETES UNFREE =====
  nixpkgs.config.allowUnfree = true;

  # ===== PAQUETES DEL SISTEMA =====
  environment.systemPackages = with pkgs; [
    # === BASICOS ===
    vim
    wget
    curl
    git
    htop
    tree
    unzip
    zip

    # === NETWORK ===
    networkmanager
    networkmanagerapplet

    # === FILESYSTEM ===
    ntfs3g
    exfat
    dosfstools

    # === HARDWARE INFO ===
    pciutils
    usbutils
    lshw

    # === BUILD TOOLS ===
    gcc
    gnumake
    pkg-config

    # === UTILIDADES ===
    stow
    direnv
    nix-direnv
  ];

  # ===== PROGRAMAS CON CONFIGURACION =====
  programs.git.enable = true;
  programs.vim.defaultEditor = true;

  # ===== SHELLS =====
  programs.fish.enable = true;
  programs.bash.completion.enable = true;
}
