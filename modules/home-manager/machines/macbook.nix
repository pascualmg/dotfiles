# =============================================================================
# Machine-specific config: MACBOOK
# =============================================================================
# MacBook Pro 13,2 (2016)
# Hardware: Intel Skylake, Intel GPU, SSD externo Thunderbolt
# Display: 168 DPI (HiDPI Retina)
#
# INTERFACES DE RED (tipicas en MacBook con NixOS):
#   - wlp3s0: WiFi Broadcom (o similar)
#   - enp0s20f0u1: USB Ethernet adapter (si lo tienes)
#
# NOTA: Verificar nombres reales con `ip link` en el macbook
# =============================================================================

{ config, lib, pkgs, ... }:

{
  # HiDPI variables para sesion X (GDM no lee /etc/set-environment)
  home.sessionVariables = {
    GDK_SCALE = "2";
    GDK_DPI_SCALE = "0.5";
    QT_SCALE_FACTOR = "2";
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    QT_ENABLE_HIGHDPI_SCALING = "1";
    XCURSOR_SIZE = "48";
  };

  # XMobar configurado para macbook HiDPI
  dotfiles.xmobar = {
    enable = false;             # DESHABILITADO: probando taffybar
    fontSize = 24;              # xmobar no usa GDK_SCALE, necesita fuente grande
    gpuType = "intel";          # Intel integrated
    networkInterface = null;    # Sin ethernet fijo, ajustar si usas adaptador
    wifiInterface = "wlp0s20f0u7";   # WiFi USB dongle (Broadcom interno no soportado)
    showBattery = true;         # Laptop, mostrar bateria
    showNvmeMonitor = false;    # SSD externo, no NVMe interno
    showTrayer = false;         # No hay trayer-padding-icon instalado
    alsaMixer = "PCM";          # MacBook usa PCM en lugar de Master
  };

  # Taffybar - Barra GTK3 con systray nativo
  dotfiles.taffybar = {
    enable = true;
    fontSize = 14;              # GTK3 respeta GDK_SCALE, no necesita fuente grande
    barHeight = 32;
    showBattery = true;
    showSystray = true;         # nm-applet, blueman-applet funcionan directo
  };

  # Alacritty configurado para macbook HiDPI
  dotfiles.alacritty = {
    fontSize = 11;              # Con Xft.dpi=227, 11 se ve bien
    theme = "dark";             # Spacemacs Dark
  };

  # Picom configurado para macbook
  dotfiles.picom = {
    backend = "xrender";        # Intel integrated - xrender mas compatible
  };

  # Gestos de trackpad para cambiar workspaces
  dotfiles.libinput-gestures.enable = true;

  # GNOME dconf settings
  dconf.settings = {
    # Deshabilitar lock screen (problemas con butterfly keyboard)
    "org/gnome/desktop/screensaver" = {
      lock-enabled = false;
      idle-activation-enabled = false;
    };
    "org/gnome/desktop/session" = {
      idle-delay = lib.hm.gvariant.mkUint32 0;  # No idle timeout
    };
    # Deshabilitar auto-lock cuando suspende
    "org/gnome/desktop/lockdown" = {
      disable-lock-screen = true;
    };
  };
}
