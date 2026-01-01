# =============================================================================
# MODULO: Sunshine Streaming Server
# =============================================================================
# Servidor de streaming de juegos compatible con Moonlight
#
# Funcionalidad:
#   - Streaming de escritorio/juegos a dispositivos Moonlight
#   - Codificacion NVENC via RTX 5080
#   - Captura de input (teclado/raton/gamepad)
#
# Puertos:
#   - TCP 47984: HTTPS Web UI
#   - TCP 47989: HTTP Web UI
#   - TCP 47990: HTTPS Web UI (secure)
#   - TCP 48010: RTSP
#   - UDP 47998-48000: Video/Audio/Control
#   - UDP 48002: Audio control
#   - UDP 48010: RTSP
#
# Web UI: https://localhost:47990
#
# Comandos utiles:
#   - sunshine-test: Test completo del servicio
#   - systemctl --user status sunshine: Estado del servicio
#
# Requisitos:
#   - NVIDIA GPU con NVENC
#   - Usuario en grupos: input, video, render
#   - uinput module cargado
# =============================================================================

{ config, pkgs, lib, ... }:

{
  # ===== BOOT: Modulo uinput para captura de input =====
  boot.kernelModules = [
    "uinput"  # Para Sunshine input capture
  ];

  # ===== SERVICES: Sunshine =====
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
    package = pkgs.sunshine.override { cudaSupport = true; };
  };

  # ===== FIREWALL: Puertos Sunshine =====
  networking.firewall = {
    allowedTCPPorts = [
      47984  # HTTPS Web UI
      47989  # HTTP Web UI
      47990  # HTTPS Web UI (secure)
      48010  # RTSP
    ];
    allowedUDPPorts = [
      47998  # Video
      47999  # Audio
      48000  # Control
      48002  # Audio control
      48010  # RTSP
    ];
    allowedUDPPortRanges = [
      { from = 47998; to = 48000; }  # Core streaming
      { from = 8000; to = 8010; }    # Extended range
    ];
  };

  # ===== UDEV: Reglas para input devices =====
  services.udev.extraRules = ''
    # Sunshine input device rules
    KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"
    SUBSYSTEM=="input", GROUP="input", MODE="0664"
    KERNEL=="event*", GROUP="input", MODE="0664"
  '';

  # ===== PAQUETES: Sunshine + cliente Moonlight =====
  environment.systemPackages = with pkgs; [
    # Sunshine con CUDA para RTX 5080
    (sunshine.override { cudaSupport = true; })

    # Cliente Moonlight local (para testing)
    moonlight-qt

    # Script test Sunshine
    (writeShellScriptBin "sunshine-test" ''
      #!/bin/bash
      echo "=== SUNSHINE STREAMING TEST ==="
      echo "GPU: $(nvidia-smi --query-gpu=name --format=csv,noheader,nounits 2>/dev/null || echo 'No detectada')"
      echo "Driver: $(nvidia-smi --query-gpu=driver_version --format=csv,noheader,nounits 2>/dev/null || echo 'No detectado')"
      echo ""
      echo "=== VERIFICANDO SUNSHINE ==="
      if systemctl --user is-active sunshine >/dev/null 2>&1; then
        echo "[OK] Sunshine esta corriendo"
      else
        echo "[ERROR] Sunshine NO esta corriendo"
        echo "Iniciando Sunshine..."
        systemctl --user start sunshine
      fi
      echo ""
      echo "=== VERIFICANDO PUERTOS ==="
      echo "Web UI: https://localhost:47990"
      if ss -tulpn | grep 47990 >/dev/null; then
        echo "[OK] Puerto 47990 abierto"
      else
        echo "[ERROR] Puerto 47990 cerrado"
      fi
      echo ""
      echo "=== NVENC TEST ==="
      ffmpeg -hide_banner -f lavfi -i testsrc2=duration=1:size=1920x1080:rate=60 \
             -c:v h264_nvenc -preset fast -f null - 2>/dev/null && \
        echo "[OK] H.264 NVENC funcionando" || echo "[ERROR] H.264 NVENC fallo"

      ffmpeg -hide_banner -f lavfi -i testsrc2=duration=1:size=1920x1080:rate=60 \
             -c:v hevc_nvenc -preset fast -f null - 2>/dev/null && \
        echo "[OK] H.265 NVENC funcionando" || echo "[ERROR] H.265 NVENC fallo"
      echo ""
      echo "Conecta desde cliente Moonlight a: $(hostname -I | awk '{print $1}'):47989"
    '')
  ];
}
