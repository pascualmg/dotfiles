# =============================================================================
# MODULO COMPARTIDO: Paquetes Comunes del Sistema
# =============================================================================
# Paquetes que AMBAS máquinas (aurin + macbook) necesitan a nivel de sistema
#
# NOTA: Paquetes de usuario van en modules/home-manager/passh.nix
# =============================================================================

{ config, pkgs, lib, ... }:

{
  # ===== PERMITIR PAQUETES UNFREE =====
  nixpkgs.config.allowUnfree = true;

  # ===== PAQUETES DEL SISTEMA =====
  environment.systemPackages = with pkgs; [
    # === BASICOS ===
    vim
    wget
    curl
    git
    htop
    tree
    unzip
    zip
    file        # Detectar tipo de archivo
    which       # Localizar ejecutables

    # === HERRAMIENTAS MODERNAS (reemplazan coreutils) ===
    ripgrep     # rg - grep ultrarapido (Rust)
    fd          # find moderno (Rust)
    bat         # cat con syntax highlight (Rust)
    eza         # ls moderno con iconos (Rust)
    jq          # Procesador JSON - esencial para APIs/configs
    btop        # Monitor sistema moderno (mejor que htop)

    # === TERMINAL MULTIPLEXERS ===
    zellij      # Modern terminal multiplexer (Rust)
    tmux        # Clasico, siempre util
    byobu       # Wrapper tmux con mejoras

    # === NETWORK ===
    networkmanager
    networkmanagerapplet

    # === FILESYSTEM ===
    ntfs3g
    exfat
    dosfstools

    # === HARDWARE INFO ===
    pciutils
    usbutils
    lshw
    inxi        # Info sistema completa

    # === MONITORING ===
    powertop    # Monitor energia (muy util en laptops)
    iotop       # Monitor I/O disco
    iftop       # Monitor trafico red

    # === GAMING MICE ===
    piper       # GUI para ratbagd (config ratones gaming: DPI, botones, LEDs)

    # === STREAMING/REMOTE ===
    moonlight-qt  # Cliente Sunshine/GameStream (conectar a Aurin)

    # === BUILD TOOLS ===
    gcc
    gnumake
    pkg-config

    # === UTILIDADES ===
    stow
    direnv
    nix-direnv
    neofetch    # Info sistema bonita
  ];

  # ===== FUENTES =====
  # Nerd Fonts - TODAS (iconos en terminal, xmobar, IDEs, etc.)
  fonts.packages = with pkgs; [
    # Todas las Nerd Fonts
    nerd-fonts.monoid
    nerd-fonts.fira-code
    nerd-fonts.fira-mono
    nerd-fonts.jetbrains-mono
    nerd-fonts.hack
    nerd-fonts.heavy-data      # Para xmobar (HeavyData Nerd Font)
    nerd-fonts.iosevka
    nerd-fonts.iosevka-term
    nerd-fonts.sauce-code-pro
    nerd-fonts.ubuntu
    nerd-fonts.ubuntu-mono
    nerd-fonts.droid-sans-mono
    nerd-fonts.roboto-mono
    nerd-fonts.inconsolata
    nerd-fonts.meslo-lg
    nerd-fonts.noto
    nerd-fonts.liberation
    nerd-fonts.dejavu-sans-mono
    nerd-fonts.code-new-roman
    nerd-fonts.anonymice
    nerd-fonts.caskaydia-cove
    nerd-fonts.caskaydia-mono
    nerd-fonts.comic-shanns-mono
    nerd-fonts.cousine
    nerd-fonts.d2coding
    nerd-fonts.fantasque-sans-mono
    nerd-fonts.geist-mono
    nerd-fonts.go-mono
    nerd-fonts.hurmit
    nerd-fonts.im-writing
    nerd-fonts.intone-mono
    nerd-fonts.lekton
    nerd-fonts.lilex
    nerd-fonts.martian-mono
    nerd-fonts.monaspace
    nerd-fonts.mononoki
    nerd-fonts.open-dyslexic
    nerd-fonts.overpass
    nerd-fonts.profont
    nerd-fonts.proggy-clean-tt
    nerd-fonts.recursive-mono
    nerd-fonts.shure-tech-mono
    nerd-fonts.space-mono
    nerd-fonts.symbols-only
    nerd-fonts.terminess-ttf
    nerd-fonts.tinos
    nerd-fonts.ubuntu-sans
    nerd-fonts.victor-mono
    nerd-fonts.zed-mono
    # Fallbacks y basicas
    dejavu_fonts
    liberation_ttf
    noto-fonts
    noto-fonts-color-emoji   # Emojis everywhere
  ];

  # ===== PROGRAMAS CON CONFIGURACION =====
  programs.git.enable = true;
  programs.vim.enable = true;
  programs.vim.defaultEditor = true;

  # ===== SHELLS =====
  programs.fish.enable = true;
  programs.bash.completion.enable = true;
}
