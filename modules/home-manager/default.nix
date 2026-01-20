# =============================================================================
# Home Manager Modules - Entry Point
# =============================================================================
# Este archivo actua como punto de entrada para los modulos de home-manager.
#
# USO EN FLAKE:
#   home-manager.nixosModules.default
#   # o importar directamente: ./modules/home-manager
#
# ESTRUCTURA:
#   modules/home-manager/
#   |-- default.nix       <- Este archivo (entry point)
#   |-- passh.nix         <- Configuracion base del usuario passh
#   |-- programs/
#   |   |-- emacs.nix     <- Wrapper inteligente X11/Wayland (dotfiles.emacs)
#   |   |-- xmobar.nix    <- Modulo xmobar parametrizable (dotfiles.xmobar)
#   |   |-- taffybar.nix  <- Barra alternativa GTK3 con systray (dotfiles.taffybar)
#   |   +-- (otros: alacritty.nix, fish.nix, etc.)
#   +-- machines/
#       |-- aurin.nix     <- Config especifica aurin
#       +-- macbook.nix   <- Config especifica macbook
#
# ESTADO: Activo - Usado por flake con enableHomeManager=true
# =============================================================================

{ config, pkgs, lib, hostname ? "aurin", ... }:

let
  # Determinar que archivo de maquina cargar basado en hostname
  machineConfig = ./machines/${hostname}.nix;
  machineExists = builtins.pathExists machineConfig;
in
{
  imports = [
    # Config base del usuario
    ./passh.nix

    # Modulos de programas (definen opciones en namespace dotfiles.*)
    ./programs/emacs.nix            # Wrapper inteligente X11/Wayland
    ./programs/xmobar.nix
    ./programs/taffybar.nix
    ./programs/alacritty.nix
    ./programs/picom.nix
    ./programs/fish.nix
    ./programs/libinput-gestures.nix
    ./programs/hyprland.nix         # Wayland compositor moderno
    ./programs/niri.nix             # Wayland scroll infinito
    ./programs/console-theme.nix    # Temas TTY en caliente (solo macbook)

    # Config especifica de maquina (setea las opciones)
    # Solo importar si existe el archivo para esa maquina
  ] ++ lib.optionals machineExists [ machineConfig ];

  # Fallback: si no hay config de maquina, deshabilitar xmobar
  # (evita errores en maquinas sin config especifica como vespino)
  dotfiles.xmobar.enable = lib.mkDefault machineExists;
}
