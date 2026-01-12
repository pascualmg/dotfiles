# =============================================================================
# MODULO: XMonad + X11
# =============================================================================
# Window manager XMonad con X.Org y compositor Picom
#
# Componentes:
#   - XMonad: Tiling window manager (Haskell)
#   - XFCE: Desktop environment (fallback)
#   - Picom: Compositor con backend GLX
#   - Display setup: 5120x1440@120Hz via RTX 5080
#
# Configuracion XMonad:
#   - Lee config de ~/.config/xmonad/xmonad.hs
#   - ContribAndExtras habilitado
#
# Keyboard:
#   - Layout: US + ES
#   - Key repeat: 350ms delay, 50 rate
#
# Compositor Picom:
#   - Backend: GLX (NVIDIA)
#   - VSync: Enabled
#   - Refresh: 120Hz
#
# Sesion por defecto: XMonad (sin desktop environment)
# =============================================================================

{ config, pkgs, lib, ... }:

{
  # ===== SERVICES: X.Org + XMonad + XFCE + Picom =====
  services = {
    # ===== LIBINPUT: Raw input para ratones gaming =====
    # Filosofía HHKB: el hardware manda, no el software
    # Perfil flat = movimiento 1:1 con el DPI del ratón
    libinput = {
      enable = true;
      mouse = {
        accelProfile = "flat";  # Raw input, sin aceleración del sistema
        accelSpeed = "0";       # Velocidad base (respeta DPI del ratón)
      };
    };

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

      # RTX 5080 display setup
      displayManager = {
        setupCommands = ''
          ${pkgs.xorg.xrandr}/bin/xrandr --output DP-4 --mode 5120x1440 --rate 120 --primary --dpi 96
          ${pkgs.xorg.xset}/bin/xset r rate 350 50
        '';
      };
    };

    displayManager = {
      defaultSession = "none+xmonad";
    };

    # Picom compositor optimizado para RTX 5080
    picom = {
      enable = true;
      settings = {
        backend = "glx";
        glx-no-stencil = true;
        glx-no-rebind-pixmap = true;
        unredir-if-possible = true;
        vsync = true;
        refresh-rate = 120;
      };
    };
  };

  # ===== SESSION VARIABLES: Forzar X11 =====
  environment.sessionVariables = {
    XDG_SESSION_TYPE = "x11";
    GDK_BACKEND = "x11";
    QT_QPA_PLATFORM = "xcb";
  };
}
