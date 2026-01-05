# =============================================================================
# Home Manager Configuration for passh
# =============================================================================
# Este modulo define la configuracion de usuario para home-manager.
#
# NOTA: Este archivo es una COPIA PREPARATORIA del home.nix existente,
# adaptada para funcionar con el flake. El home.nix original sigue
# funcionando de forma independiente.
#
# ESTADO: Preparacion - Activo en flake (homeConfigurations.passh)
#
# Cuando se active completamente en NixOS, reemplazara la necesidad de:
#   1. El import <home-manager/nixos> en configuration.nix
#   2. El home.nix standalone que usa fetchTarball
#
# MIGRACION:
#   - fetchTarball eliminado (usa nixpkgs del flake)
#   - Opciones de git actualizadas a nueva sintaxis
#   - Paquetes problematicos comentados o reemplazados
#   - xmobar: migrado a modules/home-manager/programs/xmobar.nix
# =============================================================================

{ config, pkgs, lib, ... }:

{
  # Home Manager basico
  programs.home-manager.enable = true;

  # Desactivamos gestion de configs que manejaremos con stow
  xsession.enable = false;
  programs.bash.enable = false;
  programs.zsh.enable = false;
  programs.emacs.enable = false;

  # NOTA: nixpkgs.config no se usa aquí cuando useGlobalPkgs=true
  # allowUnfree y permittedInsecurePackages se configuran a nivel del flake/sistema

  home = {
    stateVersion = "24.05";
    username = "passh";
    homeDirectory = "/home/passh";

    # =========================================================================
    # PAQUETES
    # =========================================================================
    # NOTA: Usamos pkgs directamente (viene del flake nixpkgs-unstable).
    # Ya no necesitamos fetchTarball para unstable/master.
    #
    # xmobar se instala via programs/xmobar.nix cuando enable=true
    # =========================================================================
    packages = with pkgs; [
      # Core utils
      killall
      stow
      git
      gh
      ripgrep
      fd
      wget
      curl
      neovim
      tree
      unzip
      zip
      gzip
      file
      lsof
      v4l-utils
      guvcview
      docker-compose
      lazydocker
      eza
      filezilla
      direnv
      dysk

      # Shells
      fish
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
      kdePackages.breeze-gtk  # Version Qt6
      nitrogen
      picom
      xfce4-clipman-plugin  # Fixed: moved to top-level
      flameshot
      # alttab  # DISABLED: build failure in nixpkgs-unstable (getOffendingModifiersMask compilation error)

      # X utils
      xorg.setxkbmap
      xorg.xmodmap
      xorg.xinput
      xorg.xset
      xorg.xrandr
      xorg.xev

      # Emacs y dependencias
      emacs
      nodejs_22  # nodejs_24 puede no existir, usar 22 LTS
      claude-code
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
      nixfmt-classic
      shfmt
      shellcheck
      nodePackages.js-beautify
      nodePackages.stylelint
      html-tidy  # HTML/XML formatter (doom :lang web)

      # Language Servers
      nodePackages.intelephense
      nodePackages.typescript-language-server
      clang-tools
      glslang  # GLSL validator (doom :lang cc)

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
      jetbrains-toolbox

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
      pinentry-gnome3  # Fixed: pinentry deprecated, need specific variant

      # Network
      dig

      # AI
      # open-webui  # DISABLED: ctranslate2 build failure in nixpkgs-unstable

      # Gaming
      duckstation
      prismlauncher
      jdk21
    ] ++ (with pkgs.python3Packages; [
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

    # Activaciones
    # ==========================================================================
    # STOW ACTIVATION (LEGACY - EN PROCESO DE ELIMINACIÓN)
    # ==========================================================================
    # ESTADO MIGRACIÓN STOW → HOME-MANAGER:
    #   ✅ xmobar   - Migrado (modules/home-manager/programs/xmobar.nix)
    #   ✅ alacritty - Migrado (modules/home-manager/programs/alacritty.nix)
    #   ✅ picom    - Migrado (modules/home-manager/programs/picom.nix)
    #   ✅ fish     - Migrado (modules/home-manager/programs/fish.nix)
    #   ⏳ xmonad   - Pendiente (config Haskell compleja)
    #   ⏳ composer - Pendiente (bajo riesgo, simple)
    #   ✅ claude-code - Se mantiene en stow (local, no compartir entre máquinas)
    #
    # PLAN: Cuando xmonad y composer migren, eliminar este bloque completamente.
    # ==========================================================================
    activation = {
      linkDotfiles = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
        echo "Linkeando dotfiles residuales con stow..."
        cd ${config.home.homeDirectory}/dotfiles
        # Solo quedan: xmonad (Haskell), composer (PHP), claude-code (local)
        ${pkgs.stow}/bin/stow -v -R -t ${config.home.homeDirectory} \
          composer xmonad claude-code
      '';

      createDirectories = lib.hm.dag.entryAfter [ "linkDotfiles" ] ''
        echo "Creando estructura de directorios..."
        mkdir -p $HOME/org/roam
        mkdir -p $HOME/src
        chmod 700 $HOME/org
        echo "Directorios creados correctamente"
      '';
    };
  };

  # =========================================================================
  # GIT CONFIG
  # =========================================================================
  # NOTA: Sintaxis actualizada para home-manager reciente
  # userName -> settings.user.name
  # userEmail -> settings.user.email
  # extraConfig -> settings
  # =========================================================================
  programs.git = {
    enable = true;
    # Nueva sintaxis para home-manager
    settings = {
      user = {
        name = "Pascual Munoz Galian";
        email = "pmunozg@ces.vocento.com";
      };
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

  # =========================================================================
  # SSH CONFIG
  # =========================================================================
  # NOTA: Deshabilitamos config por defecto para evitar warnings
  # =========================================================================
  programs.ssh = {
    enable = true;
    # Deshabilitar config por defecto para evitar deprecation warnings
    enableDefaultConfig = false;
    matchBlocks = {
      "*" = {
        # Config general para todos los hosts
        addKeysToAgent = "yes";
      };
    };
  };

  # Servicios
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
      ExecStart =
        "${pkgs.picom}/bin/picom --config ${config.home.homeDirectory}/.config/picom/picom.conf";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
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
