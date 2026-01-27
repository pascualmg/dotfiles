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

{
  config,
  lib,
  pkgs,
  ...
}:

{
  # XMobar configurado para aurin
  # GPU: RTX 5080 (nvidia) - auto-detectada por xmobar-gpu.sh
  # Red: enp10s0 (eth), wlp8s5 (wifi) - auto-detectadas por scripts
  dotfiles.xmobar = {
    enable = true;
    fontSize = 16; # 96 DPI - tamano normal
    showBattery = false; # Desktop, no bateria
    showDiskMonitor = true; # Monitor genérico (NVMe + SATA)
  };

  # Alacritty configurado para aurin
  dotfiles.alacritty = {
    fontSize = 14; # 96 DPI - tamano normal
    # defaultTheme = "spacemacs-dark";  # default, no hace falta
  };

  # Picom configurado para aurin
  dotfiles.picom = {
    backend = "egl"; # RTX 5080 - egl optimizado
  };

  # =============================================================================
  # TESTING: Whisper Voice Input (Phase 0 - Research)
  # =============================================================================
  # Paquetes temporales para probar Whisper antes de nixificar
  # TODO: Mover a módulo home-manager cuando decidamos arquitectura final
  # NOTA: whisper-cpp y whisper-cpp-vulkan conflictúan (mismos binarios)
  #       Probamos primero CPU, luego GPU en fase separada
  # NOTA: ffmpeg-full ya está instalado en passh.nix (no duplicar)
  home.packages = with pkgs; [
    whisper-cpp # Engine principal (CPU + compilado con OpenBLAS)
    sox # Audio processing utilities
    pavucontrol # PulseAudio/PipeWire control GUI (debugging)
  ];
}
