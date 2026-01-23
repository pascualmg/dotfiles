# =============================================================================
# Machine-specific config: ANDROID (Nix-on-Droid)
# =============================================================================
# 🔥 CLONE-FIRST: El móvil es un CLON COMPLETO de desktop
#
# Hardware: aarch64-linux (ARM)
# Form factor: Móvil (pantalla táctil, keyboard Termux)
#
# MISMO STACK QUE DESKTOP:
#   ✅ Core tools → core.nix (git, fish, fzf, ripgrep, etc.)
#   ✅ AI agents → opencode (claude-code de pkgsMasterArm si disponible)
#   ✅ Doom Emacs (INTOCABLE)
#   ✅ XMonad + X11 (via Termux-X11, para pantalla externa)
#
# Solo difiere en: hardware (ARM) y form factor.
# Filosofía: No adaptar por "ser móvil", mantener capabilities completas.
#
# TERMUX-X11 SETUP (para pantalla externa):
#   1. Instalar Termux-X11 desde F-Droid o GitHub releases
#   2. En Termux: pkg install termux-x11-nightly
#   3. Lanzar: termux-x11 :0 &
#   4. Desde nix-on-droid: start-x11
#
# Uso: nix-on-droid switch --flake ~/dotfiles
# =============================================================================

{
  config,
  pkgs,
  lib,
  pkgsMasterArm ? null,
  hostname,
  ...
}:

let
  # Claude-code from master (ARM build, optional)
  hasClaudeCode = pkgsMasterArm != null && (builtins.tryEval pkgsMasterArm.claude-code).success;

  # Script para iniciar XMonad con Termux-X11
  start-x11 = pkgs.writeShellScriptBin "start-x11" ''
    export DISPLAY=:0

    # Compilar xmonad si hay config
    if [ -f ~/.config/xmonad/xmonad.hs ]; then
      echo "Compilando tu config de XMonad..."
      ${pkgs.haskellPackages.xmonad}/bin/xmonad --recompile || echo "Warning: compile failed, usando default"
    fi

    echo ""
    echo "Lanzando XMonad en DISPLAY=:0..."
    echo "(Asegurate de tener Termux-X11 corriendo)"
    echo ""

    # Lanzar xmobar en background si existe config
    if [ -f ~/.config/xmobar/xmobarrc ]; then
      ${pkgs.haskellPackages.xmobar}/bin/xmobar &
    fi

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
    ../programs/xmonad.nix # XMonad config (for Termux-X11 + external display)
  ];

  # ===========================================================================
  # OpenCode: DESHABILITADO en Android
  # ===========================================================================
  # EPERM: hard links no permitidos en Android sandbox (bun install falla)
  programs.aiAgents.opencode.enable = false;

  # ===========================================================================
  # CLONE-FIRST PACKAGES
  # ===========================================================================
  # Mismo stack que desktop (aurin, macbook, vespino).
  # Solo difiere en hardware ARM y form factor móvil.

  home.packages =
    with pkgs;
    [
      # Sesiones remotas & TUI
      tmux
      mosh
      fzf
      lazygit
      ncdu

      # Emacs (Doom) - INTOCABLE
      emacs
      ripgrep
      fd

      # =========================================================================
      # X11 + XMonad (Termux-X11 + pantalla externa)
      # =========================================================================
      # Config gestionada por programs/xmonad.nix (mismo que desktop)
      # Binarios instalados aquí para acceso directo
      haskellPackages.xmonad
      haskellPackages.xmonad-contrib
      haskellPackages.xmobar # Status bar
      alacritty # Terminal
      xterm # Terminal fallback
      dmenu # Launcher
      feh # Wallpaper
      picom # Compositor (sombras, transparencias)
      nitrogen # Wallpaper manager
      scrot # Screenshots
      xclip # Clipboard

      # Scripts helper
      start-x11
      x11-run
    ]
    # =========================================================================
    # AI Agents (CLONE-FIRST: mismo stack que desktop)
    # =========================================================================
    ++ lib.optionals hasClaudeCode [ pkgsMasterArm.claude-code ];

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
    shortcut = "a"; # Ctrl+a como prefix (mas facil en movil)
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
