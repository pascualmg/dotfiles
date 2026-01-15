# =============================================================================
# NixOS Aurin - Dual Xeon E5-2699v3 + RTX 5080 (PURE FLAKE VERSION)
# =============================================================================
# Workstation de alto rendimiento con configuracion modular
#
# NOTA: Esta es la version "pure" para uso con flakes.
# - NO usa <home-manager/nixos> (channel)
# - Home Manager se integra via flake inputs
# - NO requiere --impure flag
#
# Hardware:
#   - CPU: Dual Xeon E5-2699v3 (72 threads)
#   - RAM: 128GB
#   - GPU: NVIDIA RTX 5080 (open drivers)
#   - Audio: FiiO K7 DAC/AMP
#   - Display: 5120x1440@120Hz
#
# Modulos:
#   - nvidia-rtx5080.nix: GPU drivers y CUDA
#   - audio-fiio-k7.nix: PipeWire + FiiO K7
#   - sunshine.nix: Streaming server
#   - printing.nix: HP M148dw + Avahi
#   - xrdp.nix: Remote desktop (disabled)
#   - virtualization.nix: Docker + libvirt
#   - xmonad.nix: Window manager + X11 (modulo compartido)
#
# Usuario:
#   - Definido en modules/common/users.nix (compartido)
# =============================================================================

