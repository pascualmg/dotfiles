{ config, pkgs, ... }:

let
  # Definición del canal unstable
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
	<home-manager/nixos> 
	];

  # Permitir paquetes unfree
  nixpkgs.config.allowUnfree = true;
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs;
    [
      # Add any missing dynamic libraries for unpackaged programs here
    ];
  programs.fish.enable = true;
  programs.gamemode.enable = true;

  # Hardware optimizado
  hardware = {
    enableAllFirmware = true;
    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
    };
    nvidia = {
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      modesetting.enable = true;
      open = false;
      nvidiaSettings = true;
      forceFullCompositionPipeline = true;
    };
    pulseaudio = { enable = false; };
  };

  # Variables de entorno optimizadas
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    __GL_SYNC_TO_VBLANK = "1";
    __GL_GSYNC_ALLOWED = "1";
    __GL_VRR_ALLOWED = "1";
    # Añadimos variables para QEMU
    LIBVIRT_DEFAULT_URI = "qemu:///system";
  };

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    # Añadimos módulos necesarios para VM
    kernelModules = [
      "kvm-amd"
      "kvm-intel"
      "vfio"
      "vfio_iommu_type1"
      "vfio_pci"
      "vfio_virqfd"
      "uvcvideo"
    ];
    # Kernel parameters para mejor rendimiento VM
    kernelParams = [ "intel_iommu=on" "amd_iommu=on" "iommu=pt" ];
    supportedFilesystems = [ "ntfs" ];
  };

  #para pipewire
  systemd.user.services = {
    pipewire.wantedBy = [ "default.target" ];
    pipewire-pulse.wantedBy = [ "default.target" ];
  };

  # RustDesk Server Services - NIVEL TOP LEVEL
  systemd.services = {
    rustdesk-hbbs = {
      enable = true;
      description = "RustDesk ID/Rendezvous Server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = "rustdesk";
        Group = "rustdesk";
        Restart = "always";
        RestartSec = "5s";
        WorkingDirectory = "/var/lib/rustdesk";
        StateDirectory = "rustdesk";
        StateDirectoryMode = "0755";
        ExecStart = "${pkgs.rustdesk-server}/bin/hbbs -r 192.168.2.125:21117";
        StandardOutput = "journal";
        StandardError = "journal";
      };
    };

    rustdesk-hbbr = {
      enable = true;
      description = "RustDesk Relay Server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = "rustdesk";
        Group = "rustdesk";
        Restart = "always";
        RestartSec = "5s";
        WorkingDirectory = "/var/lib/rustdesk";
        StateDirectory = "rustdesk";
        StateDirectoryMode = "0755";
        ExecStart = "${pkgs.rustdesk-server}/bin/hbbr";
        StandardOutput = "journal";
        StandardError = "journal";
      };
    };
  };

  networking = {
    hostName = "vespino";
    useHostResolvConf = false;
    useDHCP = false;

    # DNS configuración - solo usar VM
    nameservers = [ "192.168.53.12" ];
    search = [ "grupo.vocento" ];

    hosts = { "185.14.56.20" = [ "pascualmg" ]; };
    extraHosts = if builtins.pathExists
    "/home/passh/src/vocento/autoenv/hosts_all.txt" then
      builtins.readFile "/home/passh/src/vocento/autoenv/hosts_all.txt"
    else
      "";
    # Deshabilitar resolv.conf automático
    resolvconf.enable = false;

    # Configuración de interfaces
    interfaces = {
      enp10s0 = {
        useDHCP = false;
        ipv4.addresses = [{
          address = "192.168.2.125";
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
          # Añadimos las rutas VPN que funcionan
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
              # Entorno de PRE es necesario bypasearlo por la VPN
              # por que si no quiere autentificacion
              address = "34.175.0.0";
              prefixLength = 16;
              via = "192.168.53.12";
            }
          ];
        };
      };
    };

    # Bridge configuración
    bridges = { br0.interfaces = [ ]; };

    # Ruta por defecto
    defaultGateway = {
      address = "192.168.2.1";
      interface = "enp10s0";
    };

    # NetworkManager configuración
    networkmanager = {
      enable = true;
      dns = "default"; # Desactivar DNS de NetworkManager
      unmanaged = [
        "interface-name:enp10s0"
        "interface-name:br0"
        "interface-name:vnet*"
      ];
    };

    # NAT y firewall
    nat = {
      enable = true;
      internalInterfaces = [ "br0" ];
      externalInterface = "enp10s0";
      # Reglas específicas para VPN
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
        8384
        22000
        8096
        5900
        5901
        8000
        8081
        8080
        3000
        111
        2049
        # RustDesk ports
        21115
        21116
        21117
        21118
        21119
      ];
      allowedUDPPorts = [
        53
        22000
        21027
        # RustDesk UDP port
        21116
      ];
      checkReversePath = false;
    };
  };
  # Asegurar IP forwarding
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv4.conf.all.forwarding" = 1;
    "net.ipv4.conf.default.forwarding" = 1;
  };

  environment.etc.hosts.mode = "0644";
  environment.etc = {
    "nsswitch.conf" = {
      enable = true;
      text = ''
        # Mantener todo igual excepto hosts
        passwd:    files systemd
        group:     files [success=merge] systemd
        shadow:    files
        sudoers:   files

        # Cambiar solo el orden de esta línea
        hosts:     files mymachines myhostname dns
        networks:  files

        ethers:    files
        services:  files
        protocols: files
        rpc:       files
      '';
    };
  };

  # Desactivar servicios que pueden interferir
  services = { resolved.enable = false; };

  # Virtualización
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

  sound.enable = true;

  fonts.packages = with pkgs; [ nerdfonts powerline-fonts ];

  # Usuarios (añadido grupo rustdesk a passh)
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
      #para montar disquetes de 5 y 1/4
      "storage"
      "disk"
      "plugdev"
      "davfs2"
      "rustdesk"
    ]; # Añadidos grupos VM + rustdesk
    shell = pkgs.fish;
  };

  # Usuario y grupo para RustDesk
  users.users.rustdesk = {
    isSystemUser = true;
    group = "rustdesk";
    home = "/var/lib/rustdesk";
    createHome = true;
    description = "RustDesk Server User";
  };
  users.groups.rustdesk = { };

  services = {
    xserver = {
      enable = true;
      videoDrivers = [ "nvidia" ];
      xkb = {
        layout = "us,es";
        variant = "";
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

    nfs.server = {
      enable = true;
      exports = ''
        /storage 192.168.2.0/24(rw,sync,no_subtree_check,no_root_squash)
        /NFS 192.168.2.0/24(rw,sync,no_subtree_check,no_root_squash)
      '';
    };

      #🦙
    ollama = {
      enable = true;
      package = unstable.ollama;
      acceleration = "cuda";
      environmentVariables = {
        # Optimizaciones CUDA
        CUDA_VISIBLE_DEVICES = "0";
        CUDA_LAUNCH_BLOCKING = "0";
        CUDA_CACHE_DISABLE = "0";
        CUDA_AUTO_BOOST = "1";

        #        # Optimizaciones específicas de Ollama
        OLLAMA_GPU_LAYERS = "42"; # Aumentado para usar más capas en GPU
        OLLAMA_CUDA_MEMORY = "4000MiB"; # Aumentado a ~5GB
        OLLAMA_BATCH_SIZE = "32"; # Aumentado el batch size

        # Optimizaciones de rendimiento CUDA
        NVIDIA_TF32_OVERRIDE = "1"; # Habilita TF32 para mejor rendimiento
        CUBLAS_WORKSPACE_CONFIG = ":16:8"; # Optimización de workspace

        # Optimizaciones de threading
        OMP_NUM_THREADS = "8"; # Optimizar threads OpenMP
        MKL_NUM_THREADS = "8"; # Optimizar threads MKL
      };
    };

    open-webui = {
      enable = true;
      package = unstable.open-webui;
      port = 3000;
      host = "0.0.0.0";
      environment = {
        # Configurar para usar tu instancia local de Ollama
        OLLAMA_API_BASE_URL = "http://localhost:11434";
        # Otras configuraciones opcionales
        WEBUI_AUTH = "false"; # Habilitar autenticación (opcional)
        # WEBUI_AUTH_USER = "passh"; # Usuario (si habilitas autenticación)
        # WEBUI_AUTH_PASSWORD = "tucontraseñasegura"; # Contraseña (si habilitas auth)
      };
    };

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;

      # Configuración para mejorar la calidad
      extraConfig.pipewire = {
        "context.properties" = {
          "default.clock.rate" = 48000;
          "default.clock.quantum" = 1024;
          "default.clock.min-quantum" = 32;
          "default.clock.max-quantum" = 8192;
        };
      };
    };

    syncthing = {
      enable = true;
      user = "passh";
      group = "users";
      dataDir = "/home/passh";
      openDefaultPorts = true;
      guiAddress = "0.0.0.0:8384";

      settings = {
        devices = {
          "cohete" = {
            id =
              "MJCXI4B-EA5DX64-SY4QGGI-TKPDYG5-Y3OKBIU-XXAAWML-7TXS57Q-GLNQ4AY";
          };
          "pocapullos" = {
            id =
              "OYORVJB-XKOUBKT-NPILWWO-FYXSBAB-Q2FFRMC-YIZB4FW-XX5HDWR-X6K65QE";
          };
          "aurin" = {
            id = "I5C3RVM-G3NN7HI-PU44PDV-GHSR7XK-3TKCRT5-L3SG4QW-GDT2O5D-YOT3DQJ";
          };
        };
        folders = {
          "org" = { # Este es el ID de la carpeta que viene de cohete
            path =
              "/home/passh/org"; # Aquí es donde se va a sincronizar en tu máquina
            devices = [ "cohete" "pocapullos" "aurin" ];
            # Como es una carpeta que ya existe en cohete, quizás necesitemos:
            type = "sendreceive"; # Si quieres sincronización bidireccional
            name = "org";
            ignorePerms = false;
          };
          #ahora para la storage/Camera en mi local que yo comparto solamente con pocapullos
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

    # Servicios adicionales para VM
    spice-vdagentd.enable = true; # Para mejor integración con SPICE
    qemuGuest.enable = true; # Soporte para guest

    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = true;
      };
    };
  };

  programs.tmux.enable = true;

  # Paquetes básicos + VM + RustDesk
  environment.systemPackages = with pkgs; [
    # Tus paquetes existentes
    unstable.alacritty
    home-manager
    byobu
    wget
    git
    curl
    vim
    tree
    unzip
    zip
    nvidia-vaapi-driver
    nvtopPackages.full
    vulkan-tools
    glxinfo
    xorg.setxkbmap
    xorg.xmodmap
    xorg.xinput
    xorg.xset
    dunst
    libnotify
    pciutils
    usbutils
    neofetch
    emacs
    tree-sitter
    xclip
    alsa-utils

    # Audio tools
    easyeffects # Para ecualización y efectos
    helvum # Para routing de audio
    qjackctl # Para cuando uses JACK
    pulseaudio # Para tener las herramientas de línea de comandos
    pulsemixer # TUI mixer
    pavucontrol

    #el lsp de nix
    nil

    # Paquetes para virtualización
    virt-manager
    virt-viewer
    qemu
    OVMF
    spice-gtk
    spice-protocol
    win-virtio # Por si necesitas drivers Windows
    swtpm # Para TPM si lo necesitas
    bridge-utils
    dnsmasq # Para networking
    iptables

    # RustDesk packages
    rustdesk # Cliente RustDesk
    rustdesk-server # Servidor (hbbs + hbbr)
  ];

  security = {
    rtkit.enable = true;
    polkit.enable = true;
    sudo.wheelNeedsPassword = true;
  };

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
  # O añadir todos los certificados
  security.pki.certificateFiles = [
    /home/passh/src/vocento/abc/container.frontal-docker/configure/ssl/rootcav2.vocento.in.pem
    # Puedes agregar más archivos aquí
  ];
  system.stateVersion = "24.05";
}
