# =============================================================================
# MODULO: SDDM - Display Manager
# =============================================================================
# Soporta X11 (XMonad) y Wayland (Hyprland, niri) sin problemas.
#
# HISTORIAL:
#   - GDM: Roto con NVIDIA y XMonad puro
#   - LightDM: Solo X11, no soporta Wayland
#   - greetd + tuigreet: X11 roto (Xorg sin suid + logind = pesadilla)
#   - SDDM: Funciona con todo, sin dramas
#
# Sesiones disponibles (detectadas automaticamente):
#   - XMonad (X11)
#   - GNOME (X11/Wayland)
#   - Hyprland (Wayland)
#   - niri (Wayland)
# =============================================================================

{ config, pkgs, lib, ... }:

{
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;  # Permite sesiones Wayland
  };
}