{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix

    # Modulos hardware
    ./modules/nvidia-rtx5080.nix
    ./modules/audio-fiio-k7.nix

    # Modulos servicios
    ./modules/sunshine.nix
    ./modules/printing.nix
    # ./modules/xrdp.nix  # Desactivado - no se usa
    ./modules/virtualization.nix

    # Modulo compartido XMonad (usado por aurin y macbook)
    # Path: dotfiles/modules/desktop/xmonad.nix
    # Desde: dotfiles/nixos-aurin/etc/nixos/ -> 3 niveles arriba
    ../../../modules/desktop/xmonad.nix

    # Modulo compartido nix-ld (binarios dinamicos: JetBrains Gateway, VSCode Remote, etc.)
    ../../../modules/common/nix-ld.nix

    # Home Manager se integra via flake (no usa <home-manager/nixos>)
    # Usuario passh definido en modules/common/users.nix (via flake)
  ];

  # ===========================================================================
  # XMONAD CONFIG (modulo compartido)
  # ===========================================================================
  # Configuracion especifica del display RTX 5080 + ultrawide 5120x1440@120Hz
  desktop.xmonad = {
    enable = true;

    # RTX 5080 ultrawide setup
    displaySetupCommand = ''
      ${pkgs.xorg.xrandr}/bin/xrandr --output DP-4 --mode 5120x1440 --rate 120 --primary --dpi 96
    '';

    # NVIDIA usa backend GLX
    picomBackend = "glx";

    refreshRate = 120;
  };

  # ===== UNFREE =====
  nixpkgs.config.allowUnfree = true;

  # ===== HARDWARE =====
  hardware.enableAllFirmware = true;

  # ===== CONSOLE =====
  console = {
    earlySetup = true;
    font = "ter-p20n";
    packages = [
      pkgs.terminus_font
      pkgs.kbd
      pkgs.powerline-fonts
    ];
    keyMap = "us";
    useXkbConfig = false;
  };

  # ===== FONTS =====
  fonts.packages = with pkgs; [
    nerd-fonts.symbols-only  # Requerido por Doom Emacs (nerd-icons)
    nerd-fonts.hack
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    dejavu_fonts
    liberation_ttf
    noto-fonts
    noto-fonts-color-emoji
  ];

  # ===== BOOT =====
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    kernelParams = [
      # Desactivar ASPEED (BMC integrado en placa servidor)
      "ast.modeset=0"
      "video=ASPEED-1:d"

      # NUMA balancing
      "numa_balancing=enable"
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

  # ===== ENVIRONMENT VARIABLES =====
  environment.sessionVariables = {
    # Dual Xeon optimization
    OMP_NUM_THREADS = "72";
    MKL_NUM_THREADS = "72";
    OMP_PLACES = "cores";
    OMP_PROC_BIND = "close";
  };

  # ===== NETWORKING =====
  networking = {
    hostName = "aurin";
    useHostResolvConf = false;
    useDHCP = false;

    hosts = { "185.14.56.20" = [ "pascualmg" ]; };
    # NOTA: Requiere --impure para leer paths externos al flake
    # Sin --impure, builtins.pathExists siempre devuelve false para paths externos
    extraHosts = if builtins.pathExists
    "/home/passh/src/vocento/autoenv/hosts_all.txt" then
      builtins.readFile "/home/passh/src/vocento/autoenv/hosts_all.txt"
    else
      "";

    resolvconf.enable = false;

    interfaces = {
      enp7s0 = {
        useDHCP = false;
        ipv4.addresses = [{
          address = "192.168.2.147";
          prefixLength = 24;
        }];
      };

      br0 = {
        useDHCP = false;
        ipv4 = {
          addresses = [{
            address = "192.168.53.10";
            prefixLength = 24;
          }];
          routes = [
            { address = "10.180.0.0"; prefixLength = 16; via = "192.168.53.12"; }
            { address = "10.182.0.0"; prefixLength = 16; via = "192.168.53.12"; }
            { address = "192.168.196.0"; prefixLength = 24; via = "192.168.53.12"; }
            { address = "10.200.26.0"; prefixLength = 24; via = "192.168.53.12"; }
            { address = "10.184.0.0"; prefixLength = 16; via = "192.168.53.12"; }
            { address = "10.186.0.0"; prefixLength = 16; via = "192.168.53.12"; }
            { address = "34.175.0.0"; prefixLength = 16; via = "192.168.53.12"; }
            { address = "34.13.0.0"; prefixLength = 16; via = "192.168.53.12"; }
          ];
        };
      };
    };

    bridges = { br0.interfaces = [ ]; };

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

    firewall = {
      enable = true;
      allowedTCPPorts = [
        53 80 443 22
        8385 22000 8096
        5900 5901
        8000 8081 8080 3000
        5990 5991 5992 5993
        34279  # claude code
      ];
      allowedUDPPorts = [ 53 22000 21027 ];
      checkReversePath = false;
    };
  };

  # ===== ETC =====
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

  # ===== TIMEZONE & LOCALE =====
  time.timeZone = "Europe/Madrid";
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "es_ES.UTF-8";
      LC_IDENTIFICATION = "es_ES.UTF-8";
      LC_MEASUREMENT = "es_ES.UTF-8";
      LC_MONETARY = "es_ES.UTF-8";
      LC_NAME = "es_ES.UTF-8";
      LC_NUMERIC = "es_ES.UTF-8";
      LC_PAPER = "es_ES.UTF-8";
      LC_TELEPHONE = "es_ES.UTF-8";
      LC_TIME = "es_ES.UTF-8";
    };
  };

  # ===== USER: passh =====
  # NOTA: Usuario definido en modules/common/users.nix (compartido via flake)
  # Solo definimos aqui la politica de sudo especifica de aurin

  # ===== SERVICES =====
  services = {
    # SSH (con TCP forwarding para JetBrains Gateway)
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "yes";
        PasswordAuthentication = true;
        AllowTcpForwarding = true;
        GatewayPorts = "clientspecified";
        # Gateway abre muchos canales - aumentar limites
        MaxSessions = 100;
        ClientAliveInterval = 60;
        ClientAliveCountMax = 3;
      };
      extraConfig = ''
        MaxStartups 100:30:200
      '';
    };

    # Ollama AI
    ollama = {
      enable = true;
      package = pkgs.ollama-cuda;  # Antes: acceleration = "cuda" (deprecado)
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

    # Open WebUI
    # DISABLED: Bug en nixpkgs-unstable (ctranslate2 build failure)
    # Habilitar cuando se arregle en upstream
    open-webui = {
      enable = false;  # Temporarily disabled
      port = 3000;
      host = "0.0.0.0";
      environment = {
        OLLAMA_API_BASE_URL = "http://localhost:11434";
        WEBUI_AUTH = "false";
      };
    };

    # Syncthing
    syncthing = {
      enable = true;
      user = "passh";
      dataDir = "/home/passh";
      openDefaultPorts = true;
      guiAddress = "0.0.0.0:8385";
      settings = {
        devices = {
          "vespino" = { id = "C2DZIRD-A65IMBL-34MTS3M-ULVUMOL-6436UPS-DNZU5QI-ITPPIER-LWZCOAG"; };
          "cohete" = { id = "MJCXI4B-EA5DX64-SY4QGGI-TKPDYG5-Y3OKBIU-XXAAWML-7TXS57Q-GLNQ4AY"; };
          "pocapullos" = { id = "OYORVJB-XKOUBKT-NPILWWO-FYXSBAB-Q2FFRMC-YIZB4FW-XX5HDWR-X6K65QE"; };
        };
        folders = {
          "org" = {
            id = "pgore-xe7pu";
            path = "/home/passh/org";
            devices = [ "vespino" "cohete" "pocapullos" ];
            type = "sendreceive";
            ignorePerms = false;
          };
        };
        gui = {
          user = "passh";
          password = "capullo100";
        };
      };
    };

    # Hardware monitoring
    smartd = {
      enable = true;
      autodetect = true;
    };

    resolved.enable = false;
  };

  # ===== SECURITY =====
  security = {
    polkit.enable = true;
    sudo.wheelNeedsPassword = false;  # Aurin: workstation, sin password
  };

  # ===== SYSTEM PACKAGES =====
  environment.systemPackages = with pkgs; [
    # Terminal
    alacritty
    byobu
    tmux
    zellij  # Modern terminal multiplexer (Rust)

    # System monitoring
    iotop
    iftop
    powertop
    hwinfo
    inxi
    dmidecode

    # NUMA tools (Dual Xeon)
    numactl

    # Performance tools
    perf-tools
    sysstat
    dool

    # Benchmarking
    sysbench
    # unixbench  # Disabled: build failure in nixpkgs-unstable

    # CPU management
    cpufrequtils
    cpupower-gui
    schedtool
    util-linux

    # LSP Nix
    nixd

    # Scripts
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
      echo "XRDP: $(systemctl is-active xrdp 2>/dev/null || echo 'inactivo')"
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
    '')
  ];

  # ===== NIX SETTINGS =====
  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
      max-jobs = 72;
      cores = 36;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 8d";
    };
  };

  # ===== PROGRAMS =====
  programs = {
    fish.enable = true;

    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      extraCompatPackages = with pkgs; [ proton-ge-bin ];
      package = pkgs.steam.override {
        extraPkgs = pkgs: with pkgs; [
          libGL libGLU vulkan-loader vulkan-tools mesa
          nvidia-vaapi-driver libva libva-utils
          xorg.libX11 xorg.libXcursor xorg.libXrandr xorg.libXi
          xorg.libXext xorg.libXfixes xorg.libXrender xorg.libXScrnSaver
          xorg.libXcomposite xorg.libXdamage xorg.libXtst
          nss nspr at-spi2-atk at-spi2-core dbus cups libdrm
          expat libxkbcommon alsa-lib pango cairo gdk-pixbuf gtk3
        ];
      };
    };
  };

  system.stateVersion = "25.05";
}
