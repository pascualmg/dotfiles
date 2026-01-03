# =============================================================================
# Home Manager Modules - Entry Point
# =============================================================================
# Este archivo actua como punto de entrada para los modulos de home-manager.
#
# USO EN FLAKE:
#   home-manager.nixosModules.default
#   # o importar directamente: ./modules/home-manager
#
# ESTRUCTURA:
#   modules/home-manager/
#   ├── default.nix    <- Este archivo (entry point)
#   ├── passh.nix      <- Configuracion del usuario passh
#   └── (futuros modulos por funcionalidad)
#
# ESTADO: Preparacion - El flake no usa esto todavia
# =============================================================================

{ config, pkgs, lib, ... }:

{
  # Por ahora, simplemente exportamos el modulo de passh
  # En el futuro, podemos agregar mas modulos y opciones aqui
  imports = [
    ./passh.nix
  ];
}
