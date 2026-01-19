# =============================================================================
# MODULO COMPARTIDO: Nix Settings
# =============================================================================
# Configuracion de Nix compartida por TODAS las maquinas
#
# CONSOLIDADO DE: aurin, macbook, vespino
#
# Incluye:
#   - Flakes y nix-command habilitados
#   - Auto-optimise-store
#   - GC semanal (default, configurable por maquina)
#
# Opciones configurables:
#   - common.nix.maxJobs: numero de jobs paralelos (default: auto)
#   - common.nix.gcDays: dias para mantener generaciones (default: 14)
# =============================================================================

{ config, pkgs, lib, ... }:

{
  options = {
    common.nix = {
      maxJobs = lib.mkOption {
        type = lib.types.either lib.types.int (lib.types.enum [ "auto" ]);
        default = "auto";
        description = ''
          Numero de jobs paralelos para builds.
          - auto: detecta automaticamente
          - numero: fija a ese valor (ej: 72 para aurin)
        '';
      };

      gcDays = lib.mkOption {
        type = lib.types.int;
        default = 14;
        description = "Dias para mantener generaciones antes de GC";
      };
    };
  };

  config = {
    nix = {
      settings = {
        auto-optimise-store = true;
        experimental-features = [ "nix-command" "flakes" ];
        max-jobs = config.common.nix.maxJobs;
      };
      gc = {
        automatic = lib.mkDefault true;
        dates = lib.mkDefault "weekly";
        options = "--delete-older-than ${toString config.common.nix.gcDays}d";
      };
    };
  };
}
