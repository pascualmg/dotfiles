# =============================================================================
# HOSTS/VESPINO - Configuracion especifica de Vespino
# =============================================================================
# Servidor secundario / Testing Ground
# Hardware: AMD CPU + NVIDIA RTX 2060 + Monitor ultrawide 5120x1440
#
# Servicios:
#   - Minecraft server
#   - NFS server (/storage, /NFS)
#   - Ollama AI
#   - Syncthing
#
# ZONA SAGRADA: VPN Vocento
#   La configuracion de br0 y rutas a 192.168.53.12 es CRITICA
#   NO MODIFICAR sin plan de rollback
# =============================================================================

{ config, pkgs, lib, pkgsMaster, ... }:

{
  imports = [
    ./minecraft.nix
  ];

  # ===========================================================================
  # DISPLAY SETUP - Monitor ultrawide 5120x1440 @ 120Hz
  # ===========================================================================
  services.xserver.displayManager.setupCommands = ''
    ${pkgs.xorg.xrandr}/bin/xrandr --output DP-0 --mode 5120x1440 --rate 120 --primary --dpi 96
    ${pkgs.xorg.xset}/bin/xset r rate 350 50
  '';

  # ===========================================================================
  # OVERRIDES de modulos comunes
  # ===========================================================================
  # GC menos agresivo - servidor puede acumular mas generaciones
  nix.gc.automatic = false;  # Manual en servidor

  # ===========================================================================
  # PROGRAMS
  # ===========================================================================
  programs.gamemode.enable = true;
  programs.tmux.enable = true;

  # ===========================================================================
  # BOOT (modulos adicionales)
  # ===========================================================================
  boot = {
    kernelModules = [
      "vfio_virqfd"  # Adicional para VMs
      "uvcvideo"     # Webcam

      # WiFi Atheros
      "ath9k"
      "ath10k"
    ];
    supportedFilesystems = [ "ntfs" ];
  };

  # ===========================================================================
  # SYSTEMD USER SERVICES
  # ===========================================================================
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
      # Interface principal - acceso a internet (DHCP para flexibilidad campo/piso)
      enp10s0 = {
        useDHCP = true;
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
            { address = "10.200.26.0"; prefixLength = 24; via = "192.168.53.12"; }
            { address = "10.184.0.0"; prefixLength = 16; via = "192.168.53.12"; }
            { address = "10.186.0.0"; prefixLength = 16; via = "192.168.53.12"; }
            { address = "34.175.0.0"; prefixLength = 16; via = "192.168.53.12"; }
          ];
        };
      };
    };

    bridges = { br0.interfaces = [ ]; };

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

    # =========================================================================
    # FIREWALL - Solo puertos ESPECÍFICOS de vespino
    # =========================================================================
    # Puertos comunes (dev servers, VNC, CUPS) → modules/core/firewall.nix
    # Puertos de módulos (Syncthing, Avahi, Minecraft) → openFirewall = true
    # =========================================================================
    firewall = {
      enable = true;
      allowedTCPPorts = [
        # NFS (solo vespino es servidor NFS)
        111 2049

        # Servicios específicos vespino
        8096                  # Jellyfin
        8384                  # Syncthing GUI (puerto custom)
      ];
      allowedUDPPorts = [
        # NFS
        111 2049
      ];
      checkReversePath = false;
    };
  };
  # =============================================================================
  # FIN ZONA SAGRADA
  # =============================================================================

  # ===========================================================================
  # ETC
  # ===========================================================================
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

  # ===========================================================================
  # SERVICES (especificos de vespino)
  # ===========================================================================
  services = {
    resolved.enable = false;

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
      package = pkgs.ollama;
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

    # Open WebUI: Usar Docker (nixpkgs roto por ctranslate2)
    # docker run -d -p 3000:8080 --add-host=host.docker.internal:host-gateway \
    #   -v open-webui:/app/backend/data \
    #   -e OLLAMA_BASE_URL=http://host.docker.internal:11434 \
    #   --name open-webui ghcr.io/open-webui/open-webui:main

    # PipeWire config especifica
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

    # SSH config
    openssh.settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;
    };
  };

  # ===========================================================================
  # SECURITY
  # ===========================================================================
  security.sudo.wheelNeedsPassword = true;

  # PKI certificate (conditional)
  security.pki.certificateFiles =
    if builtins.pathExists /home/passh/src/vocento/abc/container.frontal-docker/configure/ssl/rootcav2.vocento.in.pem
    then [ /home/passh/src/vocento/abc/container.frontal-docker/configure/ssl/rootcav2.vocento.in.pem ]
    else [];

  # ===========================================================================
  # PAQUETES ESPECIFICOS
  # ===========================================================================
  environment.systemPackages = with pkgs; [
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
  ];

  system.stateVersion = "24.05";
}
