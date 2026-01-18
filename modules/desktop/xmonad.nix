# =============================================================================
# MODULO OBSOLETO - XMonad ahora esta en modules/base/desktop.nix
# =============================================================================
# Este modulo se mantiene vacio para compatibilidad con imports existentes.
# La configuracion real de XMonad esta en modules/base/desktop.nix
#
# MIGRACION:
#   - XMonad, xkb, libinput -> modules/base/desktop.nix
#   - picom -> home-manager (se lanza desde xmonad.hs)
#   - displaySetupCommand -> hardware/*.nix de cada maquina
#   - Variables X11 -> ELIMINADAS (cada sesion decide)
#
# TODO: Eliminar este archivo cuando todas las maquinas usen la nueva estructura
# =============================================================================

{ config, pkgs, lib, ... }:

{
  # Las opciones se mantienen para no romper imports existentes
  # pero ya no hacen nada - la config real esta en base/desktop.nix
  options.desktop.xmonad = {
    enable = lib.mkEnableOption "XMonad (OBSOLETO - usar base/desktop.nix)";
    displaySetupCommand = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "OBSOLETO - mover a hardware/*.nix";
    };
    picomBackend = lib.mkOption {
      type = lib.types.str;
      default = "glx";
      description = "OBSOLETO - picom esta en home-manager";
    };
    refreshRate = lib.mkOption {
      type = lib.types.int;
      default = 60;
      description = "OBSOLETO - mover a hardware/*.nix";
    };
  };

  # NO hace nada - solo existe para compatibilidad
  config = {};
}
