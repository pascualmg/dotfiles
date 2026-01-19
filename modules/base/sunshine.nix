# =============================================================================
# MODULES/BASE/SUNSHINE.NIX - Streaming server para TODAS las maquinas
# =============================================================================
# Servidor de streaming compatible con Moonlight.
# - Con NVIDIA: usa NVENC (hardware encoding)
# - Sin NVIDIA: usa software encoding (funciona pero mas CPU)
#
# Web UI: https://localhost:47990
#
# Comandos:
#   - sunshine-test: Test del servicio
#   - systemctl --user status sunshine: Estado
# =============================================================================

{ config, pkgs, lib, ... }:

let
  # Detectar si hay NVIDIA configurada
  hasNvidia = config.services.xserver.videoDrivers or [] != [] &&
              builtins.elem "nvidia" (config.services.xserver.videoDrivers or []);

  # Paquete con o sin CUDA segun hardware
  sunshinePackage = if hasNvidia
    then pkgs.sunshine.override { cudaSupport = true; }
    else pkgs.sunshine;
in
{
  # ===== BOOT: Modulo uinput para captura de input =====
  boot.kernelModules = [ "uinput" ];

  # ===== SERVICES: Sunshine =====
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
    package = sunshinePackage;
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
      { from = 47998; to = 48000; }
      { from = 8000; to = 8010; }
    ];
  };

  # ===== UDEV: Reglas para input devices =====
  services.udev.extraRules = ''
    KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"
    SUBSYSTEM=="input", GROUP="input", MODE="0664"
    KERNEL=="event*", GROUP="input", MODE="0664"
  '';

  # ===== PAQUETES =====
  environment.systemPackages = with pkgs; [
    sunshinePackage
    moonlight-qt  # Cliente para testing

    # Script test
    (writeShellScriptBin "sunshine-test" ''
      #!/bin/bash
      echo "=== SUNSHINE STREAMING TEST ==="

      # Detectar GPU
      if command -v nvidia-smi &>/dev/null; then
        echo "GPU: $(nvidia-smi --query-gpu=name --format=csv,noheader,nounits 2>/dev/null || echo 'NVIDIA no detectada')"
        echo "Encoding: NVENC (hardware)"
      else
        echo "GPU: Sin NVIDIA"
        echo "Encoding: Software (CPU)"
      fi
      echo ""

      echo "=== VERIFICANDO SUNSHINE ==="
      if systemctl --user is-active sunshine >/dev/null 2>&1; then
        echo "[OK] Sunshine corriendo"
      else
        echo "[!] Sunshine no activo - iniciando..."
        systemctl --user start sunshine
      fi
      echo ""

      echo "=== PUERTOS ==="
      if ss -tulpn 2>/dev/null | grep 47990 >/dev/null; then
        echo "[OK] Web UI disponible en https://localhost:47990"
      else
        echo "[!] Puerto 47990 no abierto"
      fi
      echo ""

      echo "Conecta desde Moonlight a: $(hostname -I | awk '{print $1}')"
    '')
  ];
}
