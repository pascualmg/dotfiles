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
#   - VPN Vocento via VM Ubuntu
#   - stateVersion
# =============================================================================

{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ../../modules/services/ivanti-vpn-vm.nix       # VM Ubuntu para VPN Ivanti
    ../../modules/services/vocento-vpn-bridge.nix  # Bridge networking para VPN
  ];

  # ===== VPN VOCENTO =====
  # VM con cliente Ivanti + Bridge para enrutar trafico corporativo
  services.ivanti-vpn-vm = {
    enable = true;
    networkMode = "bridge";        # Usar bridge br0 (no NAT)
    vmAddress = "192.168.53.12";   # IP fija de la VM
  };

  services.vocento-vpn-bridge = {
    enable = true;
    externalInterface = "wlp0s20f0u7u4";  # WiFi USB dongle
    # hostAddress = "192.168.53.10";      # default
    # vmAddress = "192.168.53.12";        # default
    # hostsFile = "/home/passh/src/vocento/autoenv/hosts_all.txt";  # si lo tienes
  };

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
  security.sudo.wheelNeedsPassword = false;

  # ===== STATE VERSION =====
  system.stateVersion = "24.11";
}
