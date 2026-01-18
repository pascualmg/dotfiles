# =============================================================================
# HOSTS/MACBOOK - Configuracion minima especifica de macbook
# =============================================================================
# Este archivo contiene SOLO lo que es especifico de macbook que NO es hardware.
#
# Hardware: hardware/apple/macbook-pro-13-2.nix
# Base: modules/base/ (compartido con todas las maquinas)
#
# Aqui solo van politicas/comportamientos especificos de este host:
#   - Suspension deshabilitada (MacBook no se recupera bien)
#   - stateVersion
# =============================================================================

{ config, pkgs, lib, ... }:

{
  # ===== POWER MANAGEMENT =====
  # Deshabilitar suspension - el MacBook no se recupera bien de sleep
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
  };

  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
  };

  # ===== SECURITY =====
  # Laptop movil: pedir password para sudo
  security.sudo.wheelNeedsPassword = true;

  # ===== STATE VERSION =====
  system.stateVersion = "24.11";
}
