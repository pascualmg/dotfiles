# =============================================================================
# MODULO: greetd + tuigreet - Login manager minimalista
# =============================================================================
# Reemplaza LightDM para soportar TANTO X11 (XMonad) como Wayland (Hyprland, niri)
#
# DEPENDENCIA: Este modulo requiere desktop.nix (o similar) para que existan
#              sesiones en xsessions/ y wayland-sessions/
#
# Por que greetd:
#   - LightDM solo lee xsessions/ (X11), ignora wayland-sessions/
#   - GDM tiene problemas con NVIDIA y XMonad puro
#   - greetd es simple, universal, y soporta ambos
#
# Controles tuigreet:
#   - Tab: siguiente campo
#   - F2: menu de sesiones
#   - F3: ciclar sesiones
#   - Enter: login
# =============================================================================

{ config, pkgs, lib, ... }:

{
  services.greetd = {
    enable = true;

    settings.default_session = {
      # tuigreet flags:
      #   --time: muestra la hora
      #   --asterisks: asteriscos en password
      #   --remember: recuerda usuario
      #   --remember-user-session: recuerda sesion
      #   --user: usuario por defecto (hardcoded - solo tenemos uno)
      #   --sessions: rutas a xsessions y wayland-sessions
      #   --xsession-wrapper: wrapper para sesiones X11 (startx con keeptty)
      command = ''
        ${pkgs.tuigreet}/bin/tuigreet \
          --time \
          --asterisks \
          --remember \
          --remember-user-session \
          --user passh \
          --sessions ${config.services.displayManager.sessionData.desktops}/share/xsessions:${config.services.displayManager.sessionData.desktops}/share/wayland-sessions \
          --xsession-wrapper "${pkgs.xorg.xinit}/bin/startx /run/current-system/sw/bin/env -- -keeptty"
      '';
      user = "greeter";
    };
  };
}
