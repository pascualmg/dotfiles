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

        # Fish key bindings migration (fish 4.3+)
        set --erase --universal fish_key_bindings

        # Fish theme colors (Solarized Dark)
        set --global fish_color_autosuggestion 586e75
        set --global fish_color_cancel --reverse
        set --global fish_color_command 93a1a1
        set --global fish_color_comment 586e75
        set --global fish_color_cwd green
        set --global fish_color_cwd_root red
        set --global fish_color_end 268bd2
        set --global fish_color_error dc322f
        set --global fish_color_escape 00a6b2
        set --global fish_color_history_current --bold
        set --global fish_color_host normal
        set --global fish_color_host_remote
        set --global fish_color_keyword
        set --global fish_color_match --background=brblue
        set --global fish_color_normal normal
        set --global fish_color_operator 00a6b2
        set --global fish_color_option
        set --global fish_color_param 839496
        set --global fish_color_quote 657b83
        set --global fish_color_redirection 6c71c4
        set --global fish_color_search_match white --background=black
        set --global fish_color_selection white --bold --background=brblack
        set --global fish_color_status red
        set --global fish_color_user brgreen
        set --global fish_color_valid_path --underline
        set --global fish_pager_color_background
        set --global fish_pager_color_completion B3A06D
        set --global fish_pager_color_description B3A06D
        set --global fish_pager_color_prefix cyan --underline
        set --global fish_pager_color_progress brwhite --background=cyan
        set --global fish_pager_color_secondary_background
        set --global fish_pager_color_secondary_completion
        set --global fish_pager_color_secondary_description
        set --global fish_pager_color_secondary_prefix
        set --global fish_pager_color_selected_background --background=brblack
        set --global fish_pager_color_selected_completion
        set --global fish_pager_color_selected_description
        set --global fish_pager_color_selected_prefix
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
