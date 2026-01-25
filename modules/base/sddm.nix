# =============================================================================
# MODULO: SDDM - Display Manager
# =============================================================================
# SDDM funciona en TODAS las maquinas, con o sin NVIDIA.
#
# IMPORTANTE: wayland.enable = false significa que el GREETER (pantalla de login)
# corre en X11. Esto NO impide elegir sesiones Wayland (Hyprland, niri).
# El greeter Wayland usa kwin_wayland que CRASHEA con NVIDIA.
#
# HISTORIAL:
#   - GDM: Roto con NVIDIA y XMonad puro
#   - LightDM: Solo X11, no soporta Wayland
#   - greetd + tuigreet: X11 roto (Xorg sin suid + logind = pesadilla)
#   - SDDM Wayland: Crashea con NVIDIA (kwin_wayland)
#   - SDDM X11: Funciona con todo
#
# Sesiones disponibles (detectadas automaticamente):
#   - XMonad (X11)
#   - GNOME (X11/Wayland)
#   - KDE Plasma (X11/Wayland)
#   - Hyprland (Wayland)
#   - niri (Wayland)
#
# Tema: sddm-astronaut (moderno, animado, Qt6)
# =============================================================================

{ config, pkgs, lib, ... }:

{
  services.displayManager.sddm = {
    enable = true;
    # GREETER en X11 (estable en todas las maquinas, incluyendo NVIDIA)
    # Puedes seguir eligiendo sesiones Wayland desde el greeter X11
    wayland.enable = false;

    # Tema astronaut - moderno y animado
    theme = "sddm-astronaut-theme";
    extraPackages = [ pkgs.sddm-astronaut ];
  };

  # El tema necesita estar instalado
  environment.systemPackages = [ pkgs.sddm-astronaut ];
}
