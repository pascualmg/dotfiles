# =============================================================================
# MODULES/CORE/NSSWITCH.NIX - Configuración de Name Service Switch
# =============================================================================
# Orden de resolución de nombres para todas las máquinas.
#
# IMPORTANTE: Esta config es necesaria para la VPN Vocento.
# La línea "hosts: files mymachines myhostname dns" asegura que:
#   1. /etc/hosts se consulta primero (para hosts Vocento)
#   2. mymachines (contenedores systemd)
#   3. myhostname (hostname local)
#   4. DNS al final
#
# Esto permite que las entradas en /etc/hosts (importadas desde
# hosts_all.txt de Vocento) tengan prioridad sobre DNS público.
# =============================================================================

{ config, lib, ... }:

{
  # nsswitch.conf - orden de resolución de nombres
  environment.etc."nsswitch.conf" = {
    enable = true;
    text = ''
      passwd:    files systemd
      group:     files [success=merge] systemd
      shadow:    files
      sudoers:   files
      hosts:     files mymachines myhostname dns
      networks:  files
      ethers:    files
      services:  files
      protocols: files
      rpc:       files
    '';
  };
}
