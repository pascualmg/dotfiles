# =============================================================================
# MODULO COMPARTIDO: cpupower-gui
# =============================================================================
# Herramienta GUI para gestionar frecuencias de CPU (scaling governors)
# Util en laptops para balance rendimiento/bateria, y en desktops para
# overclock/undervolt y monitoreo de frecuencias.
#
# Requiere: polkit, dbus, systemd service helper
# =============================================================================

{ config, pkgs, lib, ... }:

{
  # ===== PAQUETE =====
  environment.systemPackages = [ pkgs.cpupower-gui ];

  # ===== POLKIT - Permisos sin password para grupo wheel =====
  # Permite a usuarios del grupo wheel cambiar governors sin sudo
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id.indexOf("org.rnd2.cpupower_gui") == 0 &&
          subject.isInGroup("wheel")) {
        return polkit.Result.YES;
      }
    });
  '';

  # ===== D-BUS SERVICE =====
  # Registra el servicio D-Bus de cpupower-gui
  services.dbus.packages = [ pkgs.cpupower-gui ];

  # ===== SYSTEMD SERVICE - Helper D-Bus =====
  # El helper corre como root y expone interfaz D-Bus para la GUI
  systemd.services."dbus-org.rnd2.cpupower_gui.helper" = {
    description = "cpupower-gui D-Bus helper";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "dbus";
      BusName = "org.rnd2.cpupower_gui.helper";
      ExecStart = "${pkgs.cpupower-gui}/lib/cpupower-gui/cpupower-gui-helper";
      User = "root";
    };
  };
}
