# =============================================================================
# MODULO: XRDP - Remote Desktop Protocol
# =============================================================================
# Servidor RDP para acceso remoto al escritorio
#
# Estado: DESACTIVADO por defecto (usar Sunshine para streaming)
#
# Funcionalidad:
#   - Acceso remoto via protocolo RDP
#   - Compatible con clientes Windows Remote Desktop
#   - Sesion XMonad configurada
#
# Puertos:
#   - TCP 3389: RDP (solo si enable = true)
#
# Para activar:
#   - Cambiar enable = true en este modulo
#   - nixos-rebuild switch
#
# Comandos utiles:
#   - systemctl status xrdp: Estado del servicio
#   - Cliente: mstsc.exe (Windows) o remmina (Linux)
# =============================================================================

{ config, pkgs, lib, ... }:

{
  services.xrdp = {
    enable = false;  # DESACTIVADO - usar Sunshine para streaming
    openFirewall = true;
    defaultWindowManager = "${pkgs.writeShellScript "xmonad-session" ''
      export XDG_DATA_DIRS=/run/current-system/sw/share
      export PATH=/run/current-system/sw/bin:$PATH
      exec ${pkgs.xmonad-with-packages}/bin/xmonad
    ''}";
  };
}
