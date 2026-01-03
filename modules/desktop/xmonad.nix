# =============================================================================
# MODULO COMPARTIDO: XMonad + X11
# =============================================================================
# Window manager XMonad con X.Org y compositor Picom
#
# USO: Compartido entre aurin y macbook
#
# Componentes:
#   - XMonad: Tiling window manager (Haskell)
#   - XFCE: Desktop environment (fallback)
#   - Picom: Compositor con backend adaptativo
#
# Configuracion XMonad:
#   - Lee config de ~/.config/xmonad/xmonad.hs (gestionado via stow)
#   - ContribAndExtras habilitado
#
# Keyboard:
#   - Layout: US + ES
#   - Key repeat: 350ms delay, 50 rate
#
# Display Setup:
#   - Se configura via displaySetupCommand (parametro)
#   - Aurin: 5120x1440@120Hz
#   - Macbook: 2560x1600@60Hz HiDPI
#
# Compositor Picom:
#   - Backend: GLX (NVIDIA) o xrender (Intel)
#   - Configurado via picomBackend (parametro)
# =============================================================================

{ config, pkgs, lib, ... }:

{
  options = {
    desktop.xmonad = {
      enable = lib.mkEnableOption "XMonad window manager";

      displaySetupCommand = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Comando xrandr para configurar display (específico por máquina)";
        example = "\${pkgs.xorg.xrandr}/bin/xrandr --output DP-4 --mode 5120x1440 --rate 120";
      };

      picomBackend = lib.mkOption {
        type = lib.types.str;
        default = "glx";
        description = "Backend de picom (glx para NVIDIA, xrender para Intel)";
      };

      refreshRate = lib.mkOption {
        type = lib.types.int;
        default = 60;
        description = "Refresh rate del display principal";
      };
    };
  };

  config = lib.mkIf config.desktop.xmonad.enable {
    # ===== SERVICES: X.Org + XMonad + XFCE + Picom =====
    services = {
      xserver = {
        enable = true;

        xkb = {
          layout = "us,es";
          variant = "";
        };

        windowManager.xmonad = {
          enable = true;
          enableContribAndExtras = true;
          # Config file managed externally via stow: ~/.config/xmonad/xmonad.hs
          # (No usar builtins.readFile - es impuro y falla en flakes puros)
        };

        desktopManager.xfce.enable = true;

        # Display setup (específico por máquina)
        displayManager = {
          setupCommands = ''
            ${config.desktop.xmonad.displaySetupCommand}
            ${pkgs.xorg.xset}/bin/xset r rate 350 50
          '';
        };
      };

      displayManager = {
        defaultSession = "none+xmonad";
      };

      # Picom compositor
      picom = {
        enable = true;
        settings = {
          backend = config.desktop.xmonad.picomBackend;
          glx-no-stencil = true;
          glx-no-rebind-pixmap = true;
          unredir-if-possible = true;
          vsync = true;
          refresh-rate = config.desktop.xmonad.refreshRate;
        };
      };
    };

    # ===== SESSION VARIABLES: Forzar X11 =====
    environment.sessionVariables = {
      XDG_SESSION_TYPE = "x11";
      GDK_BACKEND = "x11";
      QT_QPA_PLATFORM = "xcb";
    };
  };
}
