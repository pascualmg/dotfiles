# =============================================================================
# HOME-MANAGER: Fish Shell
# =============================================================================
# Shell principal con soporte nativo de home-manager
#
# Usa programs.fish nativo que gestiona:
#   - config.fish
#   - plugins
#   - aliases
#   - abbreviations
#
# No requiere parametrización por máquina (mismo config en todas)
# =============================================================================

{ config, lib, pkgs, ... }:

{
  config = {
    # Fish shell con soporte nativo home-manager
    programs.fish = {
      enable = true;

      # Configuración interactiva
      interactiveShellInit = ''
        # Terminal type for byobu/tmux compatibility
        if not set -q TERM; or test "$TERM" = "dumb"
          set -x TERM xterm-256color
        end

        # PATH additions
        set -x PATH $HOME/.config/emacs/bin $PATH
        set -x PATH $HOME/node_modules/.bin $PATH
        set -x PATH $HOME/.local/bin $PATH
      '';

      # Aliases comunes
      shellAliases = {
        # Git shortcuts
        g = "git";
        gs = "git status";
        gd = "git diff";
        gc = "git commit";
        gp = "git push";
        gl = "git log --oneline --graph";

        # Ls modern con eza
        ls = "eza --icons";
        ll = "eza -la --icons";
        tree = "eza --tree --icons";

        # NixOS helpers (--impure needed for Vocento hosts file)
        nrs = "sudo nixos-rebuild switch --flake ~/dotfiles#aurin --impure";
        nrt = "sudo nixos-rebuild test --flake ~/dotfiles#aurin --impure";
        hms = "home-manager switch";
      };

      # Abbreviations (expanden al escribir)
      shellAbbrs = {
        # Docker
        dc = "docker-compose";
        dps = "docker ps";

        # Nix
        nd = "nix develop";
        nf = "nix flake";
      };

      # Plugins (via home-manager)
      plugins = [
        # Oh My Fish framework (si lo usas)
        # {
        #   name = "omf";
        #   src = pkgs.fetchFromGitHub {
        #     owner = "oh-my-fish";
        #     repo = "oh-my-fish";
        #     rev = "master";
        #     sha256 = "...";
        #   };
        # }
      ];
    };

    # Los archivos conf.d/ y completions/ se pueden copiar si son necesarios
    # home.file.".config/fish/conf.d/custom.fish".source = ...;
  };
}
