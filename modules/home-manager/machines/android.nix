# =============================================================================
# Machine-specific config: ANDROID (Nix-on-Droid)
# =============================================================================
# Movil con Nix-on-Droid (aarch64-linux)
# Hardware: Android phone
#
# NOTA: Importa core.nix directamente (no passh.nix que es desktop-only).
#       No tiene X11, Wayland, ni systemd user services.
#
# Uso: nix-on-droid switch --flake ~/dotfiles
# =============================================================================

{ config, pkgs, lib, pkgsMasterArm ? null, hostname, ... }:

let
  # Claude Code puede no existir en ARM - intentar con fallback
  hasClaudeCode = pkgsMasterArm != null && (builtins.tryEval pkgsMasterArm.claude-code).success;
in
{
  imports = [
    ../core.nix  # Config minima CLI (compartida con desktop)
  ];

  # Paquetes CLI adicionales para movil
  home.packages = with pkgs; [
    # Sesiones remotas
    tmux          # Multiplexor para sesiones SSH
    mosh          # SSH resistente a desconexiones

    # TUI tools
    fzf           # Fuzzy finder
    lazygit       # Git TUI
    ncdu          # Disk usage TUI

    # Emacs (Doom)
    emacs
    ripgrep
    fd
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
