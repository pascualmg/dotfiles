# =============================================================================
# HOME-MANAGER: Picom Compositor
# =============================================================================
# Compositor X11 con efectos (transparencias, sombras, animaciones, blur)
#
# Parámetros configurables:
#   - backend: "egl" para NVIDIA/AMD, "xrender" para Intel
#
# Uso en machines/{aurin,macbook}.nix:
#   dotfiles.picom.backend = "egl";  # aurin (RTX 5080)
#   dotfiles.picom.backend = "xrender";  # macbook (Intel)
# =============================================================================

{ config, lib, pkgs, ... }:

let
  cfg = config.dotfiles.picom;
in
{
  options.dotfiles.picom = {
    backend = lib.mkOption {
      type = lib.types.enum [ "egl" "glx" "xrender" ];
      default = "egl";
      description = "Picom rendering backend (egl for NVIDIA/AMD, xrender for Intel)";
    };
  };

  config = {
    # Picom config via home.file (no hay programs.picom nativo robusto)
    home.file.".config/picom/picom.conf".text = ''
      #################################
      #          Transiciones         #
      #################################
      # Balanceado: Rápido pero visible
      transition-length = 180;
      transition-pow-x = 0.25;
      transition-pow-y = 0.25;
      transition-pow-w = 0.25;
      transition-pow-h = 0.25;
      size-transition = true;

      #################################
      #           Corners             #
      #################################
      corner-radius = 16;
      rounded-corners-exclude = [
        "class_g = 'Polybar'",
        "class_g = 'xmobar'",
        "window_type = 'dock'",
        "window_type = 'desktop'",
        "window_type = 'tooltip'",
        "_GTK_FRAME_EXTENTS@",
        # Gaming y multimedia sin corners para mejor rendimiento
        "class_g = 'Steam'",
        "class_g = 'steam'",
        "class_g = 'lutris'",
        "class_g = 'Lutris'",
        "name *= 'Picture-in-Picture'",
        "class_g = 'mpv'",
        "class_g = 'vlc'"
      ];

      #################################
      #             Shadows           #
      #################################
      shadow = true;
      shadow-radius = 18;
      shadow-opacity = 0.75;
      shadow-offset-x = -14;
      shadow-offset-y = -14;
      shadow-color = "#002b36" #solarized base 3 dark

      shadow-exclude = [
        "name = 'Notification'",
        "class_g = 'Conky'",
        "class_g = 'xmobar'",
        "class_g ?= 'Notify-osd'",
        "class_g = 'Cairo-clock'",
        "class_g = 'slop'",
        "class_g = 'Polybar'",
        "_GTK_FRAME_EXTENTS@",
        "_NET_WM_STATE@ *= '_NET_WM_STATE_HIDDEN'",
        # Gaming apps sin sombra para mejor FPS
        "class_g = 'Steam'",
        "class_g = 'steam'",
        "class_g = 'lutris'",
        "class_g = 'Lutris'"
      ];

      #################################
      #           Fading              #
      #################################
      fading = true;
      # Suave pero eficiente
      fade-in-step = 0.05;
      fade-out-step = 0.05;
      fade-delta = 4;

      fade-exclude = [
        "class_g = 'slop'",
        "window_type = 'dock'",
        "window_type = 'desktop'",
        # Gaming sin fade para mejor rendimiento
        "class_g = 'Steam'",
        "class_g = 'steam'",
        "name *= 'Picture-in-Picture'"
      ]

      #################################
      #   Transparency / Opacity      #
      #################################
      inactive-opacity = 0.90;
      frame-opacity = 1.0;
      inactive-opacity-override = false;
      active-opacity = 1.0;
      inactive-dim = 0.1

      focus-exclude = [
        "class_g = 'Cairo-clock'",
        "class_g = 'slop'",
        "class_g = 'firefox' && argb",
        "class_g = 'Steam'",
        "class_g = 'steam'"
      ];

      # Reglas optimizadas con alacritty
      opacity-rule = [
        "100:class_g = 'firefox'",
        # ALACRITTY rules
        "90:class_g = 'Alacritty' && !focused",
        "95:class_g = 'Alacritty' && focused",
        "100:class_g = 'alacritty' && fullscreen",
        # Apps comunes optimizadas
        "90:class_g = 'Rofi'",
        "95:class_g = 'code-oss'",
        "90:class_g = 'Spotify'",
        # Gaming y multimedia a tope
        "100:class_g = 'Steam'",
        "100:class_g = 'steam'",
        "100:name *= 'Picture-in-Picture'",
        "100:class_g = 'mpv'",
        "100:class_g = 'vlc'",
        # Apps productividad
        "85:class_g = 'Slack'",
        "95:class_g = 'discord'",
        "95:class_g = 'Discord'",
        "90:class_g = 'Thunderbird'",
        # Navegadores alternativos
        "100:class_g = 'Chromium'",
        "100:class_g = 'Google-chrome'"
      ];

      #################################
      #           Blur                #
      #################################
      blur: {
        method = "dual_kawase";
        # Blur alto pero inteligente
        strength = 6;
        background = true;
        background-frame = false;
        background-fixed = false;
        kernel = "11x11gaussian";
      }

      # Blur selectivo para máximo rendimiento
      blur-background-exclude = [
        "window_type = 'dock'",
        "window_type = 'desktop'",
        "_GTK_FRAME_EXTENTS@",
        "class_g = 'slop'",
        "class_g = 'Firefox' && argb",
        # Gaming sin blur - máximo FPS
        "class_g = 'Steam'",
        "class_g = 'steam'",
        "class_g = 'lutris'",
        "class_g = 'Lutris'",
        "name *= 'Picture-in-Picture'",
        "class_g = 'mpv'",
        "class_g = 'vlc'",
        # Fullscreen apps sin blur
        "fullscreen",
        # Chromium/Chrome pueden dar problemas con blur
        "class_g = 'Chromium'",
        "class_g = 'Google-chrome'"
      ];

      #################################
      #        Animations            #
      #################################
      animations = true;
      # Animaciones fluidas y visibles
      animation-window-mass = 0.5;
      # Animaciones más sofisticadas
      animation-for-open-window = "slide-in";
      animation-for-unmap-window = "slide-out";
      animation-for-transient-window = "fly-in";
      # Balanceado: rápido pero suave
      animation-stiffness = 300;
      animation-dampening = 25;
      animation-clamping = false;
      animation-for-workspace-switch-in = "slide-down";
      animation-for-workspace-switch-out = "slide-up";

      # Animaciones selectivas
      animation-exclude = [
        "name = 'Notification'",
        "window_type = 'dock'",
        "window_type = 'desktop'",
        "_GTK_FRAME_EXTENTS@",
        "class_g = 'firefox' && argb",
        "class_g = 'Rofi'",
        "class_g = 'xmobar'",
        "class_g = 'Polybar'",
        # Gaming sin animaciones para mejor rendimiento
        "class_g = 'Steam'",
        "class_g = 'steam'",
        "class_g = 'lutris'",
        "class_g = 'Lutris'",
        "fullscreen"
      ];

      #################################
      #       General Settings        #
      #################################
      experimental-backends = true;
      backend = "${cfg.backend}";  # Parametrizable: egl, glx, o xrender
      vsync = true;
      mark-wmwin-focused = true;
      mark-ovredir-focused = true;
      detect-rounded-corners = true;
      detect-client-opacity = true;
      detect-transient = true;
      glx-no-stencil = true;
      use-damage = true;
      log-level = "warn";
      transparent-clipping = false;

      #################################
      #     GPU Optimizations        #
      #################################
      # Máximo rendimiento
      unredir-if-possible = true;
      unredir-if-possible-delay = 0;
      unredir-if-possible-exclude = [
        "class_g = 'Firefox' && window_type = 'utility'",
        "class_g = 'firefox' && window_type = 'utility'",
        "class_g = '.guvcview-wrapped'",
        # Evita unredir en apps importantes
        "class_g = 'Rofi'",
        "window_type = 'popup_menu'",
        "window_type = 'dropdown_menu'"
      ];

      # GPU optimizations avanzadas
      glx-copy-from-front = false;
      glx-no-rebind-pixmap = true;
      glx-use-copysubbuffermesa = false;
      xrender-sync-fence = true;

      #################################
      #          Window Types         #
      #################################
      wintypes:
      {
        tooltip = {
          fade = true;
          shadow = false;
          opacity = 0.95;
          focus = true;
          full-shadow = false;
          blur-background = true;
        };
        popup_menu = {
          fade = true;
          shadow = true;
          opacity = 0.95;
          focus = true;
          blur-background = true;
        };
        dropdown_menu = {
          fade = true;
          shadow = true;
          opacity = 0.95;
          focus = true;
          blur-background = true;
        };
        dock = {
          shadow = false;
          clip-shadow-above = true;
          blur-background = false;
        };
        utility = {
          fade = true;
          shadow = false;
          opacity = 0.95;
          focus = true;
          blur-background = true;
        };
        # Optimización para gaming
        normal = {
          fade = true;
          shadow = true;
        };
      };
    '';
  };
}
