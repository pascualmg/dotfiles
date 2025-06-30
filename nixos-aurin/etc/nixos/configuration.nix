# NixOS Aurin - Dual Xeon + RTX 5080 + Home Manager + Stress Testing + SUNSHINE STREAMING

# Configuración OPTIMIZADA para dual Xeon E5-2699v3 (72 threads total) + RTX 5080 streaming
{ config, pkgs, ... }: {

  imports = [
    ./hardware-configuration.nix
    <home-manager/nixos> # Solo esto para Home Manager
  ];

  # ===== UNFREE =====
  nixpkgs.config.allowUnfree = true;

  # ===== HARDWARE RTX 5080 (SOLO LO NECESARIO) =====
  hardware = {
    enableAllFirmware = true;

    # Sintaxis nueva NixOS 25.05
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        nvidia-vaapi-driver
        vaapiVdpau
        libvdpau-va-gl
        vulkan-loader
      ];
    };

    # RTX 5080 - CONFIGURACIÓN ESPECÍFICA
    nvidia = {
      open = true; # CRÍTICO: RTX 5080 requiere drivers abiertos
      package = config.boot.kernelPackages.nvidiaPackages.beta; # Beta para RTX 5080
      modesetting.enable = true;
      nvidiaSettings = true;
      forceFullCompositionPipeline = true;
      powerManagement.enable = true;
      nvidiaPersistenced = true;
    };

    # ===== SENSORES TEMPERATURA (SIMPLIFICADO PARA 25.05) =====
    # Nota: Los sensores se detectan automáticamente en NixOS 25.05
  };

