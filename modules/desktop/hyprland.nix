# =============================================================================
# MODULO: Hyprland Wayland Compositor
# =============================================================================
# ESTADO: Preparado para experimentos futuros (NO EN USO)
#
# Para habilitar en una máquina:
#   desktop.hyprland.enable = true;
#
# Incluye:
#   - Hyprland compositor
#   - Waybar (barra de estado)
#   - Wofi (launcher)
#   - Configuración básica
# =============================================================================

{ config, pkgs, lib, ... }:

{
  options = {
    desktop.hyprland.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Hyprland Wayland compositor (enabled by default)";
    };
  };

  config = lib.mkIf config.desktop.hyprland.enable {
    # ===== HYPRLAND =====
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    # ===== UTILIDADES WAYLAND =====
    environment.systemPackages = with pkgs; [
      waybar        # Barra de estado
      wofi          # Launcher
      mako          # Notificaciones
      grim          # Screenshots
      slurp         # Selección de área
      wl-clipboard  # Clipboard manager
      swaylock      # Screen locker
    ];

    # ===== XDG PORTAL (Compartir pantalla, etc.) =====
    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
    };

    # ===== SESSION VARIABLES =====
    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";  # Electron apps en Wayland
      MOZ_ENABLE_WAYLAND = "1";  # Firefox en Wayland
    };
  };
}
