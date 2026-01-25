# =============================================================================
# Home Manager Configuration for passh - DESKTOP
# =============================================================================
# Este modulo extiende core.nix con configuracion especifica de DESKTOP.
# Incluye: X11, Wayland, GUI apps, servicios de usuario, etc.
#
# ESTRUCTURA:
#   core.nix   <- Config minima portable (funciona en Android, servers, etc)
#   passh.nix  <- Este archivo: Desktop-specific (importa core.nix)
#
# REGLA: Todo lo que requiera GUI, X11, Wayland o systemd user services
#        va aqui. Lo portable va en core.nix.
# =============================================================================

{
  config,
  pkgs,
  pkgsMaster,
  lib,
  ...
}:

{
  imports = [
    ./core.nix # Config comun a todas las plataformas
    ./programs/xmonad.nix # XMonad configuration
  ];

  # Desactivamos gestion de configs que manejaremos con stow
  xsession.enable = false;
  programs.bash.enable = false;
  programs.zsh.enable = false;
  programs.emacs.enable = false;

  # NOTA: nixpkgs.config no se usa aqui cuando useGlobalPkgs=true
  # allowUnfree y permittedInsecurePackages se configuran a nivel del flake/sistema

  home = {
    # =========================================================================
    # PATH - Add scripts directory
    # =========================================================================
    # Scripts used by xmonad, xmobar, and other tools
    sessionPath = [ "${config.home.homeDirectory}/dotfiles/scripts" ];
    # =========================================================================
    # PAQUETES DESKTOP - Requieren GUI o son pesados
    # =========================================================================
    # Los paquetes CLI basicos estan en core.nix
    # xmobar se instala via programs/xmobar.nix cuando enable=true
    # emacs se instala via programs/emacs.nix (wrapper inteligente X11/Wayland)
    # =========================================================================
    packages =
      with pkgs;
      [
        # Desktop utils (no estan en core)
        killall
        stow
        lsof
        v4l-utils
        guvcview
        docker-compose
        lazydocker
        filezilla
        dysk

        # Terminal fun (fish greeting)
        fortune                   # Para fortunes-es custom
        pokemon-colorscripts      # Pokemon ASCII aleatorio

        # Shells adicionales
        zsh
        bash

        # XMonad y dependencias
        # xmonad-with-packages  # DISABLED: xmonad configurado a nivel de sistema (modules/xmonad.nix)
        # xmobar  # MIGRATED: ahora via programs/xmobar.nix
        # trayer  # DISABLED: build failure in nixpkgs-unstable (panel.c compilation error)
        dmenu
        xwinwrap
        xscreensaver

        # GNOME extras
        gnome-tweaks
        dconf-editor

        # KDE/Qt extras
        # NOTA: kde-gtk-config removido (no existe en nixpkgs-unstable actual)
        # libsForQt5.kde-gtk-config
        # libsForQt5.breeze-gtk  # REMOVED: no existe en nixpkgs actual
        kdePackages.breeze-gtk # Version Qt6
        nitrogen
        picom
        xfce4-clipman-plugin # Fixed: moved to top-level
        stalonetray # Standalone systray for xfce4-clipman
        flameshot
        # alttab  # DISABLED: build failure in nixpkgs-unstable (getOffendingModifiersMask compilation error)

        # X utils
        xorg.setxkbmap
        xorg.xmodmap
        xorg.xinput
        xorg.xset
        xorg.xrandr
        xorg.xev

        # Emacs dependencias (emacs binarios via programs/emacs.nix)
        # MIGRATED: emacs-pgtk -> programs/emacs.nix (wrapper inteligente X11/Wayland)
        # nodejs_22 -> MOVED to core.nix (portable, needed everywhere)
        # claude-code -> ahora via pkgsMaster (ver abajo)
        tdlib
        tree-sitter
        cmake
        gnumake
        graphviz
        gcc
        libtool
        pkg-config

        # Formatters y Linters
        jq
        nixfmt
        shfmt
        shellcheck
        nodePackages.js-beautify
        nodePackages.stylelint
        html-tidy # HTML/XML formatter (doom :lang web)

        # Language Servers
        nodePackages.intelephense
        nodePackages.typescript-language-server
        clang-tools
        glslang # GLSL validator (doom :lang cc)

        # System monitoring
        mission-center

        # Java & PlantUML
        plantuml

        # Audio
        alsa-utils
        pulseaudio
        pavucontrol

        # Python
        python3

        # Haskell toolchain
        haskellPackages.ghc
        haskell-language-server
        haskellPackages.cabal-install
        stack
        haskellPackages.ormolu
        haskellPackages.fourmolu
        haskellPackages.stylish-haskell
        haskellPackages.hlint
        # haskellPackages.apply-refact  # DISABLED: marked as broken in nixpkgs
        haskellPackages.ghcid
        haskellPackages.hoogle
        haskellPackages.implicit-hie
        haskellPackages.cabal-fmt
        # haskellPackages.retrie  # DISABLED: marked as broken in nixpkgs
        gmp
        zlib

        # System tools
        btop
        s-tui
        pciutils
        usbutils

        # Clipboard
        xclip
        xsel
        xorg.xkill

        # Browsers
        firefox
        google-chrome
        qutebrowser

        # Markdown
        pandoc
        bat

        # IDEs
        pkgsMaster.jetbrains-toolbox

        # Office/Communication
        slack
        teams-for-linux
        telegram-desktop
        postman

        # Media
        simplescreenrecorder
        vlc
        mpv
        (obs-studio.override { cudaSupport = true; })
        ffmpeg-full
        spotify

        # Torrents & Media Server
        qbittorrent
        jellyfin

        # Security
        openssl
        nmap
        wireshark
        etherape
        traceroute
        tcpdump
        gnupg
        pinentry-gnome3 # Fixed: pinentry deprecated, need specific variant

        # Network
        dig

        # AI
        # open-webui  # DISABLED: ctranslate2 build failure in nixpkgs-unstable

        # Gaming
        # duckstation  # TEMP: hash mismatch in nixpkgs-unstable (2026-01-14)
        prismlauncher
        jdk21
      ]
      ++ (with pkgs.python3Packages; [
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
      ])
      ++ [
        # Paquetes de nixpkgs-master (bleeding-edge)
        pkgsMaster.claude-code # 2.1.6 (master) vs 2.1.2 (unstable)
      ];

    # Session variables adicionales para desktop
    # (las basicas como EDITOR, ORG_DIRECTORY estan en core.nix)
    sessionVariables = {
      # Telega (Telegram client para Emacs) - evita hardcodear path en doom config
      TDLIB_PREFIX = "${pkgs.tdlib}";
    };

    # ==========================================================================
    # STOW ACTIVATION (LEGACY - EN PROCESO DE ELIMINACION)
    # ==========================================================================
    # ESTADO MIGRACION STOW -> HOME-MANAGER:
    #   [OK] xmobar   - Migrado (modules/home-manager/programs/xmobar.nix)
    #   [OK] alacritty - Migrado (modules/home-manager/programs/alacritty.nix)
    #   [OK] picom    - Migrado (modules/home-manager/programs/picom.nix)
    #   [OK] fish     - Migrado (modules/home-manager/programs/fish.nix)
    #   [OK] emacs    - Migrado (modules/home-manager/programs/emacs.nix)
    #   [OK] xmonad   - Migrado (modules/home-manager/programs/xmonad.nix) 🎉
    #   [..] composer - Pendiente (bajo riesgo, simple)
    #   [OK] claude-code - Migrado (modules/home-manager/programs/ai-agents.nix)
    #   [OK] opencode - Migrado (modules/home-manager/programs/ai-agents.nix)
    #
    # PLAN: Cuando composer migre, eliminar stow completamente.
    # ==========================================================================
    activation.linkDotfiles = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      echo "Linkeando dotfiles residuales con stow..."
      cd ${config.home.homeDirectory}/dotfiles
      # Solo queda: composer (PHP config)
      # xmonad → Migrado a home-manager (modules/home-manager/programs/xmonad.nix)
      ${pkgs.stow}/bin/stow -v -R -t ${config.home.homeDirectory} \
        composer
    '';
  };

  # =========================================================================
  # GIT y SSH CONFIG -> Movidos a core.nix
  # =========================================================================

  # =========================================================================
  # SERVICIOS DESKTOP
  # =========================================================================
  services = {
    dunst = {
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
  };

  systemd.user.services.picom = {
    Unit = {
      Description = "Picom compositor";
      After = [ "graphical-session-pre.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.picom}/bin/picom --config ${config.home.homeDirectory}/.config/picom/picom.conf";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # =========================================================================
  # DCONF / GSETTINGS (GNOME)
  # =========================================================================
  dconf.settings = {
    "org/gnome/desktop/input-sources" = {
      sources = [
        (lib.hm.gvariant.mkTuple [
          "xkb"
          "us"
        ])
        (lib.hm.gvariant.mkTuple [
          "xkb"
          "es"
        ])
      ];
    };
  };

  # XDG dirs
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