console = {
  earlySetup = true;
  
  # FUENTES (descomenta una):
   font = "ter-p20n";                    # ACTIVA: Terminus unicode ✅
  # font = "ter-116n";                    # ACTIVA: Terminus unicode ✅
  # font = "ter-120n";                  # Terminus grande con unicode ✅  
  # font = "lat9u-16";                  # VGA con unicode ✅
  # font = "lat9w-16";                  # Clásica VGA (sin unicode ❌)
  # font = "Lat2-Terminus16";           # Híbrida con unicode ✅
  # font = "iso01.16";                  # ISO básica (limitada ❌)
  # font = "ter-112n";                  # Terminus pequeña unicode ✅
  # font = "ter-132n";                  # Terminus gigante unicode ✅
  # font = "cp850-8x16";                # CP850 (sin unicode ❌)
  # font = "eurlatgr";                  # European latin ✅
  # font = "latarcyrheb-sun16";         # Multi-idioma unicode ✅
  
  packages = [ 
    pkgs.terminus_font        # Para ter-* (mejor unicode)
    pkgs.kbd                  # Para lat*, iso*, cp*
    pkgs.powerline-fonts      # Caracteres powerline limitados
  ];
  
  keyMap = "us";
  useXkbConfig = false;  # Usar keyMap simple para consola
};  

  # ===== VARIABLES RTX 5080 + SUNSHINE =====
  environment.sessionVariables = {
    # NVIDIA RTX 5080
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    __GL_SYNC_TO_VBLANK = "1";
    __GL_GSYNC_ALLOWED = "1";
    __GL_VRR_ALLOWED = "1";
    __GL_THREADED_OPTIMIZATIONS = "1";

    # ===== SUNSHINE STREAMING OPTIMIZATIONS =====
    # Configuración para NVENC en RTX 5080
    CUDA_VISIBLE_DEVICES = "0";
    NVIDIA_DRIVER_CAPABILITIES = "all";
    __GL_SHOW_GRAPHICS_OSD = "0";  # Desactivar OSD en streaming
    
    # Variables para Wayland/X11 compatibility en streaming
    XDG_SESSION_TYPE = "x11";  # Forzar X11 para mejor compatibilidad
    GDK_BACKEND = "x11";       # GTK en X11 para streaming
    QT_QPA_PLATFORM = "xcb";   # Qt en X11 para streaming

    # ===== VARIABLES OPTIMIZACIÓN DUAL XEON (AÑADIDO) =====
    OMP_NUM_THREADS = "72"; # Usar todos los threads
    MKL_NUM_THREADS = "72"; # Intel MKL optimizado
    OMP_PLACES = "cores"; # Placement optimizado
    OMP_PROC_BIND = "close"; # Binding NUMA-aware

    # ===== VARIABLES VIRTUALIZACIÓN (AÑADIDO) =====
    LIBVIRT_DEFAULT_URI = "qemu:///system"; # Para libvirt
  };

  # ===== BOOT DUAL XEON + RTX 5080 OPTIMIZADO =====
  boot = {
    loader = {
      systemd-boot.enable = true; # Cambiado de GRUB
      efi.canTouchEfiVariables = true;
    };

    # Parámetros kernel RTX 5080 + básicos
    kernelParams = [
      # RTX 5080 (NO TOCAR - FUNCIONABA)
      "nvidia-drm.modeset=1"
      "nvidia-drm.fbdev=1"
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
      "nvidia.NVreg_EnableGpuFirmware=1"
      "nvidia.NVreg_OpenRmEnableUnsupportedGpus=1"
      "video=5120x1440@120"
      "nouveau.modeset=0"
      "ast.modeset=0" # Desactivar ASPEED
      "video=ASPEED-1:d"

      # ===== VIRTUALIZACIÓN (BÁSICO) =====
      "intel_iommu=on"
      "amd_iommu=on"
      "iommu=pt"

      # ===== OPTIMIZACIONES BÁSICAS (SIN TOCAR KERNEL) =====
      "numa_balancing=enable" # NUMA balancing básico
    ];

    initrd.kernelModules = [
      # NVIDIA (NO TOCAR - FUNCIONABA)
      "nvidia"
      "nvidia_modeset"
      "nvidia_uvm"
      "nvidia_drm"
    ];

    # Módulos de virtualización + input para streaming
    kernelModules = [ 
      "kvm-amd" 
      "kvm-intel" 
      "vfio" 
      "vfio_iommu_type1" 
      "vfio_pci" 
      "uinput"  # AÑADIDO: Para Sunshine input capture
    ];
    blacklistedKernelModules = [ "nouveau" "ast" ];

    # ===== FILESYSTEMS ADICIONALES (AÑADIDO) =====
    supportedFilesystems = [ "ntfs" ];

    # ===== OPTIMIZACIONES DUAL XEON MEJORADAS + STREAMING =====
    kernel.sysctl = {
      # Memoria (128GB RAM)
      "vm.swappiness" = 1;
      "vm.vfs_cache_pressure" = 50;
      "vm.dirty_ratio" = 15; # Optimización para stress testing
      "vm.dirty_background_ratio" = 5;
      "vm.dirty_expire_centisecs" = 500;
      "vm.dirty_writeback_centisecs" = 100;

      # File system
      "fs.inotify.max_user_watches" = 524288;
      "vm.max_map_count" = 2147483647; # AUMENTADO: Para RTX 5080 + Sunshine

      # ===== NUMA DUAL XEON OPTIMIZADO (AÑADIDO) =====
      "kernel.numa_balancing" = 1; # NUMA balancing
      "kernel.numa_balancing_scan_delay_ms" = 1000;
      "kernel.numa_balancing_scan_period_min_ms" = 1000;
      "kernel.numa_balancing_scan_period_max_ms" = 60000;

      # Scheduler optimizado para 72 threads
      "kernel.sched_migration_cost_ns" = 5000000;
      "kernel.sched_autogroup_enabled" = 0; # Mejor para stress testing
      "kernel.sched_tunable_scaling" = 0; # Scaling fijo

      # ===== NETWORK OPTIMIZATIONS MEJORADAS PARA STREAMING =====
      "net.core.rmem_default" = 262144;
      "net.core.rmem_max" = 134217728;     # AÑADIDO: Para Sunshine streaming
      "net.core.wmem_default" = 262144; 
      "net.core.wmem_max" = 134217728;     # AÑADIDO: Para Sunshine streaming
      "net.core.netdev_max_backlog" = 30000; # AÑADIDO: Para high throughput
      "net.ipv4.tcp_rmem" = "4096 12582912 134217728";
      "net.ipv4.tcp_wmem" = "4096 12582912 134217728";
      "net.ipv4.tcp_congestion_control" = "bbr"; # AÑADIDO: Para mejor latencia
      "net.ipv4.tcp_low_latency" = 1;      # AÑADIDO: Para streaming
      "net.ipv4.tcp_no_delay" = 1;         # AÑADIDO: Para streaming

      # ===== OPTIMIZACIONES STRESS TESTING (AÑADIDO) =====
      "vm.overcommit_memory" = 1; # Permite overcommit para stress
      "kernel.panic_on_oops" = 0; # No panic en stress extremo
      "kernel.hung_task_timeout_secs" = 0; # Desactivar hung task detector

      # ===== IP FORWARDING PARA VMs (SOLO ESTO PARA RED) =====
      "net.ipv4.ip_forward" = 1;
      "net.ipv4.conf.all.forwarding" = 1;
      "net.ipv4.conf.default.forwarding" = 1;
    };
  };

  # ===== NETWORKING AURIN (SOLO CAMBIOS DE RED) =====
  networking = {
    hostName = "aurin";
    useHostResolvConf = false;
    useDHCP = false;

    # DNS configuración - SOLO LA VM COMO VESPINO
    # nameservers = [ "8.8.8.8" "192.168.53.12" ];
    # search = [ "grupo.vocento" ];

    hosts = { "185.14.56.20" = [ "pascualmg" ]; };
    extraHosts = if builtins.pathExists
    "/home/passh/src/vocento/autoenv/hosts_all.txt" then
      builtins.readFile "/home/passh/src/vocento/autoenv/hosts_all.txt"
    else
      "";

    # Deshabilitar resolv.conf automático (como Vespino)
    resolvconf.enable = false;

    # Configuración de interfaces AURIN
    interfaces = {
      enp7s0 = { # Interface real de Aurin
        useDHCP = false;
        ipv4.addresses = [{
          address = "192.168.2.147"; # IP temporal actual
          prefixLength = 24;
        }];
      };

      # enp8s0 disponible para bridge futuro

      br0 = {
        useDHCP = false;
        ipv4 = {
          addresses = [{
            address = "192.168.53.10";
            prefixLength = 24;
          }];
          # Rutas VPN Vocento (preparadas para migración)
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
              address = "10.200.26.0"; # toran
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
              # Entorno de PRE
              address = "34.175.0.0";
              prefixLength = 16;
              via = "192.168.53.12";
            }
          ];
        };
      };
    };

    # Bridge configuración (preparado para VMs)
    bridges = { br0.interfaces = [ ]; };

    # Ruta por defecto
    defaultGateway = {
      address = "192.168.2.1";
      interface = "enp7s0"; # Interface real de Aurin
    };

    # NetworkManager configuración - COMO VESPINO
    networkmanager = {
      enable = true;
      dns = "none";
      unmanaged = [
        "interface-name:enp7s0" # Interface real de Aurin
        "interface-name:enp8s0" # Segunda interface Aurin
        "interface-name:br0"
        "interface-name:vnet*"
      ];
    };

    # NAT y firewall (preparado para VMs)
    nat = {
      enable = true;
      internalInterfaces = [ "br0" ];
      externalInterface = "enp7s0"; # Interface real de Aurin
      extraCommands = ''
        iptables -t nat -A POSTROUTING -s 192.168.53.0/24 -j MASQUERADE
      '';
    };

    firewall = {
      enable = true;
      allowedTCPPorts = [
        53
        80
        443
        22
        8385
        22000
        8096
        5900
        5901
        8000
        8081
        8080
        3000
        5990
        5991
        5992
        5993
        631
        # ===== SUNSHINE PORTS AÑADIDOS =====
        47984  # HTTPS Web UI
        47989  # HTTP Web UI  
        47990  # HTTPS Web UI (secure)
        48010  # RTSP
      ];
      allowedUDPPorts = [ 
        53 
        22000 
        21027 
        5353
        # ===== SUNSHINE UDP PORTS AÑADIDOS =====
        47998  # Video
        47999  # Audio
        48000  # Control
        48002  # Audio control
        48010  # RTSP
      ];
      allowedUDPPortRanges = [
        # ===== SUNSHINE UDP RANGES AÑADIDOS =====
        { from = 47998; to = 48000; }  # Core streaming
        { from = 8000; to = 8010; }    # Extended range
      ];
      checkReversePath = false;
    };
  };

  # ===== CONFIGURACIÓN ETC (SOLO FORZAR RESOLV.CONF) =====
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
      '';
      mode = "0644";
    };
  };

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

  # ===== USUARIO CON GRUPOS PARA STREAMING =====
  users.users.passh = {
    isNormalUser = true;
    description = "passh";
    extraGroups = [
      "wheel"
      "networkmanager"
      "audio"
      "video"
      "docker"
      "input"        # CRÍTICO: Para Sunshine input capture
      "libvirtd"     # Para virtualización
      "kvm"          # Para virtualización
      "storage"      # Para dispositivos
      "disk"         # Para dispositivos
      "plugdev"      # Para dispositivos
      "render"       # AÑADIDO: Para GPU access en streaming
    ];
    shell = pkgs.fish; # Fish como en tu home.nix
  };

  # ===== XORG + XMONAD + SUNSHINE =====
  services = {

    # ===== SUNSHINE STREAMING SERVER =====
    sunshine = {
  enable = true;
  autoStart = true;
  capSysAdmin = true;
  openFirewall = true;
  package = pkgs.sunshine.override { cudaSupport = true; };
};

    xrdp = {
      enable = true;
      openFirewall = true;
      defaultWindowManager = "${pkgs.writeShellScript "xmonad-session" ''
        export XDG_DATA_DIRS=/run/current-system/sw/share
        export PATH=/run/current-system/sw/bin:$PATH
        exec ${pkgs.xmonad-with-packages}/bin/xmonad
      ''}";
    };

    printing = {
      enable = true;
      drivers = [ pkgs.hplip ];
    };

    # Autodescubrimiento WiFi (ESENCIAL para M148dw)
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    xserver = {
      enable = true;
      videoDrivers = [ "nvidia" ]; # Solo NVIDIA RTX 5080

      xkb = {
        layout = "us,es";
        variant = "";
      };

      windowManager.xmonad = {
        enable = true;
        enableContribAndExtras = true;
        config = pkgs.writeText "xmonad.hs"
          (if builtins.pathExists "/home/passh/.config/xmonad/xmonad.hs" then
            builtins.readFile "/home/passh/.config/xmonad/xmonad.hs"
          else
            "-- XMonad config placeholder");
      };

      desktopManager.xfce.enable = true;

      # RTX 5080 display setup
      displayManager = {
        setupCommands = ''
          ${pkgs.xorg.xrandr}/bin/xrandr --output DP-4 --mode 5120x1440 --rate 120 --primary --dpi 96
          ${pkgs.xorg.xset}/bin/xset r rate 350 50
        '';
      };
    };

    displayManager = { defaultSession = "none+xmonad"; };

    # Picom RTX 5080
    picom = {
      enable = true;
      settings = {
        backend = "glx";
        glx-no-stencil = true;
        glx-no-rebind-pixmap = true;
        unredir-if-possible = true;
        vsync = true;
        refresh-rate = 120;
      };
    };

    # SSH
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "yes";
        PasswordAuthentication = true;
      };
    };

    # 🦙 OLLAMA BESTIAL - RTX 5080 16GB + 70GB RAM + 72 THREADS
    ollama = {
      enable = true;
      acceleration = "cuda";
      environmentVariables = {
        # ===== RTX 5080 16GB AL MÁXIMO + RAM MASIVA =====
        CUDA_VISIBLE_DEVICES = "0";
        CUDA_LAUNCH_BLOCKING = "0";
        CUDA_CACHE_DISABLE = "0";
        CUDA_AUTO_BOOST = "1";

        # ===== CONFIGURACIÓN BESTIAL =====
        OLLAMA_GPU_LAYERS = "70"; # MÁXIMO layers en GPU
        OLLAMA_CUDA_MEMORY = "15800MiB"; # CASI TODA la VRAM (15.8GB)
        OLLAMA_HOST_MEMORY = "70000MiB"; # 70GB RAM para resto del modelo

        # Batch y contexto ENORMES para aprovechar TODO
        OLLAMA_BATCH_SIZE = "128"; # BATCH ENORME
        OLLAMA_CONTEXT_SIZE = "32768"; # CONTEXTO MÁXIMO
        OLLAMA_PREDICT = "8192"; # PREDICCIÓN LARGA

        # ===== OPTIMIZACIONES RTX 5080 EXTREMAS =====
        NVIDIA_TF32_OVERRIDE = "1"; # TF32 activado
        CUBLAS_WORKSPACE_CONFIG = ":8192:16"; # Workspace MASIVO
        CUDA_DEVICE_ORDER = "PCI_BUS_ID";

        # Aprovechar TODA la VRAM disponible
        OLLAMA_GPU_MEMORY_FRACTION = "0.98"; # 98% VRAM
        OLLAMA_TENSOR_PARALLEL = "1";
        OLLAMA_FLASH_ATTENTION = "1";

        # Cache y optimizaciones GPU agresivas
        CUDA_CACHE_MAXSIZE = "2147483648"; # Cache 2GB
        NVIDIA_DRIVER_CAPABILITIES = "compute,utility";

        # ===== DUAL XEON E5-2699v3 MÁXIMA POTENCIA =====
        OMP_NUM_THREADS = "72"; # TODOS los 72 threads
        MKL_NUM_THREADS = "72"; # Intel MKL completo
        GOMP_CPU_AFFINITY = "0-71"; # Todos los cores
        OMP_PLACES = "cores"; # Por cores físicos
        OMP_PROC_BIND = "spread"; # SPREAD para ambos Xeon
        OMP_SCHEDULE = "dynamic,4"; # Scheduling dinámico optimizado

        # ===== OPTIMIZACIONES NUMA DUAL SOCKET =====
        OMP_THREAD_LIMIT = "72";
        NUMA_BALANCING = "1";
        MKL_ENABLE_INSTRUCTIONS = "AVX2"; # AVX2 para Haswell-EP
        MKL_DOMAIN_NUM_THREADS = "36,36"; # 36 threads por NUMA domain

        # ===== GESTIÓN MEMORIA HÍBRIDA INTELIGENTE =====
        MALLOC_TRIM_THRESHOLD = "131072"; # Gestión memoria balanceada
        MALLOC_MMAP_THRESHOLD = "131072";

        # Configuración para modelo gigante híbrido
        OLLAMA_KEEP_ALIVE = "24h"; # Mantener cargado TODO el día
        OLLAMA_MAX_LOADED_MODELS = "1"; # Solo Deepseek 70B
        OLLAMA_PRELOAD = "true"; # Pre-cargar automáticamente

        # ===== COMUNICACIÓN GPU<->CPU OPTIMIZADA =====
        CUDA_HOST_MEMORY_BUFFER_SIZE = "2048"; # Buffer GRANDE para transferencias
        OLLAMA_GPU_CPU_SYNC = "1"; # Sincronización optimizada

        # Optimizaciones híbridas avanzadas
        OLLAMA_PARALLEL_DECODE = "1"; # Decodificación paralela
        OLLAMA_MEMORY_POOL = "1"; # Pool de memoria eficiente
      };
    };

    open-webui = {
      enable = true;
      port = 3000;
      host = "0.0.0.0";
      environment = {
        # Configurar para usar tu instancia local de Ollama
        OLLAMA_API_BASE_URL = "http://localhost:11434";
        # Otras configuraciones opcionales
        WEBUI_AUTH = "false"; # Habilitar autenticación (opcional)
      };
    };

    # ===== SERVICIOS VIRTUALIZACIÓN (AÑADIDO) =====
    spice-vdagentd.enable = true; # Para mejor integración con SPICE
    qemuGuest.enable = true; # Soporte para guest

    # ===== SERVICIOS MONITOREO (AÑADIDO) =====
    # Nota: lm_sensors se configura automáticamente en NixOS 25.05

    # Servicios de hardware monitoring
    smartd = {
      enable = true;
      autodetect = true;
    };

    # Desactivar servicios que pueden interferir (SOLO PARA RED)
    resolved.enable = false;

  };

  # ===== VIRTUALIZACIÓN (IGUAL QUE VESPINO) =====
  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        ovmf.enable = true;
        runAsRoot = true;
      };
      onBoot = "ignore";
      onShutdown = "shutdown";
      allowedBridges = [ "br0" "virbr0" ];
    };
    docker = {
      enable = true;
      autoPrune = {
        enable = true;
        dates = "weekly";
      };
    };
  };

  # ===== NVIDIA CONTAINER TOOLKIT (NUEVA SINTAXIS 25.05) =====
  hardware.nvidia-container-toolkit.enable = true;

  # ===== PAQUETES SISTEMA + SUNSHINE =====
  environment.systemPackages = with pkgs; [
    # Basics mínimos
    wget
    git
    curl
    vim
    htop

    # XMonad system
    xmonad-with-packages
    xmobar
    trayer
    dmenu
    nitrogen
    picom
    alacritty
    gnome-terminal
    xscreensaver

    # X tools
    xorg.setxkbmap
    xorg.xmodmap
    xorg.xinput
    xorg.xset
    dunst
    libnotify
    pciutils
    usbutils
    neofetch

    # RTX 5080 tools
    nvtopPackages.nvidia
    vulkan-tools
    glxinfo

    # Basic clipboard
    xclip

    home-manager
    neovim
    tmux
    byobu

    # ===== SUNSHINE STREAMING TOOLS =====
    (sunshine.override { cudaSupport = true; })  # Sunshine con CUDA para RTX 5080
    moonlight-qt                                  # Cliente Moonlight local
    ffmpeg-full                                   # FFmpeg completo para encoding tests

    # ===== HERRAMIENTAS STRESS TESTING DUAL XEON (AÑADIDO) =====
    stress-ng # Herramienta principal stress testing
    stress # Stress testing básico
    lm_sensors # Sensores temperatura
    mission-center # GUI para sensores (reemplazo de psensor)

    # Monitoreo avanzado
    iotop # Monitoreo I/O
    iftop # Monitoreo red
    powertop # Monitoreo energía
    s-tui # Terminal UI para stress+temp
    hwinfo # Info detallada hardware
    inxi # System info
    dmidecode

    # NUMA tools
    numactl # Control NUMA (incluye libnuma)

    # Performance tools
    perf-tools # Herramientas rendimiento kernel
    sysstat # Estadísticas sistema (sar, iostat)
    dool # Monitor recursos sistema (reemplazo de dstat)

    # Benchmarking
    sysbench # Benchmark sistema
    unixbench # Unix benchmark suite

    # Frequency scaling
    cpufrequtils # Control frecuencia CPU
    cpupower-gui # GUI control CPU

    # Process management
    schedtool # Scheduler tuning
    util-linux # Incluye taskset para CPU affinity

    # ===== VIRTUALIZACIÓN COMPLETA (IGUAL QUE VESPINO) =====
    virt-manager
    virt-viewer
    qemu
    OVMF
    spice-gtk
    spice-protocol
    win-virtio
    swtpm
    bridge-utils
    dnsmasq
    iptables

    #lsp para nix 
    nixd

    # ===== SCRIPTS SUNSHINE + MONITORING =====
    # Temperature monitoring scripts
    (writeShellScriptBin "temp-monitor" ''
      #!/bin/bash
      watch -n 1 'sensors | grep -E "(Core|Package|temp)" | sort'
    '')

    # Stress test script optimizado para dual Xeon
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
      echo "Ejecutando test básico de 60 segundos..."
      stress-ng --cpu 72 --timeout 60s --metrics-brief
    '')

    # NUMA info script
    (writeShellScriptBin "numa-info" ''
      #!/bin/bash
      echo "=== INFORMACIÓN NUMA DUAL XEON ==="
      numactl --hardware
      echo ""
      echo "=== BINDING ACTUAL ==="
      numactl --show
      echo ""
      echo "=== ESTADÍSTICAS NUMA ==="
      numastat
    '')

    # Sunshine test script
    (writeShellScriptBin "sunshine-test" ''
      #!/bin/bash
      echo "=== SUNSHINE STREAMING TEST ==="
      echo "GPU: $(nvidia-smi --query-gpu=name --format=csv,noheader,nounits 2>/dev/null || echo 'No detectada')"
      echo "Driver: $(nvidia-smi --query-gpu=driver_version --format=csv,noheader,nounits 2>/dev/null || echo 'No detectado')"
      echo ""
      echo "=== VERIFICANDO SUNSHINE ==="
      if systemctl --user is-active sunshine >/dev/null 2>&1; then
        echo "✅ Sunshine está corriendo"
      else
        echo "❌ Sunshine NO está corriendo"
        echo "Iniciando Sunshine..."
        systemctl --user start sunshine
      fi
      echo ""
      echo "=== VERIFICANDO PUERTOS ==="
      echo "Web UI: https://localhost:47990"
      if ss -tulpn | grep 47990 >/dev/null; then
        echo "✅ Puerto 47990 abierto"
      else
        echo "❌ Puerto 47990 cerrado"
      fi
      echo ""
      echo "=== NVENC TEST ==="
      ffmpeg -hide_banner -f lavfi -i testsrc2=duration=1:size=1920x1080:rate=60 \
             -c:v h264_nvenc -preset fast -f null - 2>/dev/null && \
        echo "✅ H.264 NVENC funcionando" || echo "❌ H.264 NVENC falló"
      
      ffmpeg -hide_banner -f lavfi -i testsrc2=duration=1:size=1920x1080:rate=60 \
             -c:v hevc_nvenc -preset fast -f null - 2>/dev/null && \
        echo "✅ H.265 NVENC funcionando" || echo "❌ H.265 NVENC falló"
      echo ""
      echo "🎮 Conecta desde cliente Moonlight a: $(hostname -I | awk '{print $1}'):47989"
    '')

    # Aurin system info script (actualizado)
    (writeShellScriptBin "aurin-info" ''
      #!/bin/bash
      echo "=== INFORMACIÓN SISTEMA AURIN ==="
      echo "Hostname: $(hostname)"
      echo "CPUs: $(nproc) threads (dual Xeon E5-2699v3)"
      echo "Memoria: $(free -h | grep Mem | awk '{print $2}')"
      echo "GPU: $(nvidia-smi --query-gpu=name --format=csv,noheader,nounits 2>/dev/null || echo 'RTX 5080')"
      echo ""
      echo "=== RED ==="
      echo "Interface principal: enp7s0 ($(ip addr show enp7s0 | grep 'inet ' | awk '{print $2}' || echo 'no configurada'))"
      echo "Interface secundaria: enp8s0 ($(ip addr show enp8s0 | grep 'inet ' | awk '{print $2}' || echo 'no configurada'))"
      echo ""
      echo "=== STREAMING ==="
      echo "Sunshine: $(systemctl --user is-active sunshine 2>/dev/null || echo 'inactivo')"
      echo "XRDP: $(systemctl is-active xrdp 2>/dev/null || echo 'inactivo')"
      echo ""
      echo "=== VMs ACTIVAS ==="
      if command -v virsh &> /dev/null; then
        virsh list --all 2>/dev/null || echo "libvirt no disponible"
      else
        echo "virt-manager no instalado"
      fi
      echo ""
      echo "=== DOCKER ==="
      docker ps --format "table {{.Names}}\t{{.Status}}" 2>/dev/null || echo "Docker no disponible"
    '')

  ];

  # ===== SECURITY CON SUNSHINE =====
  security = {
    rtkit.enable = true;
    polkit.enable = true;
    sudo.wheelNeedsPassword = true;
  };

  # ===== UDEV RULES PARA SUNSHINE =====
  services.udev.extraRules = ''
    # Sunshine input device rules
    KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"
    SUBSYSTEM=="input", GROUP="input", MODE="0664"
    KERNEL=="event*", GROUP="input", MODE="0664"
  '';

  # ===== NIX SETTINGS =====
  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
      # ===== OPTIMIZACIÓN COMPILACIÓN DUAL XEON (AÑADIDO) =====
      max-jobs = 72; # Usar todos los threads para compilar
      cores = 36; # Cores físicos
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 8d";
    };
  };

  # ===== PROGRAMAS =====
  programs = { 
   fish.enable = true; 
   steam.enable = true;
  };

  fileSystems."/mnt/vespino-storage" = {
    device = "192.168.2.125:/storage";
    fsType = "nfs";
    options = [ "nfsvers=4" ];
  };

  fileSystems."/mnt/vespino-NFS" = {
    device = "192.168.2.125:/NFS";
    fsType = "nfs";
    options = [ "nfsvers=4" ];
  };

  # System version
  system.stateVersion = "25.05";
}
