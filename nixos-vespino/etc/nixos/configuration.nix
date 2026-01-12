# =============================================================================
# NixOS Vespino - Configuracion Limpia
# =============================================================================
# Maquina secundaria - servidor Minecraft, NFS, Ollama
# Limpiado: 2026-01-01 (eliminado RustDesk, servicios VM guest innecesarios)
#
# Hardware:
#   - CPU: Intel/AMD (con soporte KVM)
#   - GPU: NVIDIA (drivers propietarios stable)
#   - Red: enp10s0 (192.168.2.125) + br0 (192.168.53.10) para VPN
#
# Servicios principales:
#   - Minecraft server (ver minecraft.nix)
#   - NFS server (/storage, /NFS)
#   - Ollama + Open-webui
#   - Syncthing
#   - libvirt/Docker para VMs
#
# ZONA SAGRADA - VPN VOCENTO:
#   La configuracion de br0 y rutas a 192.168.53.12 es CRITICA
#   para acceso a infraestructura Vocento via VM Ubuntu + Ivanti
#   NO MODIFICAR sin plan de rollback
# =============================================================================

{ config, pkgs, ... }:

let
  # Definicion del canal unstable
  unstable = import (fetchTarball
    "https://github.com/nixos/nixpkgs/archive/nixos-unstable.tar.gz") {
      config = config.nixpkgs.config;
    };
  master = import
    (fetchTarball "https://github.com/nixos/nixpkgs/archive/master.tar.gz") {
      config = config.nixpkgs.config;
    };

