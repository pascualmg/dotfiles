{ config, pkgs, lib, ... }:

let
  unstable = import (fetchTarball
    "https://github.com/nixos/nixpkgs/archive/nixos-unstable.tar.gz") {
      inherit (pkgs) system;
      config = config.nixpkgs.config;
    };
  master = import
    (fetchTarball "https://github.com/nixos/nixpkgs/archive/master.tar.gz") {
      inherit (pkgs) system;
      config = config.nixpkgs.config;
    };
in {
  # Home Manager
  programs.home-manager.enable = true;

  # Desactivamos gestión de configs que manejaremos con stow
  xsession.enable = false;
  programs.bash.enable = false;
  programs.zsh.enable = false;
  programs.emacs.enable = false;

  # Permitir unfree
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [ "qbittorrent-4.6.4" ];

  home = {
    stateVersion = "24.05";
    username = "passh";
    homeDirectory = "/home/passh";

    packages = with pkgs;
      [
        # Core utils
        killall # para matarlos a todos
        stow # para los dotfiles
        git # para olvidar al antiguo y cojonero svn
        gh # para no ser tan viejuno
        ripgrep # para no perderme en el código
        fd # para no perderme en el código
        wget # para descargar cosas
        curl # con esto haces un huevo frito.
        unstable.neovim # para cuando emacs no arranca
        tree # para plantar un pino en el terminal
        unzip # lo contrario de zip
        zip # lo contrario de unzip
        gzip # para comprimir cosas y que doom funcione bien
        file # para saber que eres
        lsof # para saber que haces
        v4l-utils # para que la webcam funcione
        #master.guvcview # para verme la cara
        docker-compose # para componer contenedores
        unstable.lazydocker # tui para docker
        unstable.eza # ls pero con coloricos
        filezilla
        direnv # para cargar variables de entorno automáticamente

        dysk # df pero más bonito

        # los caparazones
        fish
        zsh # para ser cool
        bash # para ser normal

        # XMonad y dependencias
        xmonad-with-packages # que rico esto xmonad + xmobar + trayer + dmenu
        xmobar # cada pixel vale ro
        trayer # para que te acuerdes de lo que arrancaste aquel día
        dmenu # como el mac pero mejor y más feocd
        xwinwrap # para poner de fondo glmatix
        xscreensaver # ya no hay screens que salvar, pero glmatrix es la vida

        # GNOME extras útiles
        gnome-tweaks
        dconf-editor

        # KDE extras útiles
        libsForQt5.kde-gtk-config
        libsForQt5.breeze-gtk
        nitrogen # para cambiar el fondo y creer que soy un hacker
        picom # para que todo tenga sentido , blur , animaciones ,transparencias , ventanas redondicas, etc
        xfce.xfce4-clipman-plugin # para tener un clipboard decente
        flameshot # sin esto no hay memes
        alttab # para cambiar de ventana con alt+tab , como en windoze

        # X utils necesarios
        xorg.setxkbmap # espa;o , ingl'es , espa;ol ingles , espa;ol
        xorg.xmodmap # para cambiar la tecla capslock por ctrl
        xorg.xinput # para configurar el ratón
        xorg.xset # para configurar el ratón
        xorg.xrandr # para configurar las pantallas
        xorg.xev # Útil para debugging de teclas

        # Emacs y dependencias
        unstable.emacs
        # nodejs_19  para el copilot del doom .. entre otras cosas xD
        nodejs_24
        unstable.claude-code
        tdlib # para que funcione el telega ( telegram de emcas doom !   )

        tree-sitter
        cmake
        gnumake
        graphviz
        # para compilar la vterm o lo que sea
        gcc
        gnumake
        cmake
        libtool
        pkg-config

        # Formatters y Linters
        jq # para formatear json
        nixfmt-classic
        shfmt
        shellcheck
        nodePackages.js-beautify
        nodePackages.stylelint

        # Language Servers y herramientas
        nodePackages.intelephense
        nodePackages.typescript-language-server
        clang-tools

        mission-center

        # Java & PlantUML
        plantuml

        # Audio
        alsa-utils
        pulseaudio
        pavucontrol

        # Python ecosystem completo
        python3
        #poetry

        # ═══════════════════════════════════════════════════════════
        # HASKELL TOOLCHAIN - Enfoque Híbrido
        # ═══════════════════════════════════════════════════════════
        # Herramientas globales del sistema. Los flakes pueden override.

        # Core toolchain
        haskellPackages.ghc                    # GHC 9.8.x
        haskell-language-server                # Wrapper + binarios para múltiples GHC
        haskellPackages.cabal-install          # Build tool
        stack                                  # Build tool alternativo

        # Formatters
        haskellPackages.ormolu
        haskellPackages.fourmolu               # Recomendado
        haskellPackages.stylish-haskell

        # Linting
        haskellPackages.hlint
        haskellPackages.apply-refact

        # Development
        haskellPackages.ghcid
        haskellPackages.hoogle

        # Utilidades
        haskellPackages.implicit-hie
        haskellPackages.cabal-fmt
        haskellPackages.retrie

        # Dependencias del sistema
        gmp
        zlib
        gcc

        # Rust ecosystem
        #rustc
        #cargo
        #rustfmt
        #clippy
        #rust-analyzer

        # Herramientas sistema
        master.btop
        master.s-tui
        pciutils
        usbutils

        # Clipboard y utilidades
        xclip
        xsel
        xorg.xkill

        # Browsers
        master.firefox
        master.google-chrome
        master.qutebrowser

        # Markdown
        pandoc

        # inutils
        bat

        #a programal
        master.jetbrains-toolbox

        #oficina
        unstable.slack
        unstable.teams-for-linux
        unstable.telegram-desktop
        postman

        #grabaciones/reproducciones
        unstable.simplescreenrecorder
        unstable.vlc
        unstable.mpv
        (unstable.obs-studio.override { cudaSupport = true; })
        unstable.ffmpeg-full

        #musiqueta algunas veces
        spotify

        #pelis
        unstable.qbittorrent
        master.jellyfin
        # para generar certificados
        openssl

        #pen e testing
        unstable.nmap # para escanear puertos y ver que hay
        wireshark # para ver el tráfico de red
        etherape # para ver el tráfico de red de forma gráfica
        traceroute
        tcpdump # puta vpn de mierda

        #phgp
        gnupg
        pinentry # Para el prompt de la passphrase

        dig
        #llms
        open-webui
        #unstable.ollama
        duckstation # para el xenogear , sin eso no se puede programar

        #mineria
        unstable.prismlauncher
        unstable.jdk21

      ] ++ (with pkgs.python3Packages; [
        # Python packages 🐍
        pip
        black
        flake8
        pylint
        pytest
        pynvim
        pyttsx3
        ipython
        pyflakes
        isort
        setuptools
      ]);

    sessionVariables = {
      EDITOR = "emacs";
      VISUAL = "emacs";
      ORG_DIRECTORY = "$HOME/org";
      ORG_ROAM_DIRECTORY = "$HOME/org/roam";
      PATH = "${pkgs.emacs}/bin:${pkgs.git}/bin:$PATH";
    };

    # Mantenemos la activación para Doom/stow
    activation = {
      # Primero linkeamos dotfiles
      linkDotfiles = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
        echo "🔗 Linkeando dotfiles con stow..."
        cd ${config.home.homeDirectory}/dotfiles
        ${pkgs.stow}/bin/stow -v -R -t ${config.home.homeDirectory} */
      '';

      # Doom install/sync
      #installDoom = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      #  export PATH="${pkgs.emacs}/bin:${pkgs.git}/bin:$PATH"
      #
      #        if [ ! -d "$HOME/.config/emacs" ]; then
      #          echo "🚀 Instalando Doom Emacs..."
      #          ${pkgs.git}/bin/git clone --depth 1 https://github.com/doomemacs/doomemacs $HOME/.config/emacs
      #
      #          echo "📝 Clonando tu configuración personal de Doom..."
      #          ${pkgs.git}/bin/git clone https://github.com/pascualmg/doom $HOME/.config/doom
      #
      #          echo "⚡ Ejecutando doom install..."
      #          $HOME/.config/emacs/bin/doom install --force
      #        else
      #          echo "🔄 Sincronizando Doom Emacs..."
      #          $HOME/.config/emacs/bin/doom sync
      #        fi
      #      '';

      # Directorios base
      createDirectories = lib.hm.dag.entryAfter [ "installDoom" ] ''
        echo "📁 Creando estructura de directorios..."
        mkdir -p $HOME/org/roam
        mkdir -p $HOME/src
        chmod 700 $HOME/org
        echo "✅ Directorios creados correctamente"
      '';
    };
  };

  # Git config
  programs.git = {
    enable = true;
    userName = "Pascual Muñoz Galian";
    userEmail = "pmunozg@ces.vocento.com";
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = false;
      color.ui = "auto";
    };
    ignores = [
      ".org-id-locations"
      "*.org~"
      ".org-roam.db"
      ".DS_Store"
      ".idea"
      "*~"
      "\\#*\\#"
    ];
  };

  # SSH básico
  programs.ssh = {
    enable = true;
    matchBlocks = { "*" = { extraOptions = { AddKeysToAgent = "yes"; }; }; };
  };

  # Servicios esenciales
  services = {
    dunst = { # para notificaciones de escritorio
      enable = true;
      settings = {
        global = {
          font = "monoid 18";
          frame_width = 2;
          frame_color = "#8EC07C";
          corner_radius = 10;
        };
      };
    };
    #  picom = {
    #    enable = true;
    #    extraArgs = [ "--config" "${config.home.homeDirectory}/.config/picom/picom.conf" ];
    #  };
  };
  systemd.user.services.picom = {
    Unit = {
      Description = "Picom compositor";
      After = [ "graphical-session-pre.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart =
        "${pkgs.picom}/bin/picom --config ${config.home.homeDirectory}/.config/picom/picom.conf";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
  #XDG dirs
  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      desktop = "${config.home.homeDirectory}/Desktop";
      documents = "${config.home.homeDirectory}/Documents";
      download = "${config.home.homeDirectory}/Downloads";
      music = "${config.home.homeDirectory}/Music";
      pictures = "${config.home.homeDirectory}/Pictures";
      videos = "${config.home.homeDirectory}/Videos";
    };
  };
}
