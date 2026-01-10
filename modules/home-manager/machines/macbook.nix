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
  # XMobar configurado para macbook HiDPI
  dotfiles.xmobar = {
    enable = true;
    fontSize = 18;              # Con GDK_SCALE=2 se vera como 36
    gpuType = "intel";          # Intel integrated
    networkInterface = null;    # Sin ethernet fijo, ajustar si usas adaptador
    wifiInterface = "wlp0s20f0u7";   # WiFi USB dongle (Broadcom interno no soportado)
    showBattery = true;         # Laptop, mostrar bateria
    showNvmeMonitor = false;    # SSD externo, no NVMe interno
    showTrayer = false;         # No hay trayer-padding-icon instalado
    alsaMixer = "PCM";          # MacBook usa PCM en lugar de Master
  };

  # Alacritty configurado para macbook HiDPI
  dotfiles.alacritty = {
    fontSize = 18;              # 168 DPI HiDPI - fuente mas grande
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
