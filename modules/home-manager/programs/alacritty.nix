# =============================================================================
# HOME-MANAGER: Alacritty Terminal Emulator
# =============================================================================
# Configuración de Alacritty parametrizable por máquina
#
# Parámetros configurables:
#   - fontSize: Tamaño de fuente (14 para aurin, 18-20 para macbook HiDPI)
#
# Uso en machines/{aurin,macbook}.nix:
#   dotfiles.alacritty.fontSize = 14;
# =============================================================================

{ config, lib, pkgs, ... }:

let
  cfg = config.dotfiles.alacritty;
in
{
  options.dotfiles.alacritty = {
    fontSize = lib.mkOption {
      type = lib.types.number;
      default = 14;
      description = "Font size for Alacritty terminal";
    };
  };

  config = {
    # Usar programs.alacritty nativo de home-manager
    programs.alacritty = {
      enable = true;

      settings = {
        # Window configuration
        window = {
          padding = {
            x = 2;
            y = 2;
          };
          dynamic_padding = true;
          decorations = "full";
          startup_mode = "Windowed";
          title = "Alacritty";
          dynamic_title = true;
        };

        # Scrolling
        scrolling = {
          history = 10000;
          multiplier = 3;
        };

        # Font configuration (parametrizable)
        font = {
          size = cfg.fontSize;

          normal = {
            family = "Hack Nerd Font";
            style = "Regular";
          };

          bold = {
            family = "Hack Nerd Font";
            style = "Bold";
          };

          italic = {
            family = "Hack Nerd Font";
            style = "Italic";
          };

          bold_italic = {
            family = "Hack Nerd Font";
            style = "Bold Italic";
          };
        };

        # Cursor
        cursor = {
          style = "Block";
          unfocused_hollow = false;
        };

        # Keyboard bindings
        keyboard.bindings = [
          {
            key = "Copy";
            mods = "Control";
            action = "Copy";
          }
          {
            key = "Paste";
            mods = "Control";
            action = "Paste";
          }
        ];

        # Mouse
        mouse = {
          hide_when_typing = true;
        };

        # Selection
        selection = {
          save_to_clipboard = true;
        };

        # Colors - Spacemacs Light theme inline
        # (El import de archivo externo no funcionaba, lo ponemos directo)
        colors = {
          primary = {
            background = "#fbf8ef";
            foreground = "#655370";
          };

          cursor = {
            text = "#fbf8ef";
            cursor = "#655370";
          };

          normal = {
            black = "#fbf8ef";
            red = "#f2241f";
            green = "#67b11d";
            yellow = "#b1951d";
            blue = "#4f97d7";
            magenta = "#a31db1";
            cyan = "#2d9574";
            white = "#655370";
          };

          bright = {
            black = "#9e8a8e";
            red = "#f2241f";
            green = "#67b11d";
            yellow = "#b1951d";
            blue = "#4f97d7";
            magenta = "#a31db1";
            cyan = "#2d9574";
            white = "#655370";
          };
        };
      };
    };
  };
}
