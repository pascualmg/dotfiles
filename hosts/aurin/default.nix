# =============================================================================
# HOSTS/AURIN - Configuracion especifica de Aurin
# =============================================================================
# Workstation de produccion - Dual Xeon E5-2699v3 + RTX 5080
#
# Hardware:
#   - CPU: Dual Xeon E5-2699v3 (72 threads)
#   - RAM: 128GB DDR4 ECC
#   - GPU: NVIDIA RTX 5080 (open drivers)
#   - Audio: FiiO K7 DAC/AMP + Sennheiser HD600
#   - Display: 5120x1440@120Hz ultrawide
#
# Servicios:
#   - Sunshine (streaming via NVENC)
#   - Ollama AI (CUDA optimizado)
#   - Syncthing
#   - Docker + libvirt
#   - Steam
#   - Voice Cloning (Qwen TTS via Docker)
#
# =============================================================================
# QWEN TTS - Text-to-Speech con RTX 5080
# =============================================================================
# Sistema TTS usando Qwen3-TTS en Docker con CUDA 13. Dos modos:
#
#   1. VOCES PREFABRICADAS (rapido) - Solo texto, sin referencia
#   2. VOICE CLONING (tu voz) - Requiere audio de referencia
#
# SETUP (primera vez):
#   cd ~/dotfiles/containers/qwen-tts && docker build -t qwen-tts:cu130 .
#   docker volume create qwen-tts-cache
#
# USO - Voces prefabricadas:
#   qwen-tts -t "Hola mundo" -v Chelsie -o salida.wav
#
# USO - Clonar tu voz:
#   qwen-tts --clone \
#     -r ~/voice-cloning/references/mi-voz.wav \
#     -rt "Transcripcion del audio" \
#     -t "Texto a generar" \
#     -o ~/voice-cloning/output/clonado.wav
#
# VOCES DISPONIBLES: Chelsie, Ethan, Aura, Nova, Atlas
# IDIOMAS: Spanish (default), English, Chinese, Japanese, Korean, etc.
#
# NOTAS:
#   - Primera ejecucion descarga modelo (~3.5GB), luego usa cache
#   - RTX 5080 requiere PyTorch nightly cu130 (CUDA 13)
#   - Voces prefabricadas: ~5s | Voice cloning: ~15s
#
#
# ZONA SAGRADA: VPN Vocento
#   La configuracion de br0 y rutas a 192.168.53.12 es CRITICA
#   NO MODIFICAR sin plan de rollback
# =============================================================================

{
  config,
  pkgs,
  lib,
  pkgsMaster,
  ...
}:

