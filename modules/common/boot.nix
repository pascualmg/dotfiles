# =============================================================================
# MODULO COMPARTIDO: Boot Loader
# =============================================================================
# Configuracion base de bootloader compartida por TODAS las maquinas
#
# CONSOLIDADO DE: aurin, macbook, vespino
#
# Todos usan systemd-boot (EFI).
# Parametros de kernel especificos van en cada maquina.
# =============================================================================

{ config, pkgs, lib, ... }:

{
  boot.loader = {
    systemd-boot.enable = lib.mkDefault true;
    efi.canTouchEfiVariables = lib.mkDefault true;
  };
}
