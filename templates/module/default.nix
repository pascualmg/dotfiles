# Template para modulo NixOS
# Uso: nix flake init -t ~/dotfiles#module
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.NOMBRE;
in {
  options.services.NOMBRE = {
    enable = mkEnableOption "Descripcion del servicio";

    # Agregar mas opciones aqui
    # setting = mkOption {
    #   type = types.str;
    #   default = "valor";
    #   description = "Descripcion de la opcion";
    # };
  };

  config = mkIf cfg.enable {
    # Configuracion cuando el servicio esta habilitado
    # environment.systemPackages = [ pkgs.algo ];
  };
}
