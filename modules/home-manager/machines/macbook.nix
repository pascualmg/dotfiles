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
    fontSize = 24;              # 168 DPI HiDPI - necesita fuente mas grande
    gpuType = "intel";          # Intel integrated
    networkInterface = null;    # Sin ethernet fijo, ajustar si usas adaptador
    wifiInterface = "wlp0s20f0u7";   # WiFi USB dongle (Broadcom interno no soportado)
    showBattery = true;         # Laptop, mostrar bateria
    showNvmeMonitor = false;    # SSD externo, no NVMe interno
    showTrayer = false;         # No hay trayer-padding-icon instalado
    alsaMixer = "PCM";          # MacBook usa PCM en lugar de Master
  };
}