{
  # ===========================================================================
  # IMPORTS
  # ===========================================================================
  imports = [
    ../../modules/services/syncthing.nix
  ];

  # ===========================================================================
  # SYNCTHING (módulo centralizado)
  # ===========================================================================
  dotfiles.syncthing.enable = true;
  dotfiles.syncthing.guiPort = 8385;  # aurin usa 8385

  # ===========================================================================
  # DISPLAY SETUP - Monitor ultrawide 5120x1440 @ 120Hz
  # ===========================================================================
  services.xserver.displayManager.setupCommands = ''
    ${pkgs.xorg.xrandr}/bin/xrandr --output DP-4 --mode 5120x1440 --rate 120 --primary --dpi 96
    ${pkgs.xorg.xset}/bin/xset r rate 350 50
  '';

  # ===========================================================================
  # OVERRIDES de modulos comunes (valores especificos Dual Xeon)
  # ===========================================================================
  # Nix settings: 72 jobs para Dual Xeon
  common.nix.maxJobs = 72;
  common.nix.gcDays = 8; # GC mas agresivo, tenemos mucho disco

  # ===========================================================================
  # HARDWARE
  # ===========================================================================
  hardware.enableAllFirmware = true;

  # ===========================================================================
  # BOOT (parametros especificos Dual Xeon + ASPEED)
  # ===========================================================================
  boot = {
    kernelParams = [
      # Desactivar ASPEED (BMC integrado en placa servidor)
      "ast.modeset=0"
      "video=ASPEED-1:d"

      # NUMA balancing
      "numa_balancing=enable"

      # Video mode para ultrawide
      "video=5120x1440@120"
    ];

    blacklistedKernelModules = [ "ast" ];

    supportedFilesystems = [ "ntfs" ];

    # Optimizaciones Dual Xeon + Streaming
    kernel.sysctl = {
      # Memoria (128GB RAM)
      "vm.swappiness" = 1;
      "vm.vfs_cache_pressure" = 50;
      "vm.dirty_ratio" = 15;
      "vm.dirty_background_ratio" = 5;
      "vm.dirty_expire_centisecs" = 500;
      "vm.dirty_writeback_centisecs" = 100;

      # File system
      "fs.inotify.max_user_watches" = 524288;
      "vm.max_map_count" = 2147483647;
      "fs.file-max" = 2097152;

      # NUMA Dual Xeon
      "kernel.numa_balancing" = 1;
      "kernel.numa_balancing_scan_delay_ms" = 1000;
      "kernel.numa_balancing_scan_period_min_ms" = 1000;
      "kernel.numa_balancing_scan_period_max_ms" = 60000;

      # Scheduler para 72 threads
      "kernel.sched_migration_cost_ns" = 5000000;
      "kernel.sched_autogroup_enabled" = 0;
      "kernel.sched_tunable_scaling" = 0;

      # Network para streaming
      "net.core.rmem_default" = 262144;
      "net.core.rmem_max" = 134217728;
      "net.core.wmem_default" = 262144;
      "net.core.wmem_max" = 134217728;
      "net.core.netdev_max_backlog" = 30000;
      "net.ipv4.tcp_rmem" = "4096 12582912 134217728";
      "net.ipv4.tcp_wmem" = "4096 12582912 134217728";
      "net.ipv4.tcp_congestion_control" = "bbr";
      "net.ipv4.tcp_low_latency" = 1;
      "net.ipv4.tcp_no_delay" = 1;

      # Stress testing
      "vm.overcommit_memory" = 1;
      "kernel.panic_on_oops" = 0;
      "kernel.hung_task_timeout_secs" = 0;
    };
  };

  # ===========================================================================
  # ENVIRONMENT VARIABLES (Dual Xeon)
  # ===========================================================================
  environment.sessionVariables = {
    OMP_NUM_THREADS = "72";
    MKL_NUM_THREADS = "72";
    OMP_PLACES = "cores";
    OMP_PROC_BIND = "close";
  };

  # =============================================================================
  # ZONA SAGRADA: NETWORKING + VPN VOCENTO
  # =============================================================================
  # NO MODIFICAR esta seccion sin:
  # 1. Backup de la VM Ubuntu con Ivanti
  # 2. Snapshot de la generacion NixOS actual
  # 3. Plan de rollback documentado
  # =============================================================================
  networking = {
    useHostResolvConf = false;
    useDHCP = false;

    hosts = {
      "185.14.56.20" = [ "pascualmg" ];
    };
    # NOTA: Requiere --impure para leer paths externos al flake
    extraHosts =
      if builtins.pathExists "/home/passh/src/vocento/autoenv/hosts_all.txt" then
        builtins.readFile "/home/passh/src/vocento/autoenv/hosts_all.txt"
      else
        "";

    resolvconf.enable = false;

    interfaces = {
      enp7s0 = {
        useDHCP = false;
        ipv4.addresses = [
          {
            address = "192.168.2.147";
            prefixLength = 24;
          }
        ];
      };

      br0 = {
        useDHCP = false;
        ipv4 = {
          addresses = [
            {
              address = "192.168.53.10";
              prefixLength = 24;
            }
          ];
          routes = [
            {
              address = "10.180.0.0";
              prefixLength = 16;
              via = "192.168.53.12";
            }
            {
              address = "10.182.0.0";
              prefixLength = 16;
              via = "192.168.53.12";
            }
            {
              address = "192.168.196.0";
              prefixLength = 24;
              via = "192.168.53.12";
            }
            {
              address = "10.200.26.0";
              prefixLength = 24;
              via = "192.168.53.12";
            }
            {
              address = "10.184.0.0";
              prefixLength = 16;
              via = "192.168.53.12";
            }
            {
              address = "10.186.0.0";
              prefixLength = 16;
              via = "192.168.53.12";
            }
            {
              address = "34.175.0.0";
              prefixLength = 16;
              via = "192.168.53.12";
            }
            {
              address = "34.13.0.0";
              prefixLength = 16;
              via = "192.168.53.12";
            }
          ];
        };
      };
    };

    bridges = {
      br0.interfaces = [ ];
    };

    defaultGateway = {
      address = "192.168.2.1";
      interface = "enp7s0";
    };

    networkmanager = {
      enable = true;
      dns = "none";
      unmanaged = [
        "interface-name:enp7s0"
        "interface-name:enp8s0"
        "interface-name:br0"
        "interface-name:vnet*"
      ];
    };

    nat = {
      enable = true;
      internalInterfaces = [ "br0" ];
      externalInterface = "enp7s0";
      extraCommands = ''
        iptables -t nat -A POSTROUTING -s 192.168.53.0/24 -j MASQUERADE
      '';
    };

    # =========================================================================
    # FIREWALL - Solo puertos ESPECÍFICOS de aurin
    # =========================================================================
    # Puertos comunes (dev servers, VNC, CUPS) → modules/core/firewall.nix
    # Puertos de módulos (Ollama, Syncthing, Avahi) → openFirewall = true
    # =========================================================================
    firewall = {
      enable = true;
      allowedTCPPorts = [
        # VPN Vocento (DNS via VM)
        53

        # Servicios específicos aurin
        8096                  # Jellyfin (no tiene módulo NixOS)
        8385                  # Syncthing GUI (puerto custom)
        34279                 # Claude Code MCP

        # Puertos custom
        5990 5991 5992 5993
      ];
      allowedUDPPorts = [
        53                    # DNS (VPN Vocento)
      ];
      checkReversePath = false;  # Necesario para bridge VPN
    };
  };
  # =============================================================================
  # FIN ZONA SAGRADA
  # =============================================================================

  # ===========================================================================
  # ETC (DNS via VM, nsswitch)
  # ===========================================================================
  environment.etc = {
    hosts.mode = "0644";
    "nsswitch.conf" = {
      enable = true;
      text = ''
        passwd:    files systemd
        group:     files [success=merge] systemd
        shadow:    files
        sudoers:   files
        hosts:     files mymachines myhostname dns
        networks:  files
        ethers:    files
        services:  files
        protocols: files
        rpc:       files
      '';
    };
    "resolv.conf" = {
      text = ''
        nameserver 192.168.53.12
        nameserver 8.8.8.8
        search grupo.vocento
        options timeout:1 attempts:1 rotate
      '';
      mode = "0644";
    };
  };

  # ===========================================================================
  # SERVICES (especificos de aurin)
  # ===========================================================================
  services = {
    # SSH (con TCP forwarding para JetBrains Gateway)
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "yes";
        PasswordAuthentication = true;
        AllowTcpForwarding = true;
        GatewayPorts = "clientspecified";
        MaxSessions = 100;
        ClientAliveInterval = 60;
        ClientAliveCountMax = 3;
      };
      extraConfig = ''
        MaxStartups 100:30:200
      '';
    };

    # Ollama AI (CUDA optimizado para RTX 5080)
    ollama = {
      enable = true;
      package = pkgs.ollama-cuda;
      host = "0.0.0.0"; # Permitir conexiones externas
      openFirewall = true; # Abrir puerto 11434 automáticamente
      port = 11434; # Especificar puerto explícitamente
      environmentVariables = {
        CUDA_VISIBLE_DEVICES = "0";
        CUDA_LAUNCH_BLOCKING = "0";
        CUDA_CACHE_DISABLE = "0";
        CUDA_AUTO_BOOST = "1";
        OLLAMA_GPU_LAYERS = "70";
        OLLAMA_CUDA_MEMORY = "15800MiB";
        OLLAMA_HOST_MEMORY = "70000MiB";
        OLLAMA_BATCH_SIZE = "128";
        OLLAMA_CONTEXT_SIZE = "32768";
        OLLAMA_PREDICT = "8192";
        NVIDIA_TF32_OVERRIDE = "1";
        CUBLAS_WORKSPACE_CONFIG = ":8192:16";
        CUDA_DEVICE_ORDER = "PCI_BUS_ID";
        OLLAMA_GPU_MEMORY_FRACTION = "0.98";
        OLLAMA_TENSOR_PARALLEL = "1";
        OLLAMA_FLASH_ATTENTION = "1";
        CUDA_CACHE_MAXSIZE = "2147483648";
        NVIDIA_DRIVER_CAPABILITIES = "compute,utility";
        OMP_NUM_THREADS = "72";
        MKL_NUM_THREADS = "72";
        GOMP_CPU_AFFINITY = "0-71";
        OMP_PLACES = "cores";
        OMP_PROC_BIND = "spread";
        OMP_SCHEDULE = "dynamic,4";
        OMP_THREAD_LIMIT = "72";
        NUMA_BALANCING = "1";
        MKL_ENABLE_INSTRUCTIONS = "AVX2";
        MKL_DOMAIN_NUM_THREADS = "36,36";
        MALLOC_TRIM_THRESHOLD = "131072";
        MALLOC_MMAP_THRESHOLD = "131072";
        OLLAMA_KEEP_ALIVE = "24h";
        OLLAMA_MAX_LOADED_MODELS = "1";
        OLLAMA_PRELOAD = "true";
        CUDA_HOST_MEMORY_BUFFER_SIZE = "2048";
        OLLAMA_GPU_CPU_SYNC = "1";
        OLLAMA_PARALLEL_DECODE = "1";
        OLLAMA_MEMORY_POOL = "1";
      };
    };

    # Open WebUI: Usar Docker (nixpkgs roto por ctranslate2)
    # docker run -d -p 3000:8080 --add-host=host.docker.internal:host-gateway \
    #   -v open-webui:/app/backend/data \
    #   -e OLLAMA_BASE_URL=http://host.docker.internal:11434 \
    #   --name open-webui ghcr.io/open-webui/open-webui:main

    # Syncthing (módulo centralizado en modules/services/syncthing.nix)
    # Config: dotfiles.syncthing (abajo)

    # Hardware monitoring
    smartd = {
      enable = true;
      autodetect = true;
    };

    resolved.enable = false;

    # Impresora HP M148dw
    printing = {
      enable = true;
      drivers = [ pkgs.hplip ];
    };

    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
  };

  # ===========================================================================
  # SECURITY (workstation: sudo sin password)
  # ===========================================================================
  security.sudo.wheelNeedsPassword = false;

  # ===========================================================================
  # PROGRAMS
  # ===========================================================================
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    extraCompatPackages = with pkgs; [ proton-ge-bin ];
    package = pkgs.steam.override {
      extraPkgs =
        pkgs: with pkgs; [
          libGL
          libGLU
          vulkan-loader
          vulkan-tools
          mesa
          nvidia-vaapi-driver
          libva
          libva-utils
          xorg.libX11
          xorg.libXcursor
          xorg.libXrandr
          xorg.libXi
          xorg.libXext
          xorg.libXfixes
          xorg.libXrender
          xorg.libXScrnSaver
          xorg.libXcomposite
          xorg.libXdamage
          xorg.libXtst
          nss
          nspr
          at-spi2-atk
          at-spi2-core
          dbus
          cups
          libdrm
          expat
          libxkbcommon
          alsa-lib
          pango
          cairo
          gdk-pixbuf
          gtk3
        ];
    };
  };

  # ===========================================================================
  # PAQUETES ESPECIFICOS AURIN
  # ===========================================================================
  environment.systemPackages = with pkgs; [
    # NUMA tools (Dual Xeon)
    numactl

    # Performance tools
    perf-tools
    sysstat
    dool

    # Benchmarking
    sysbench

    # CPU management
    cpufrequtils
    schedtool
    util-linux

    # Scripts especificos de aurin
    (writeShellScriptBin "temp-monitor" ''
      #!/bin/bash
      watch -n 1 'sensors | grep -E "(Core|Package|temp)" | sort'
    '')

    (writeShellScriptBin "xeon-stress" ''
      #!/bin/bash
      echo "=== DUAL XEON E5-2699v3 STRESS TEST ==="
      echo "CPUs disponibles: $(nproc)"
      echo "NUMA nodes: $(numactl --hardware | grep available)"
      echo ""
      echo "Comandos disponibles:"
      echo "1. stress-ng --cpu 72 --timeout 300s --metrics-brief"
      echo "2. stress-ng --cpu 36 --timeout 180s (un procesador)"
      echo "3. taskset -c 0-35 stress-ng --cpu 36 --timeout 180s (CPU 0)"
      echo "4. taskset -c 36-71 stress-ng --cpu 36 --timeout 180s (CPU 1)"
      echo ""
      echo "Ejecutando test basico de 60 segundos..."
      stress-ng --cpu 72 --timeout 60s --metrics-brief
    '')

    (writeShellScriptBin "numa-info" ''
      #!/bin/bash
      echo "=== INFORMACION NUMA DUAL XEON ==="
      numactl --hardware
      echo ""
      echo "=== BINDING ACTUAL ==="
      numactl --show
      echo ""
      echo "=== ESTADISTICAS NUMA ==="
      numastat
    '')

    # Qwen TTS helper (pre-made voices + voice cloning)
    (writeShellScriptBin "qwen-tts" ''
      #!/bin/bash
      # Wrapper para Qwen TTS en Docker (voces prefabricadas + clonado)
      #
      # MODO 1 - Voces prefabricadas (rapido):
      #   qwen-tts -t "Texto a leer" -v Chelsie -o salida.wav
      #
      # MODO 2 - Clonar tu voz:
      #   qwen-tts --clone -r mi-voz.wav -rt "Transcripcion" -t "Texto nuevo" -o clonado.wav
      #
      # Voces disponibles: Chelsie, Ethan, Aura, Nova, Atlas

      if [ "$#" -lt 2 ]; then
        echo "Qwen TTS - Text-to-Speech con GPU"
        echo ""
        echo "MODO 1 - Voces prefabricadas:"
        echo "  qwen-tts -t 'Hola mundo' [-v Chelsie] [-o salida.wav]"
        echo ""
        echo "MODO 2 - Clonar tu voz:"
        echo "  qwen-tts --clone -r referencia.wav -rt 'texto ref' -t 'texto nuevo'"
        echo ""
        echo "Voces: Chelsie (default), Ethan, Aura, Nova, Atlas"
        echo "Idiomas: Spanish (default), English, Chinese, Japanese, etc."
        exit 1
      fi

      # Verificar imagen Docker
      if ! docker image inspect qwen-tts:cu130 >/dev/null 2>&1; then
        echo "ERROR: Imagen qwen-tts:cu130 no encontrada"
        echo "   Construir: cd ~/dotfiles/containers/qwen-tts && docker build -t qwen-tts:cu130 ."
        exit 1
      fi

      # Verificar/crear volumen cache
      if ! docker volume inspect qwen-tts-cache >/dev/null 2>&1; then
        echo "Creando volumen cache para modelo..."
        docker volume create qwen-tts-cache
      fi

      docker run --rm --device nvidia.com/gpu=all \
        -v qwen-tts-cache:/root/.cache/huggingface \
        -v $HOME/dotfiles/scripts/qwen-tts-clone:/app/qwen-tts-clone:ro \
        -v $HOME/voice-cloning/references:/voice-cloning/references:ro \
        -v $HOME/voice-cloning/output:/voice-cloning/output \
        qwen-tts:cu130 "$@"
    '')

    (writeShellScriptBin "aurin-info" ''
      #!/bin/bash
      echo "=== INFORMACION SISTEMA AURIN ==="
      echo "Hostname: $(hostname)"
      echo "CPUs: $(nproc) threads (dual Xeon E5-2699v3)"
      echo "Memoria: $(free -h | grep Mem | awk '{print $2}')"
      echo "GPU: $(nvidia-smi --query-gpu=name --format=csv,noheader,nounits 2>/dev/null || echo 'RTX 5080')"
      echo ""
      echo "=== AUDIO ==="
      echo "Sistema de audio: $(if systemctl --user is-active pipewire >/dev/null 2>&1; then echo "PipeWire"; else echo "PulseAudio/ALSA"; fi)"
      if pactl info >/dev/null 2>&1; then
        DEFAULT_SINK=$(pactl info | grep "Default Sink" | cut -d: -f2 | xargs)
        echo "Dispositivo por defecto: $DEFAULT_SINK"
        if echo "$DEFAULT_SINK" | grep -i "fiio\|usb.*analog" >/dev/null; then
          echo "[OK] FiiO K7 activo"
        else
          echo "[WARN] FiiO K7 no es el dispositivo por defecto"
        fi
      else
        echo "[ERROR] Sistema de audio no disponible"
      fi
      echo ""
      echo "=== RED ==="
      echo "Interface principal: enp7s0 ($(ip addr show enp7s0 | grep 'inet ' | awk '{print $2}' || echo 'no configurada'))"
      echo "Interface secundaria: enp8s0 ($(ip addr show enp8s0 | grep 'inet ' | awk '{print $2}' || echo 'no configurada'))"
      echo ""
      echo "=== STREAMING ==="
      echo "Sunshine: $(systemctl --user is-active sunshine 2>/dev/null || echo 'inactivo')"
      echo ""
      echo "=== VMS ACTIVAS ==="
      if command -v virsh &> /dev/null; then
        virsh list --all 2>/dev/null || echo "libvirt no disponible"
      else
        echo "virt-manager no instalado"
      fi
      echo ""
      echo "=== DOCKER ==="
      docker ps --format "table {{.Names}}\t{{.Status}}" 2>/dev/null || echo "Docker no disponible"
      echo ""
      echo "=== COMANDOS UTILES ==="
      echo "- fiio-k7-test    - Test completo FiiO K7"
      echo "- sunshine-test   - Test streaming Sunshine"
      echo "- xeon-stress     - Stress test dual Xeon"
      echo "- numa-info       - Informacion NUMA"
      echo "- temp-monitor    - Monitor temperaturas"
      echo "- qwen-tts        - Text-to-Speech (voces prefabricadas o clonado)"
    '')
  ];

  system.stateVersion = "25.05";
}