in {
  imports = [
    ./hardware-configuration.nix
    ./minecraft.nix
    # home-manager ahora viene del flake (enableHomeManager = true)
  ];

  # ===== UNFREE =====
  nixpkgs.config.allowUnfree = true;

  # ===== PROGRAMS =====
  programs = {
    nix-ld.enable = true;
    nix-ld.libraries = with pkgs; [
      # Add any missing dynamic libraries for unpackaged programs here
    ];
    fish.enable = true;
    gamemode.enable = true;
    tmux.enable = true;
  };

  # ===== HARDWARE =====
  hardware = {
    enableAllFirmware = true;
    # Actualizado de hardware.opengl (deprecated) a hardware.graphics
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    nvidia = {
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      modesetting.enable = true;
      open = false;  # Drivers propietarios (GPU antigua, no RTX 50xx)
      nvidiaSettings = true;
      forceFullCompositionPipeline = true;
    };
  };

  # ===== ENVIRONMENT VARIABLES =====
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    __GL_SYNC_TO_VBLANK = "1";
    __GL_GSYNC_ALLOWED = "1";
    __GL_VRR_ALLOWED = "1";
    LIBVIRT_DEFAULT_URI = "qemu:///system";
  };

  # ===== BOOT =====
  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;

    # Modulos para virtualizacion (vespino es HOST de VMs)
    kernelModules = [
      "kvm-amd"
      "kvm-intel"
      "vfio"
      "vfio_iommu_type1"
      "vfio_pci"
      "vfio_virqfd"
      "uvcvideo"

      # WiFi Atheros
      "ath9k"     # Atheros 802.11n (older cards)
      "ath10k"    # Atheros 802.11ac (newer cards)
    ];

    kernelParams = [ "intel_iommu=on" "amd_iommu=on" "iommu=pt" ];
    supportedFilesystems = [ "ntfs" ];

    # IP forwarding para NAT de VMs
    kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv4.conf.all.forwarding" = 1;
      "net.ipv4.conf.default.forwarding" = 1;
    };
  };

  # ===== SYSTEMD USER SERVICES =====
  # PipeWire necesita arrancar con la sesion de usuario
  systemd.user.services = {
    pipewire.wantedBy = [ "default.target" ];
    pipewire-pulse.wantedBy = [ "default.target" ];
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
    hostName = "vespino";
    useHostResolvConf = false;
    useDHCP = false;

    # DNS via VM Ubuntu (192.168.53.12)
    nameservers = [ "192.168.53.12" ];
    search = [ "grupo.vocento" ];

    hosts = { "185.14.56.20" = [ "pascualmg" ]; };
    extraHosts = if builtins.pathExists
      "/home/passh/src/vocento/autoenv/hosts_all.txt" then
        builtins.readFile "/home/passh/src/vocento/autoenv/hosts_all.txt"
      else
        "";

    resolvconf.enable = false;

    # Interfaces de red
    interfaces = {
      # Interface principal - acceso a internet
      enp10s0 = {
        useDHCP = false;
        ipv4.addresses = [{
          address = "192.168.2.125";
          prefixLength = 24;
        }];
      };

      # Bridge para VMs - gateway VPN
      br0 = {
        useDHCP = false;
        ipv4 = {
          addresses = [{
            address = "192.168.53.10";
            prefixLength = 24;
          }];
          # Rutas VPN via VM Ubuntu (192.168.53.12)
          routes = [
            { address = "10.180.0.0"; prefixLength = 16; via = "192.168.53.12"; }
            { address = "10.182.0.0"; prefixLength = 16; via = "192.168.53.12"; }
            { address = "192.168.196.0"; prefixLength = 24; via = "192.168.53.12"; }
            { address = "10.200.26.0"; prefixLength = 24; via = "192.168.53.12"; }  # Toran
            { address = "10.184.0.0"; prefixLength = 16; via = "192.168.53.12"; }
            { address = "10.186.0.0"; prefixLength = 16; via = "192.168.53.12"; }
            { address = "34.175.0.0"; prefixLength = 16; via = "192.168.53.12"; }  # PRE
          ];
        };
      };
    };

    bridges = { br0.interfaces = [ ]; };

    defaultGateway = {
      address = "192.168.2.1";
      interface = "enp10s0";
    };

    networkmanager = {
      enable = true;
      dns = "default";
      unmanaged = [
        "interface-name:enp10s0"
        "interface-name:br0"
        "interface-name:vnet*"
      ];
    };

    nat = {
      enable = true;
      internalInterfaces = [ "br0" ];
      externalInterface = "enp10s0";
      extraCommands = ''
        iptables -t nat -A POSTROUTING -s 192.168.53.0/24 -j MASQUERADE
      '';
    };

    firewall = {
      enable = true;
      allowedTCPPorts = [
        53 80 443 22          # Basicos
        8385 8384 22000       # Syncthing
        8096                  # Jellyfin
        5900 5901             # VNC
        8000 8081 8080 3000   # Web apps (Open-webui en 3000)
        111 2049              # NFS
      ];
      allowedUDPPorts = [
        53
        22000 21027           # Syncthing
      ];
      checkReversePath = false;
    };
  };
  # =============================================================================
  # FIN ZONA SAGRADA
  # =============================================================================

  # ===== ETC =====
  environment.etc.hosts.mode = "0644";
  environment.etc = {
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
  };

  # ===== VIRTUALIZATION =====
  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        # ovmf.enable = true;  # REMOVED: OVMF now available by default
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

  # ===== FONTS =====
  fonts.packages = with pkgs; [ powerline-fonts ];  # Fixed: nerdfonts removed (deprecated)

  # ===== USER =====
  users.users.passh = {
    isNormalUser = true;
    description = "passh";
    extraGroups = [
      "wheel"
      "networkmanager"
      "audio"
      "pipewire"
      "video"
      "docker"
      "input"
      "libvirtd"
      "kvm"
      "storage"
      "disk"
      "plugdev"
      "davfs2"
    ];
    shell = pkgs.fish;
  };

  # ===== SERVICES =====
  services = {
    resolved.enable = false;

    # ===== LIBINPUT: Raw input para ratones gaming =====
    # Filosofía HHKB: el hardware manda, no el software
    # Perfil flat = movimiento 1:1 con el DPI del ratón
    libinput = {
      enable = true;
      mouse = {
        accelProfile = "flat";  # Raw input, sin aceleración del sistema
        accelSpeed = "0";       # Velocidad base (respeta DPI del ratón)
      };
    };

    xserver = {
      enable = true;
      videoDrivers = [ "nvidia" ];
      xkb = {
        layout = "us,es";
        variant = "";
        # Alt+Shift para cambiar layout, Caps Lock → Escape
        options = "grp:alt_shift_toggle,caps:escape";
      };
      windowManager.xmonad = {
        enable = true;
        enableContribAndExtras = true;
      };
      desktopManager.xfce.enable = true;
      displayManager = {
        setupCommands = ''
          ${pkgs.xorg.xrandr}/bin/xrandr --output DP-0 --mode 5120x1440 --rate 120 --primary --dpi 96
          ${pkgs.xorg.xset}/bin/xset r rate 350 50
        '';
      };
    };

    # NFS Server
    nfs.server = {
      enable = true;
      exports = ''
        /storage 192.168.2.0/24(rw,sync,no_subtree_check,no_root_squash)
        /NFS 192.168.2.0/24(rw,sync,no_subtree_check,no_root_squash)
      '';
    };

    # Ollama AI
    ollama = {
      enable = true;
      package = unstable.ollama-cuda;  # Fixed: acceleration = "cuda" deprecated
      environmentVariables = {
        CUDA_VISIBLE_DEVICES = "0";
        CUDA_LAUNCH_BLOCKING = "0";
        CUDA_CACHE_DISABLE = "0";
        CUDA_AUTO_BOOST = "1";
        OLLAMA_GPU_LAYERS = "42";
        OLLAMA_CUDA_MEMORY = "4000MiB";
        OLLAMA_BATCH_SIZE = "32";
        NVIDIA_TF32_OVERRIDE = "1";
        CUBLAS_WORKSPACE_CONFIG = ":16:8";
        OMP_NUM_THREADS = "8";
        MKL_NUM_THREADS = "8";
      };
    };

    # Open WebUI
    # DISABLED: Bug en nixpkgs-unstable (ctranslate2 build failure)
    # Habilitar cuando se arregle en upstream
    open-webui = {
      enable = false;  # Temporarily disabled
      package = unstable.open-webui;
      port = 3000;
      host = "0.0.0.0";
      environment = {
        OLLAMA_API_BASE_URL = "http://localhost:11434";
        WEBUI_AUTH = "false";
      };
    };

    # PipeWire Audio
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      extraConfig.pipewire = {
        "context.properties" = {
          "default.clock.rate" = 48000;
          "default.clock.quantum" = 1024;
          "default.clock.min-quantum" = 32;
          "default.clock.max-quantum" = 8192;
        };
      };
    };

    # Syncthing
    syncthing = {
      enable = true;
      user = "passh";
      group = "users";
      dataDir = "/home/passh";
      openDefaultPorts = true;
      guiAddress = "0.0.0.0:8384";
      settings = {
        devices = {
          "cohete" = { id = "MJCXI4B-EA5DX64-SY4QGGI-TKPDYG5-Y3OKBIU-XXAAWML-7TXS57Q-GLNQ4AY"; };
          "pocapullos" = { id = "OYORVJB-XKOUBKT-NPILWWO-FYXSBAB-Q2FFRMC-YIZB4FW-XX5HDWR-X6K65QE"; };
          "aurin" = { id = "I5C3RVM-G3NN7HI-PU44PDV-GHSR7XK-3TKCRT5-L3SG4QW-GDT2O5D-YOT3DQJ"; };
        };
        folders = {
          "org" = {
            path = "/home/passh/org";
            devices = [ "cohete" "pocapullos" "aurin" ];
            type = "sendreceive";
            name = "org";
            ignorePerms = false;
          };
          "storage/Camera" = {
            path = "/home/passh/storage/Camera";
            devices = [ "pocapullos" ];
            type = "sendreceive";
            name = "Camera";
            ignorePerms = false;
          };
        };
        gui = {
          user = "passh";
          password = "capullo100";
        };
      };
    };

    # SSH
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = true;
      };
    };
  };

  # ===== SYSTEM PACKAGES =====
  environment.systemPackages = with pkgs; [
    # Terminal y utilidades
    unstable.alacritty
    home-manager
    byobu
    zellij  # Modern terminal multiplexer (Rust)
    wget
    git
    curl
    vim
    tree
    unzip
    zip

    # NVIDIA y graficos
    nvidia-vaapi-driver
    nvtopPackages.full
    vulkan-tools
    mesa-demos  # Fixed: glxinfo renamed

    # X11
    xorg.setxkbmap
    xorg.xmodmap
    xorg.xinput
    xorg.xset
    dunst
    libnotify

    # Hardware info
    pciutils
    usbutils
    neofetch

    # Editores
    emacs
    tree-sitter
    xclip

    # Audio
    alsa-utils
    easyeffects
    helvum
    qjackctl
    pulseaudio
    pulsemixer
    pavucontrol

    # LSP Nix
    nil

    # Virtualizacion
    virt-manager
    virt-viewer
    qemu
    OVMF
    spice-gtk
    spice-protocol
    virtio-win  # Fixed: win-virtio renamed
    swtpm
    bridge-utils
    dnsmasq
    iptables
  ];

  # ===== SECURITY =====
  security = {
    rtkit.enable = true;
    polkit.enable = true;
    sudo.wheelNeedsPassword = true;
    # PKI certificate (conditional - only if file exists)
    pki.certificateFiles =
      if builtins.pathExists /home/passh/src/vocento/abc/container.frontal-docker/configure/ssl/rootcav2.vocento.in.pem
      then [ /home/passh/src/vocento/abc/container.frontal-docker/configure/ssl/rootcav2.vocento.in.pem ]
      else [];
  };

  # ===== NIX SETTINGS =====
  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
    };
    gc = {
      automatic = false;
      dates = "monthly";
      options = "--delete-older-than 60d";
    };
  };

  system.stateVersion = "24.05";
}
