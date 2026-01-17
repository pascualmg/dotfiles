# =============================================================================
# NixOS Vespino - Servidor Secundario / Testing Ground
# =============================================================================
# Maquina secundaria - servidor Minecraft, NFS, Ollama
# Limpiado: 2026-01-01 (eliminado RustDesk, servicios VM guest innecesarios)
# Refactorizado: 2026-01-17 (movido comun a modules/common/*)
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
# Modulos compartidos (via flake.nix):
#   - modules/common/*: locale, console, boot, packages, services, users, etc.
#   - modules/desktop/xmonad.nix: Window manager + X11
#   - modules/desktop/hyprland.nix: Wayland compositor
#   - modules/desktop/niri.nix: Wayland compositor
#
# Usuario:
#   - Definido en modules/common/users.nix (compartido)
#
# ZONA SAGRADA - VPN VOCENTO:
#   La configuracion de br0 y rutas a 192.168.53.12 es CRITICA
#   para acceso a infraestructura Vocento via VM Ubuntu + Ivanti
#   NO MODIFICAR sin plan de rollback
# =============================================================================

{ config, pkgs, lib, ... }:

let
  # Definicion del canal unstable (para paquetes especificos)
  unstable = import (fetchTarball
    "https://github.com/nixos/nixpkgs/archive/nixos-unstable.tar.gz") {
      config = config.nixpkgs.config;
    };
in {
  imports = [
    ./hardware-configuration.nix
    ./minecraft.nix

    # Modulo compartido XMonad
    # Path: dotfiles/modules/desktop/xmonad.nix
    ../../../modules/desktop/xmonad.nix

    # home-manager ahora viene del flake (enableHomeManager = true)
    # Usuario passh definido en modules/common/users.nix (via flake)
  ];

  # ===========================================================================
  # XMONAD CONFIG (modulo compartido)
  # ===========================================================================
  desktop.xmonad = {
    enable = true;

    displaySetupCommand = ''
      ${pkgs.xorg.xrandr}/bin/xrandr --output DP-0 --mode 5120x1440 --rate 120 --primary --dpi 96
    '';

    picomBackend = "glx";
    refreshRate = 120;
  };

  # ===========================================================================
  # OVERRIDES de modulos comunes (valores especificos de vespino)
  # ===========================================================================

  # GC menos agresivo - servidor puede acumular mas generaciones
  common.nix.gcDays = 60;
  nix.gc.automatic = false;  # Manual en servidor

  # ===========================================================================
  # CONFIGURACION ESPECIFICA DE VESPINO
  # ===========================================================================

  # ===== PROGRAMS =====
  programs.gamemode.enable = true;
  programs.tmux.enable = true;

  # ===== HARDWARE (NVIDIA) =====
  hardware = {
    enableAllFirmware = true;
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

  # ===== ENVIRONMENT VARIABLES (NVIDIA) =====
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    __GL_SYNC_TO_VBLANK = "1";
    __GL_GSYNC_ALLOWED = "1";
    __GL_VRR_ALLOWED = "1";
    LIBVIRT_DEFAULT_URI = "qemu:///system";
  };

  # ===== BOOT (KVM/IOMMU para VMs) =====
  boot = {
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
      qemu.runAsRoot = true;
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

  # ===== SERVICES (especificos de vespino) =====
  services = {
    resolved.enable = false;

    xserver.videoDrivers = [ "nvidia" ];

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
      package = unstable.ollama-cuda;
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

    # PipeWire Audio (override del modulo comun con config especifica)
    pipewire.extraConfig.pipewire = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.quantum" = 1024;
        "default.clock.min-quantum" = 32;
        "default.clock.max-quantum" = 8192;
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

    # SSH (override del modulo comun)
    openssh.settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;
    };
  };

  # ===== SECURITY =====
  security.sudo.wheelNeedsPassword = true;  # Servidor, con password
  # PKI certificate (conditional - only if file exists)
  security.pki.certificateFiles =
    if builtins.pathExists /home/passh/src/vocento/abc/container.frontal-docker/configure/ssl/rootcav2.vocento.in.pem
    then [ /home/passh/src/vocento/abc/container.frontal-docker/configure/ssl/rootcav2.vocento.in.pem ]
    else [];

  # ===== SYSTEM PACKAGES (solo especificos de vespino) =====
  # Los paquetes comunes estan en modules/common/packages.nix
  environment.systemPackages = with pkgs; [
    # NVIDIA y graficos
    nvidia-vaapi-driver
    nvtopPackages.full
    vulkan-tools
    mesa-demos

    # X11
    xorg.setxkbmap
    xorg.xmodmap
    xorg.xinput
    xorg.xset
    dunst
    libnotify

    # Editores
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

    # Virtualizacion
    virt-viewer
    qemu
    OVMF
    spice-gtk
    spice-protocol
    virtio-win
    swtpm
    bridge-utils
    dnsmasq
    iptables
  ];

  system.stateVersion = "24.05";
}
