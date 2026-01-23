# =============================================================================
# XMonad Module - Configuration managed by home-manager
# =============================================================================
# Este módulo gestiona xmonad.hs via home-manager (reemplaza stow).
#
# USO:
#   En machines/*.nix:
#     dotfiles.xmonad.enable = true;  # Default: enabled
#
# NOTA: Usamos namespace "dotfiles.xmonad" para no colisionar con
# programs.xmonad nativo de home-manager (que maneja el binario).
#
# MIGRACION:
#   Antes: stow -R xmonad (symlink ~/.config/xmonad -> dotfiles/xmonad/.config/xmonad)
#   Ahora: home.file copia xmonad.hs desde dotfiles/xmonad/.config/xmonad/xmonad.hs
#
# FILOSOFIA: Simple copy (no templating) - xmonad.hs es portable tras Fase 1 cleanup
# =============================================================================

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.dotfiles.xmonad;
in
{
  options.dotfiles.xmonad = {
    enable = lib.mkEnableOption "XMonad configuration" // {
      default = true; # Enabled on desktop by default
    };
  };

  config = lib.mkIf cfg.enable {
    # =========================================================================
    # XMONAD CONFIG FILE
    # =========================================================================
    # Copy xmonad.hs from dotfiles source to ~/.config/xmonad/xmonad.hs
    # This replaces the stow symlink approach
    home.file.".config/xmonad/xmonad.hs".source = ../../../xmonad/.config/xmonad/xmonad.hs;

    # =========================================================================
    # TRANSITION HELPER: Clean old stow symlinks
    # =========================================================================
    # This removes symlinks created by stow to avoid conflicts.
    # Only runs once during the transition from stow to home-manager.
    #
    # IMPORTANTE: Se ejecuta ANTES de checkLinkTargets para que home-manager
    # pueda crear el archivo real sin conflictos.
    home.activation.cleanXmonadStow = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      if [ -L "$HOME/.config/xmonad" ]; then
        echo "🧹 Cleaning old xmonad stow symlink: $HOME/.config/xmonad"
        rm -f "$HOME/.config/xmonad"
      fi

      # Create directory if it doesn't exist (home-manager will populate it)
      mkdir -p "$HOME/.config/xmonad"
    '';
  };
}
