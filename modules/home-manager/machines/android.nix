# =============================================================================
# Home Manager Machine Config - Android (Nix-on-Droid)
# =============================================================================
# Configuracion especifica para el movil con Nix-on-Droid.
#
# NOTA: Esta config NO importa passh.nix (que es para desktop).
#       Solo importa core.nix directamente.
#
# Uso: nix-on-droid switch --flake ~/dotfiles
# =============================================================================

{ config, pkgs, lib, pkgsMasterArm, ... }:

{
  # Solo importamos el core (sin desktop stuff)
  imports = [
    ../core.nix
  ];

  # nix-on-droid ya setea username="nix-on-droid" y homeDirectory correctamente
  # No necesitamos override aqui

  # Paquetes adicionales especificos para Android
  # (ligeros, utiles para terminal movil)
  home.packages = with pkgs; [
    # Ya tenemos los basicos de core.nix, añadimos extras utiles
    tmux          # Multiplexor para sesiones SSH
    mosh          # SSH resistente a desconexiones (perfecto para movil)
    fzf           # Fuzzy finder
    lazygit       # Git TUI
    ncdu          # Disk usage TUI

    # Emacs para Doom
    emacs
    ripgrep       # Dependencia de Doom
    fd            # Dependencia de Doom

    # Claude Code (desde nixpkgs-master para version mas reciente)
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
