# =============================================================================
# MODULO: niri Wayland Compositor
# =============================================================================
# Compositor Wayland con paradigma de scroll infinito.
#
# Para habilitar en una máquina:
#   desktop.niri.enable = true;
#
# Incluye:
#   - niri compositor
#   - Waybar (barra de estado)
#   - fuzzel (launcher)
#   - Utilidades Wayland
# =============================================================================

{ config, pkgs, lib, ... }:

{
  options = {
    desktop.niri.enable = lib.mkEnableOption "niri scrolling Wayland compositor";
  };

  config = lib.mkIf config.desktop.niri.enable {
    # ===== NIRI =====
    programs.niri = {
      enable = true;
    };

    # ===== UTILIDADES WAYLAND =====
    environment.systemPackages = with pkgs; [
      waybar        # Barra de estado
      fuzzel        # Launcher (mas ligero que wofi)
      mako          # Notificaciones
      grim          # Screenshots
      slurp         # Selección de área
      wl-clipboard  # Clipboard manager
      swaylock      # Screen locker
    ];

    # ===== XDG PORTAL =====
    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
    };

    # ===== SESSION VARIABLES =====
    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";
    };
  };
}
