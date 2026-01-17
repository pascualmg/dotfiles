# =============================================================================
# MODULO COMPARTIDO: Configuracion de Consola (TTY)
# =============================================================================
# Configuracion base de consola compartida por TODAS las maquinas
#
# CONSOLIDADO DE: aurin, macbook, vespino
#
# Opciones configurables:
#   - console.fontSize: "normal" | "hidpi" (default: "normal")
#     - normal: ter-p20n (aurin, vespino)
#     - hidpi: ter-p32n (macbook Retina)
#
# USO:
#   # En configuration.nix de macbook:
#   common.console.fontSize = "hidpi";
# =============================================================================

{ config, pkgs, lib, ... }:

{
  options = {
    common.console.fontSize = lib.mkOption {
      type = lib.types.enum [ "normal" "hidpi" ];
      default = "normal";
      description = ''
        Tamano de fuente para la consola TTY.
        - normal: ter-p20n (para monitores normales)
        - hidpi: ter-p32n (para pantallas Retina/HiDPI)
      '';
    };
  };

  config = {
    console = {
      earlySetup = true;
      font = if config.common.console.fontSize == "hidpi"
             then "ter-p32n"
             else "ter-p20n";
      packages = with pkgs; [
        terminus_font
        kbd
        powerline-fonts
      ];
      keyMap = "us";
      useXkbConfig = lib.mkDefault false;
    };
  };
}
