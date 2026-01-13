# =============================================================================
# HOME-MANAGER: Hyprland Configuration
# =============================================================================
# Compositor Wayland moderno con animaciones, blur y gestos.
#
# KEYBINDINGS (similar a XMonad):
#   Mod+Enter       -> Terminal (alacritty)
#   Mod+p           -> Launcher (wofi)
#   Mod+Shift+q     -> Cerrar ventana
#   Mod+Shift+e     -> Salir de Hyprland
#   Mod+[1-9]       -> Cambiar workspace
#   Mod+Shift+[1-9] -> Mover ventana a workspace
#   Mod+h/j/k/l     -> Mover foco (vim-style)
#   Mod+Shift+h/j/k/l -> Mover ventana
#   Mod+f           -> Fullscreen
#   Mod+Space       -> Toggle floating
#
# USO: dotfiles.hyprland.enable = true;
# =============================================================================

{ config, pkgs, lib, ... }:

{
  options.dotfiles.hyprland = {
    enable = lib.mkEnableOption "Hyprland user configuration";

    terminal = lib.mkOption {
      type = lib.types.str;
      default = "alacritty";
      description = "Terminal emulator command";
    };

    launcher = lib.mkOption {
      type = lib.types.str;
      default = "wofi --show drun";
      description = "Application launcher command";
    };

    modifier = lib.mkOption {
      type = lib.types.str;
      default = "SUPER";
      description = "Main modifier key (SUPER = Win/Cmd)";
    };

    monitorScale = lib.mkOption {
      type = lib.types.str;
      default = "2";
      description = "HiDPI scale factor";
    };
  };

  config = lib.mkIf config.dotfiles.hyprland.enable {
    wayland.windowManager.hyprland = {
      enable = true;

      settings = {
        "$mod" = config.dotfiles.hyprland.modifier;
        "$terminal" = config.dotfiles.hyprland.terminal;
        "$launcher" = config.dotfiles.hyprland.launcher;

        # ===== MONITOR =====
        monitor = ",preferred,auto,${config.dotfiles.hyprland.monitorScale}";

        # ===== INPUT =====
        input = {
          kb_layout = "us,es";
          kb_options = "grp:alt_shift_toggle,caps:escape";
          follow_mouse = 1;
          touchpad = {
            natural_scroll = true;
            tap-to-click = true;
            drag_lock = true;
          };
        };

        # ===== GENERAL =====
        general = {
          gaps_in = 4;
          gaps_out = 8;
          border_size = 2;
          "col.active_border" = "rgba(8ec07cff)";   # Gruvbox green
          "col.inactive_border" = "rgba(504945ff)";
          layout = "dwindle";
        };

        # ===== DECORATION =====
        decoration = {
          rounding = 8;
          blur = {
            enabled = true;
            size = 5;
            passes = 2;
          };
          shadow = {
            enabled = true;
            range = 8;
            render_power = 2;
          };
        };

        # ===== ANIMATIONS =====
        animations = {
          enabled = true;
          bezier = "snappy, 0.05, 0.9, 0.1, 1.05";
          animation = [
            "windows, 1, 4, snappy"
            "windowsOut, 1, 4, default, popin 80%"
            "fade, 1, 4, default"
            "workspaces, 1, 3, default"
          ];
        };

        # ===== LAYOUT =====
        dwindle = {
          pseudotile = true;
          preserve_split = true;
        };

        # ===== KEYBINDINGS (igual que XMonad) =====
        bind = [
          # Programas (como XMonad)
          "$mod SHIFT, Return, exec, $terminal"   # M-S-Enter = terminal
          "$mod, p, exec, $launcher"              # M-p = launcher

          # Ventanas (como XMonad)
          "$mod SHIFT, c, killactive,"            # M-S-c = cerrar ventana
          "$mod, f, fullscreen,"                  # M-f = fullscreen toggle
          "$mod, Space, togglefloating,"          # M-Space = toggle float
          "$mod SHIFT, s, exec, hyprctl dispatch workspaceopt allfloat"  # M-S-s = sink all

          # Foco (vim-style, como XMonad con vim keys)
          "$mod, h, movefocus, l"
          "$mod, l, movefocus, r"
          "$mod, k, movefocus, u"
          "$mod, j, movefocus, d"
          # Foco alternativo (Tab como XMonad default)
          "$mod, Tab, cyclenext,"

          # Mover ventanas
          "$mod SHIFT, h, movewindow, l"
          "$mod SHIFT, l, movewindow, r"
          "$mod SHIFT, k, movewindow, u"
          "$mod SHIFT, j, movewindow, d"

          # Resize (como XMonad M-h/M-l)
          "$mod CTRL, h, resizeactive, -50 0"
          "$mod CTRL, l, resizeactive, 50 0"
          "$mod CTRL, k, resizeactive, 0 -50"
          "$mod CTRL, j, resizeactive, 0 50"

          # Workspaces (cambiar) - igual que XMonad
          "$mod, 1, workspace, 1"
          "$mod, 2, workspace, 2"
          "$mod, 3, workspace, 3"
          "$mod, 4, workspace, 4"
          "$mod, 5, workspace, 5"
          "$mod, 6, workspace, 6"
          "$mod, 7, workspace, 7"
          "$mod, 8, workspace, 8"
          "$mod, 9, workspace, 9"

          # Workspaces (mover ventana) - igual que XMonad
          "$mod SHIFT, 1, movetoworkspace, 1"
          "$mod SHIFT, 2, movetoworkspace, 2"
          "$mod SHIFT, 3, movetoworkspace, 3"
          "$mod SHIFT, 4, movetoworkspace, 4"
          "$mod SHIFT, 5, movetoworkspace, 5"
          "$mod SHIFT, 6, movetoworkspace, 6"
          "$mod SHIFT, 7, movetoworkspace, 7"
          "$mod SHIFT, 8, movetoworkspace, 8"
          "$mod SHIFT, 9, movetoworkspace, 9"

          # Navegacion workspaces (como XMonad M-Left/Right)
          "$mod, Left, workspace, e-1"
          "$mod, Right, workspace, e+1"

          # Scroll workspaces con raton
          "$mod, mouse_down, workspace, e+1"
          "$mod, mouse_up, workspace, e-1"

          # Scratchpads (special workspaces, como XMonad)
          "$mod, a, togglespecialworkspace, terminal"   # M-a = terminal scratchpad
          "$mod, e, togglespecialworkspace, emacs"      # M-e = emacs scratchpad

          # Screenshot (como XMonad Print)
          ", Print, exec, grim -g \"$(slurp)\" - | wl-copy"
          "$mod, Print, exec, grim - | wl-copy"

          # Clipboard (como XMonad M-c)
          "$mod, c, exec, cliphist list | wofi --dmenu | cliphist decode | wl-copy"

          # Salir (como XMonad M-S-q)
          "$mod SHIFT, q, exit,"

          # Reload config
          "$mod, q, exec, hyprctl reload"
        ];

        # Reglas para scratchpads
        workspace = [
          "special:terminal, on-created-empty:alacritty"
          "special:emacs, on-created-empty:emacs"
        ];

        # Mouse bindings
        bindm = [
          "$mod, mouse:272, movewindow"
          "$mod, mouse:273, resizewindow"
        ];

        # ===== AUTOSTART =====
        exec-once = [
          "waybar"
        ];
      };
    };

    # Waybar config (barra de estado)
    programs.waybar = {
      enable = true;
      settings = {
        mainBar = {
          layer = "top";
          position = "top";
          height = 32;
          modules-left = [ "hyprland/workspaces" ];
          modules-center = [ "hyprland/window" ];
          modules-right = [ "pulseaudio" "network" "battery" "clock" ];

          "hyprland/workspaces" = {
            format = "{name}";
            on-click = "activate";
          };

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
  };
}
