# =============================================================================
# HARDWARE/AUDIO/FIIO-K7.NIX - FiiO K7 DAC/AMP
# =============================================================================
# Configuracion PipeWire optimizada para FiiO K7 DAC/AMP con Sennheiser HD600
#
# Hardware:
#   - FiiO K7 USB DAC/AMP (USB ID: 2972:0047)
#   - Sennheiser HD600 (300 ohm - requiere GAIN: High)
#
# Optimizaciones:
#   - Sample rate: 96kHz (nativo del K7)
#   - Quantum: 1024 (balance latencia/estabilidad)
#   - USB Audio: nrpacks=1 para DACs USB
#   - rtkit habilitado para prioridad real-time
#
# Comandos utiles:
#   - fiio-k7-test: Test completo del dispositivo
#   - pulsemixer: Control volumen TUI
#   - helvum: PipeWire patchbay GUI
#
# Configuracion fisica recomendada HD600:
#   - Switch OUTPUT: PO (Phone Out)
#   - Switch GAIN: H (High) para 300 ohm
#   - Volumen sistema: 85-90%
#   - Volumen K7 fisico: 60-75%
# =============================================================================

{ config, pkgs, lib, ... }:

{
  # ===== HARDWARE: Bluetooth para dispositivos audio inalambricos =====
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # ===== BOOT: Kernel params para USB Audio =====
  boot = {
    kernelParams = [
      "snd_usb_audio.nrpacks=1"  # Optimizacion para DACs USB
    ];

    kernelModules = [
      "snd-usb-audio"  # CRITICO: Para FiiO K7
    ];
  };

  # ===== SERVICES: PipeWire + PulseAudio disabled =====
  services = {
    # Desactivar PulseAudio para usar PipeWire
    pulseaudio.enable = false;

    # PipeWire optimizado para FiiO K7
    pipewire = {
      enable = true;
      pulse.enable = true;
      jack.enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };

      # Configuracion especifica para FiiO K7
      extraConfig.pipewire."10-fiio-k7" = {
        "context.properties" = {
          "default.clock.rate" = 96000;          # 96kHz nativo del K7
          "default.clock.quantum" = 1024;        # Balance latencia/estabilidad
          "default.clock.min-quantum" = 32;
          "default.clock.max-quantum" = 2048;
        };
      };

      # Configuracion ALSA optimizada
      extraConfig.pipewire."99-alsa-config" = {
        "alsa.properties" = {
          "alsa.period-size" = 1024;
          "alsa.periods" = 2;
        };
      };

      # Configuracion volumen conservador
      extraConfig.pipewire-pulse."10-volume" = {
        "pulse.properties" = {
          "pulse.max-volume" = "131072";  # 125% en formato pulse
        };
      };

      # Configuracion especifica USB Audio
      extraConfig.pipewire."20-usb-audio" = {
        "context.modules" = [{
          name = "libpipewire-module-adapter";
          args = {
            "audio.position" = [ "FL" "FR" ];
            "node.name" = "fiio-k7-optimized";
            "node.description" = "FiiO K7 Optimized";
          };
        }];
      };
    };
  };

  # ===== SECURITY: rtkit para audio real-time =====
  security.rtkit.enable = true;  # CRITICO: Para audio de baja latencia

  # ===== UDEV: Reglas para FiiO K7 =====
  services.udev.extraRules = ''
    # FiiO K7 USB Audio device rules
    SUBSYSTEM=="usb", ATTRS{idVendor}=="2972", ATTRS{idProduct}=="0047", GROUP="audio", MODE="0664"
    SUBSYSTEM=="sound", KERNEL=="card*", ATTRS{idVendor}=="2972", ATTRS{idProduct}=="0047", GROUP="audio", MODE="0664"
  '';

  # ===== PAQUETES: Herramientas audio =====
  environment.systemPackages = with pkgs; [
    # Control volumen
    pulsemixer      # TUI control volumen
    pamixer         # CLI control volumen

    # PipeWire tools
    helvum          # PipeWire patchbay GUI
    coppwr          # Monitor PipeWire

    # JACK tools (para PipeWire JACK)
    qjackctl

    # Efectos audio
    easyeffects     # Efectos de audio en tiempo real

    # Script test FiiO K7
    (writeShellScriptBin "fiio-k7-test" ''
      #!/bin/bash
      echo "=== FIIO K7 DAC/AMP TEST ==="
      echo ""
      echo "=== VERIFICANDO DISPOSITIVO USB ==="
      if lsusb | grep -i "fiio\|2972:0047" >/dev/null; then
        echo "[OK] FiiO K7 detectado por USB"
        lsusb | grep -i "fiio\|2972:0047"
      else
        echo "[ERROR] FiiO K7 NO detectado por USB"
        echo "Verifica:"
        echo "1. Cable USB conectado correctamente"
        echo "2. Switch OUTPUT en PO (Phone Out)"
        echo "3. Encendido el K7"
        exit 1
      fi

      echo ""
      echo "=== VERIFICANDO AUDIO ALSA ==="
      if aplay -l | grep -i "fiio\|usb" >/dev/null; then
        echo "[OK] FiiO K7 detectado por ALSA"
        aplay -l | grep -i "fiio\|usb"
      else
        echo "[ERROR] FiiO K7 NO detectado por ALSA"
      fi

      echo ""
      echo "=== VERIFICANDO PIPEWIRE/PULSEAUDIO ==="
      if pactl list short sinks | grep -i "fiio\|usb.*analog" >/dev/null; then
        echo "[OK] FiiO K7 disponible en PipeWire"
        echo "Sink: $(pactl list short sinks | grep -i "fiio\|usb.*analog" | head -1)"

        # Verificar si es el dispositivo por defecto
        DEFAULT_SINK=$(pactl info | grep "Default Sink" | cut -d: -f2 | xargs)
        if echo "$DEFAULT_SINK" | grep -i "fiio\|usb.*analog" >/dev/null; then
          echo "[OK] FiiO K7 es el dispositivo por defecto"
        else
          echo "[WARN] FiiO K7 NO es el dispositivo por defecto"
          echo "Actual: $DEFAULT_SINK"
          echo ""
          echo "Para configurarlo como default:"
          FIIO_SINK=$(pactl list short sinks | grep -i "fiio\|usb.*analog" | head -1 | cut -f2)
          echo "pactl set-default-sink '$FIIO_SINK'"
        fi
      else
        echo "[ERROR] FiiO K7 NO disponible en PipeWire"
        echo "Sinks disponibles:"
        pactl list short sinks
      fi

      echo ""
      echo "=== VERIFICANDO VOLUMEN ==="
      if pactl list short sinks | grep -i "fiio\|usb.*analog" >/dev/null; then
        FIIO_SINK=$(pactl list short sinks | grep -i "fiio\|usb.*analog" | head -1 | cut -f2)
        VOLUME=$(pactl get-sink-volume "$FIIO_SINK" | grep -o '[0-9]*%' | head -1)
        MUTED=$(pactl get-sink-mute "$FIIO_SINK")

        echo "Volumen actual: $VOLUME"
        echo "Estado: $MUTED"

        if [[ "$VOLUME" =~ ^[0-9]+% ]] && [ "''${VOLUME%\%}" -lt 50 ]; then
          echo "[WARN] Volumen bajo (< 50%). Para HD600 se recomienda 80-90%"
        fi
      fi

      echo ""
      echo "=== TEST DE AUDIO ==="
      echo "Ejecutar test de audio? (y/n)"
      read -r response
      if [[ "$response" =~ ^[Yy]$ ]]; then
        echo "Reproduciendo tono de prueba 440Hz por 3 segundos..."
        if command -v speaker-test &> /dev/null; then
          timeout 3s speaker-test -t sine -f 440 -c 2 -l 1 -s 1 2>/dev/null || echo "Test completado"
        else
          echo "speaker-test no disponible"
        fi
      fi

      echo ""
      echo "=== CONFIGURACION RECOMENDADA HD600 ==="
      echo "- Switch fisico OUTPUT: PO (Phone Out)"
      echo "- Switch fisico GAIN: H (High) para HD600 (300ohm)"
      echo "- Volumen sistema: 85-90%"
      echo "- Volumen K7: 60-75% (fisico en el dispositivo)"
      echo ""
      echo "=== COMANDOS UTILES ==="
      echo "- Configurar como default: pactl set-default-sink SINK_NAME"
      echo "- Cambiar volumen: pactl set-sink-volume @DEFAULT_SINK@ 85%"
      echo "- Ver dispositivos: pactl list short sinks"
      echo "- GUI control: pavucontrol"
    '')
  ];
}
