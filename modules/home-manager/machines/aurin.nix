# =============================================================================
# Machine-specific config: AURIN
# =============================================================================
# Workstation de produccion
# Hardware: Dual Xeon E5-2699v3, 128GB RAM, RTX 5080
# Display: 96 DPI (monitor estandar)
#
# INTERFACES DE RED:
#   - enp10s0: Ethernet principal
#   - wlp8s5: WiFi
# =============================================================================

{ config, lib, pkgs, ... }:

{
  # XMobar configurado para aurin
  dotfiles.xmobar = {
    enable = true;
    fontSize = 16;              # 96 DPI - tamano normal
    gpuType = "nvidia";         # RTX 5080
    networkInterface = "enp10s0";
    wifiInterface = "wlp8s5";
    showBattery = false;        # Desktop, no bateria
    showNvmeMonitor = true;     # Tiene NVMe
  };

  # Alacritty configurado para aurin
  dotfiles.alacritty = {
    fontSize = 14;              # 96 DPI - tamano normal
  };
}
