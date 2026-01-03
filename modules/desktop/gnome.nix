# =============================================================================
# MODULO: GNOME Desktop Environment
# =============================================================================
# ESTADO: Preparado para experimentos futuros (NO EN USO)
#
# Para habilitar en una máquina:
#   desktop.gnome.enable = true;
#
# Incluye:
#   - GDM (Display Manager)
#   - GNOME Desktop completo
#   - Extensiones útiles
#   - Configuración HiDPI
# =============================================================================

{ config, pkgs, lib, ... }:

{
  options = {
    desktop.gnome.enable = lib.mkEnableOption "GNOME Desktop Environment";
  };

  config = lib.mkIf config.desktop.gnome.enable {
    # ===== GNOME + GDM =====
    services.xserver = {
      enable = true;
      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
    };

    # ===== EXTENSIONES GNOME =====
    environment.systemPackages = with pkgs; [
      gnome.gnome-tweaks
      gnomeExtensions.appindicator
      gnomeExtensions.blur-my-shell
      gnomeExtensions.dash-to-dock
      gnomeExtensions.user-themes
    ];

    # ===== SERVICIOS INNECESARIOS DESHABILITADOS =====
    services.gnome = {
      gnome-keyring.enable = true;
      tracker-miners.enable = false;  # Indexing pesado
      tracker.enable = false;
    };

    # ===== PROGRAMAS GNOME A EXCLUIR =====
    environment.gnome.excludePackages = with pkgs; [
      gnome-photos
      gnome-tour
      gnome.cheese
      gnome.geary
      epiphany  # Navegador
    ];
  };
}
