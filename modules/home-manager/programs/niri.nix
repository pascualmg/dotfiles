# =============================================================================
# HOME-MANAGER: niri Configuration
# =============================================================================
# Compositor Wayland con paradigma de scroll infinito horizontal.
#
# CONCEPTO:
#   En vez de workspaces tradicionales, tienes una fila infinita de columnas.
#   Scrolleas lateralmente entre ventanas con gestos o teclas.
#   Ideal para pantallas pequenas (13") - siempre ves 1-2 ventanas.
#
# KEYBINDINGS (similar a XMonad):
#   Mod+Shift+Enter -> Terminal (alacritty)
#   Mod+p           -> Launcher (fuzzel)
#   Mod+Shift+c     -> Cerrar ventana
#   Mod+Shift+q     -> Salir de niri
#   Mod+h/l         -> Scroll izq/derecha (columnas)
#   Mod+j/k         -> Foco arriba/abajo (dentro de columna)
#   Mod+f           -> Fullscreen
#   3-finger swipe  -> Scroll entre columnas
#
# USO: dotfiles.niri.enable = true;
# =============================================================================

{ config, pkgs, lib, ... }:

{
  options.dotfiles.niri = {
    enable = lib.mkEnableOption "niri scrolling Wayland compositor";

    terminal = lib.mkOption {
      type = lib.types.str;
      default = "alacritty";
      description = "Terminal emulator command";
    };

    launcher = lib.mkOption {
      type = lib.types.str;
      default = "fuzzel";
      description = "Application launcher command";
    };
  };

  config = lib.mkIf config.dotfiles.niri.enable {
    # niri config via xdg.configFile (no hay modulo programs.niri en home-manager)
    xdg.configFile."niri/config.kdl".text = ''
      // =============================================================================
      // NIRI CONFIG - Generado por home-manager
      // =============================================================================

      // ===== INPUT =====
      input {
          keyboard {
              xkb {
                  layout "us,es"
                  options "grp:alt_shift_toggle,caps:escape"
              }
          }

          touchpad {
              tap
              natural-scroll
              dwt  // disable while typing
          }

          mouse {
              accel-profile "flat"
          }
      }

      // ===== OUTPUT (HiDPI) =====
      output "*" {
          scale 2.0
      }

      // ===== LAYOUT =====
      layout {
          gaps 8

          center-focused-column "never"

          preset-column-widths {
              proportion 0.33333
              proportion 0.5
              proportion 0.66667
          }

          default-column-width { proportion 0.5; }

          focus-ring {
              width 2
              active-color "#8ec07c"
              inactive-color "#504945"
          }
      }

      // ===== SPAWN AT STARTUP =====
      spawn-at-startup "waybar"

      // ===== KEYBINDINGS (igual que XMonad) =====
      binds {
          // Programas
          Mod+Shift+Return { spawn "${config.dotfiles.niri.terminal}"; }
          Mod+p { spawn "${config.dotfiles.niri.launcher}"; }

          // Ventanas
          Mod+Shift+c { close-window; }
          Mod+Shift+q { quit; }
          Mod+f { fullscreen-window; }
          Mod+Space { switch-preset-column-width; }

          // Scroll horizontal (core de niri)
          Mod+h { focus-column-left; }
          Mod+l { focus-column-right; }
          Mod+Shift+h { move-column-left; }
          Mod+Shift+l { move-column-right; }

          // Flechas
          Mod+Left { focus-column-left; }
          Mod+Right { focus-column-right; }

          // Foco vertical
          Mod+j { focus-window-down; }
          Mod+k { focus-window-up; }
          Mod+Shift+j { move-window-down; }
          Mod+Shift+k { move-window-up; }
          Mod+Tab { focus-window-down-or-column-right; }

          // Columnas
          Mod+w { maximize-column; }
          Mod+c { center-column; }

          // Consume/expel
          Mod+Comma { consume-window-into-column; }
          Mod+Period { expel-window-from-column; }

          // Workspaces
          Mod+1 { focus-workspace 1; }
          Mod+2 { focus-workspace 2; }
          Mod+3 { focus-workspace 3; }
          Mod+4 { focus-workspace 4; }
          Mod+5 { focus-workspace 5; }
          Mod+6 { focus-workspace 6; }
          Mod+7 { focus-workspace 7; }
          Mod+8 { focus-workspace 8; }
          Mod+9 { focus-workspace 9; }

          // Mover a workspace
          Mod+Shift+1 { move-column-to-workspace 1; }
          Mod+Shift+2 { move-column-to-workspace 2; }
          Mod+Shift+3 { move-column-to-workspace 3; }
          Mod+Shift+4 { move-column-to-workspace 4; }
          Mod+Shift+5 { move-column-to-workspace 5; }
          Mod+Shift+6 { move-column-to-workspace 6; }
          Mod+Shift+7 { move-column-to-workspace 7; }
          Mod+Shift+8 { move-column-to-workspace 8; }
          Mod+Shift+9 { move-column-to-workspace 9; }

          // Screenshot
          Print { screenshot; }
          Mod+Print { screenshot-window; }

          // Emacs
          Mod+e { spawn "emacs"; }
      }

      // ===== GESTOS TRACKPAD =====
      gestures {
          workspace-swipe {
              fingers 3
              distance 300
          }
      }

      // ===== WINDOW RULES =====
      window-rule {
          // Bordes redondeados
          geometry-corner-radius 8
          clip-to-geometry true
      }
    '';

    # Waybar config para niri
    programs.waybar = {
      enable = true;
      settings = {
        mainBar = {
          layer = "top";
          position = "top";
          height = 32;
          modules-left = [ "niri/workspaces" ];
          modules-center = [ "niri/window" ];
          modules-right = [ "pulseaudio" "network" "battery" "clock" ];

          clock = {
            format = "{:%H:%M}";
            format-alt = "{:%a %d %b}";
          };

          battery = {
            states = {
              warning = 30;
              critical = 15;
            };
            format = "{capacity}% {icon}";
            format-icons = [ "" "" "" "" "" ];
          };

          network = {
            format-wifi = "{essid} ";
            format-disconnected = "";
          };

          pulseaudio = {
            format = "{volume}% {icon}";
            format-muted = "";
            format-icons = {
              default = [ "" "" "" ];
            };
          };
        };
      };

      style = ''
        * {
          font-family: "JetBrainsMono Nerd Font";
          font-size: 14px;
        }

        window#waybar {
          background-color: rgba(40, 40, 40, 0.95);
          color: #ebdbb2;
        }

        #workspaces button {
          padding: 0 12px;
          color: #a89984;
        }

        #workspaces button.active {
          background-color: #8ec07c;
          color: #282828;
          border-radius: 4px;
        }

        #clock, #battery, #network, #pulseaudio {
          padding: 0 12px;
        }

        #battery.warning {
          color: #fabd2f;
        }

        #battery.critical {
          color: #fb4934;
        }
      '';
    };

    # fuzzel (launcher ligero para niri)
    programs.fuzzel = {
      enable = true;
      settings = {
        main = {
          terminal = config.dotfiles.niri.terminal;
          layer = "overlay";
          font = "JetBrainsMono Nerd Font:size=12";
        };
        colors = {
          background = "282828ff";
          text = "ebdbb2ff";
          selection = "8ec07cff";
          selection-text = "282828ff";
        };
      };
    };
  };
}
