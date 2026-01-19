# =============================================================================
# Machine-specific config: ANDROID (Nix-on-Droid)
# =============================================================================
# Movil con Nix-on-Droid (aarch64-linux)
#
# TERMUX-X11 SUPPORT:
#   1. Instalar Termux-X11 desde F-Droid o GitHub releases
#   2. En Termux normal: pkg install termux-x11-nightly
#   3. Lanzar: termux-x11 :0 &
#   4. Desde nix-on-droid: start-x11 (script incluido)
#
# Uso: nix-on-droid switch --flake ~/dotfiles
# =============================================================================

{ config, pkgs, lib, pkgsMasterArm ? null, hostname, ... }:

let
  hasClaudeCode = pkgsMasterArm != null && (builtins.tryEval pkgsMasterArm.claude-code).success;

  # Script para iniciar XMonad con Termux-X11
  start-x11 = pkgs.writeShellScriptBin "start-x11" ''
    export DISPLAY=:0
    echo "Conectando a Termux-X11 en DISPLAY=:0..."
    echo ""
    echo "Asegurate de tener Termux-X11 corriendo:"
    echo "  1. Abre Termux (no nix-on-droid)"
    echo "  2. Ejecuta: termux-x11 :0"
    echo "  3. Abre la app Termux-X11"
    echo ""
    echo "Lanzando XMonad..."
    exec ${pkgs.haskellPackages.xmonad}/bin/xmonad
  '';

  # Script para lanzar apps X11 individuales
  x11-run = pkgs.writeShellScriptBin "x11-run" ''
    export DISPLAY=:0
    exec "$@"
  '';
in
{
  imports = [
    ../core.nix
  ];

  home.packages = with pkgs; [
    # Sesiones remotas
    tmux
    mosh

    # TUI tools
    fzf
    lazygit
    ncdu

    # Emacs (Doom)
    emacs
    ripgrep
    fd

    # =========================================================================
    # X11 + XMonad (para usar con Termux-X11)
    # =========================================================================
    haskellPackages.xmonad
    haskellPackages.xmonad-contrib
    xterm           # Terminal X11 basica
    dmenu           # Launcher
    feh             # Visor de imagenes / wallpaper

    # Scripts helper
    start-x11
    x11-run
  ] ++ lib.optionals hasClaudeCode [
    pkgsMasterArm.claude-code
  ];

  # Fish shell con config ligera
  programs.fish = {
    enable = true;
    shellAbbrs = {
      g = "git";
      gs = "git status";
      gd = "git diff";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git log --oneline -20";
      l = "eza -la";
      ll = "eza -l";
      ".." = "cd ..";
      "..." = "cd ../..";
    };
    shellInit = ''
      # Prompt simple para movil
      set -g fish_greeting ""

      # Path para nix-on-droid
      fish_add_path ~/.nix-profile/bin
    '';
  };

  # Tmux config basica para sesiones SSH
  programs.tmux = {
    enable = true;
    shortcut = "a";  # Ctrl+a como prefix (mas facil en movil)
    terminal = "screen-256color";
    historyLimit = 10000;
    extraConfig = ''
      # Mouse support (util en algunas apps terminal Android)
      set -g mouse on

      # Status bar simple
      set -g status-style bg=black,fg=white
      set -g status-left "[#S] "
      set -g status-right "%H:%M"
    '';
  };
}
