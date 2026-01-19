# =============================================================================
# MODULES/BASE - Todo lo compartido por TODAS las maquinas
# =============================================================================
# Filosofia: Todas las maquinas son CLONES IDENTICOS.
# Este modulo importa TODO lo que es comun.
#
# Las unicas diferencias entre maquinas son:
#   1. hostname (se pasa como parametro)
#   2. hardware-configuration.nix (auto-generado)
#   3. Modulos en hardware/ (nvidia, apple, etc.)
#   4. Modulos en extra/ (vocento-vpn, etc.) - OPT-IN
# =============================================================================

{ config, pkgs, lib, ... }:

{
  imports = [
    # ===== SISTEMA BASE =====
    ../common/boot.nix
    ../common/locale.nix
    ../common/console.nix
    ../common/nix-settings.nix
    ../common/nix-ld.nix
    ../common/security.nix
    ../common/users.nix
    ../common/packages.nix
    ../common/services.nix
    ../common/cpupower-gui.nix

    # ===== DESKTOP UNIFICADO =====
    # GDM + GNOME + XMonad + Hyprland + Niri - TODO disponible en TODAS
    ./desktop.nix

    # ===== WAYLAND COMPOSITORS =====
    ../desktop/hyprland.nix
    ../desktop/niri.nix

    # ===== VIRTUALIZACION =====
    # Docker + libvirt/QEMU para TODAS las maquinas
    ./virtualization.nix

    # ===== STREAMING =====
    # Sunshine server (NVENC si NVIDIA, software si no)
    ./sunshine.nix
  ];
}
