# =============================================================================
# Machine-specific config: VESPINO
# =============================================================================
# Servidor secundario / Testing
# Hardware: PC antiguo con NVIDIA
# Rol: Minecraft server, NFS, Ollama, VM VPN Vocento
#
# INTERFACES DE RED:
#   - (verificar con ip link en vespino)
# =============================================================================

{ config, lib, pkgs, ... }:

{
  # XMobar configurado para vespino (servidor con X11)
  dotfiles.xmobar = {
    enable = true;
    fontSize = 16;
    gpuType = "nvidia";         # NVIDIA antigua
    networkInterface = null;    # TODO: verificar interfaz
    wifiInterface = null;       # Sin WiFi
    showBattery = false;        # Servidor, no bateria
    showNvmeMonitor = false;    # Sin NVMe
  };

  # Alacritty configurado para vespino
  dotfiles.alacritty = {
    fontSize = 14;
    theme = "dark";
  };

  # Picom configurado para vespino
  dotfiles.picom = {
    backend = "glx";            # NVIDIA antigua - glx estable
  };
}
