# =============================================================================
# MODULO COMPARTIDO: Security
# =============================================================================
# Configuracion de seguridad compartida por TODAS las maquinas
#
# CONSOLIDADO DE: aurin, macbook, vespino
#
# NOTA: security.sudo.wheelNeedsPassword NO esta aqui porque es
#       politica de seguridad local (laptop vs workstation).
#       Cada maquina lo define en su configuration.nix:
#         - aurin:   false (workstation, sudo sin password)
#         - macbook: true  (laptop, seguridad)
#         - vespino: true  (servidor, seguridad)
# =============================================================================

{ config, pkgs, lib, ... }:

{
  security = {
    # Polkit: necesario para muchas herramientas GUI que requieren root
    # (NetworkManager, cpupower-gui, systemd services, etc.)
    polkit.enable = lib.mkDefault true;

    # RTKit: prioridad realtime para audio (PipeWire lo necesita)
    rtkit.enable = lib.mkDefault true;
  };
}
