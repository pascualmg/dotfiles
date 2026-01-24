# =============================================================================
# MODULES/BASE/DESKTOP.NIX - Escritorio unificado para TODAS las maquinas
# =============================================================================
# SDDM + GNOME + XMonad - TODO disponible en TODAS las maquinas
#
# IMPORTANTE:
#   - SDDM como display manager (soporta X11 Y Wayland sin dramas)
#   - NO habilita picom aqui (va en home-manager, se lanza desde xmonad.hs)
#   - displaySetupCommand va en los modulos hardware/ de cada maquina
#
# Sesiones disponibles (detectadas automaticamente por SDDM):
#   - XMonad (X11)
#   - GNOME (X11 y Wayland)
#   - Hyprland (Wayland)
#   - niri (Wayland)
#
# HISTORIAL:
#   - 2026-01-19: LightDM (GDM roto con NVIDIA)
#   - 2026-01-24: greetd (X11 roto, Xorg sin suid + logind = pesadilla)
#   - 2026-01-24: SDDM (funciona todo)
# =============================================================================

{ config, pkgs, lib, ... }:

{
  # ===== X.ORG SERVER =====
  services.xserver.enable = true;

  # ===== DISPLAY MANAGER =====
  # SDDM (configurado en ./sddm.nix)
  # - Soporta X11 (XMonad) y Wayland (Hyprland, niri)
  # - Login grafico, simple, funciona

  # ===== DESKTOP ENVIRONMENT: GNOME =====
  services.desktopManager.gnome.enable = true;

  # ===== WINDOW MANAGER: XMONAD =====
  services.xserver.windowManager.xmonad = {
    enable = true;
    enableContribAndExtras = true;
    # Config file: ~/.config/xmonad/xmonad.hs (gestionado via stow)
  };

  # ===== KEYBOARD =====
  # Layout: US (default) + ES (Alt+Shift para cambiar)
  # Caps Lock -> Escape (util para Vim/Emacs)
  services.xserver.xkb = {
    layout = "us,es";
    options = "grp:alt_shift_toggle,caps:escape";
  };

  # ===== INPUT: LIBINPUT =====
  # Filosofia HHKB: el hardware manda, no el software
  # Perfil flat = movimiento 1:1 con el DPI del raton
  services.libinput = {
    enable = true;
    mouse = {
      accelProfile = "flat";  # Raw input, sin aceleracion
      accelSpeed = "0";       # Respeta DPI del raton
    };
  };

  # ===== PAQUETES DESKTOP =====
  environment.systemPackages = with pkgs; [
    # XMonad utilities
    dmenu           # Launcher
    xclip           # Clipboard X11
    xsel            # Clipboard X11 alternativo

    # File manager (disponible en todas las maquinas)
    thunar          # File manager ligero (antes xfce.thunar)
    thunar-volman   # Gestion de volumenes

    # Screenshot
    scrot           # Screenshot tool

    # Wallpaper
    feh             # Image viewer + wallpaper setter
  ];

  # ===== NOTA IMPORTANTE =====
  # picom NO se habilita aqui porque conflictua con Mutter (GNOME)
  #
  # Solucion:
  #   1. picom se configura en home-manager (modules/home-manager/programs/picom.nix)
  #   2. xmonad.hs lo lanza en startupHook: spawnOnce "picom"
  #   3. Cuando usas GNOME, picom NO corre (Mutter hace de compositor)
  #   4. Cuando usas XMonad, picom SI corre (lanzado por xmonad.hs)
}
