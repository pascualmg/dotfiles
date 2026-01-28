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
    ../core/boot.nix
    ../core/locale.nix
    ../core/console.nix
    ../core/nix-settings.nix
    ../core/nix-ld.nix
    ../core/security.nix
    ../core/users.nix
    ../core/packages.nix
    ../core/services.nix
    ../core/cpupower-gui.nix
    ../core/firewall.nix

    # ===== DESKTOP UNIFICADO =====
    # SDDM + GNOME + XMonad + Hyprland + Niri - TODO disponible en TODAS
    ./desktop.nix
    ./sddm.nix  # Login manager (soporta X11 y Wayland)

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
