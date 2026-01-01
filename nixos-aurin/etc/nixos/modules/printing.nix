# =============================================================================
# MODULO: Printing - Impresora HP M148dw
# =============================================================================
# Configuracion de impresion con HP LaserJet Pro M148dw
#
# Hardware:
#   - HP LaserJet Pro MFP M148dw (WiFi + USB)
#   - Conexion: WiFi via autodescubrimiento Avahi/mDNS
#
# Servicios:
#   - CUPS: Sistema de impresion
#   - HPLIP: Drivers HP
#   - Avahi: Autodescubrimiento de impresoras en red
#
# Puertos:
#   - TCP 631: CUPS Web UI
#   - UDP 5353: mDNS/Avahi
#
# Comandos utiles:
#   - lpstat -p: Ver impresoras disponibles
#   - hp-setup: Configurar impresora HP
#   - http://localhost:631: CUPS Web UI
# =============================================================================

{ config, pkgs, lib, ... }:

{
  # ===== SERVICES: CUPS + Avahi =====
  services = {
    # Sistema de impresion
    printing = {
      enable = true;
      drivers = [ pkgs.hplip ];
    };

    # Autodescubrimiento WiFi (ESENCIAL para M148dw)
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
  };

  # ===== FIREWALL: Puerto CUPS =====
  networking.firewall.allowedTCPPorts = [ 631 ];
  networking.firewall.allowedUDPPorts = [ 5353 ];
}
