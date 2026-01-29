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
#
# ┌─────────────────────────────────────────────────────────────────────────┐
# │              GUIA PARA NOOBS - ARCHIVO DE HOST                          │
# ├─────────────────────────────────────────────────────────────────────────┤
# │                                                                         │
# │  ARQUITECTURA CLONE-FIRST:                                              │
# │  ─────────────────────────                                              │
# │  En este repo, TODAS las maquinas comparten la misma base:              │
# │    modules/base/   <- Config comun (desktop, paquetes, usuarios)        │
# │    hardware/       <- Drivers especificos (nvidia, apple, audio)        │
# │    hosts/hostname/ <- SOLO overrides y servicios locales                │
# │                                                                         │
# │  Por eso este archivo es TAN PEQUENO. La mayor parte de la config       │
# │  viene de modules/base/ que se importa automaticamente en flake.nix     │
# │                                                                         │
# │  QUE PONER AQUI:                                                        │
# │  ───────────────                                                        │
# │  - Servicios que SOLO corren en esta maquina (VPN, servidores)          │
# │  - Overrides de comportamiento (suspend, power management)              │
# │  - stateVersion (version de NixOS con la que se instalo)                │
# │                                                                         │
# │  QUE NO PONER AQUI:                                                     │
# │  ──────────────────                                                     │
# │  - Paquetes generales -> van en modules/base/                           │
# │  - Config de usuario -> va en modules/home-manager/                     │
# │  - Drivers de hardware -> van en hardware/                              │
# │                                                                         │
# └─────────────────────────────────────────────────────────────────────────┘

# Argumentos del modulo
# config: configuracion actual del sistema (para leer valores)
# pkgs: todos los paquetes de nixpkgs
# lib: funciones auxiliares
# ...: otros argumentos que no usamos
{
  config,
  pkgs,
  lib,
  ...
}:

{
  # ---------------------------------------------------------------------------
  # IMPORTS - Modulos adicionales especificos de este host
  # ---------------------------------------------------------------------------
  # Importamos los modulos de VPN que creamos para este MacBook.
  # Estos modulos definen opciones (services.ivanti-vpn-vm, etc.)
  # que luego configuramos abajo.
  imports = [
    ../../modules/services/ivanti-vpn-vm.nix # VM Ubuntu para VPN Ivanti
    ../../modules/services/vocento-vpn-bridge.nix # Bridge networking para VPN
    ../../modules/services/syncthing.nix # Syncthing centralizado
  ];

  # ===========================================================================
  # VPN VOCENTO
  # ===========================================================================
  # Sistema de VPN usando una VM Ubuntu como gateway.
  # La VM tiene el cliente Ivanti VPN instalado.
  # El host (MacBook) enruta el trafico de redes Vocento via la VM.
  #
  # Arquitectura:
  #   MacBook -> br0 (bridge) -> VM Ubuntu -> VPN Ivanti -> Redes Vocento
  #
  # Uso diario:
  #   vpn-vm start      # Arranca VM y abre viewer
  #   (conectar VPN en la VM)
  #   vpn-bridge-status # Verificar que todo funciona

  # Configuracion de la VM
  services.ivanti-vpn-vm = {
    enable = true; # Activa el modulo
    networkMode = "bridge"; # Usa bridge br0 (no NAT de libvirt)
    vmAddress = "192.168.53.12"; # IP fija de la VM en el bridge
  };

  # Configuracion del bridge y rutas
  services.vocento-vpn-bridge = {
    enable = true;
    externalInterface = "wlp0s20f0u7u4"; # WiFi USB dongle (el wifi interno no funciona)
    # Valores por defecto (se pueden cambiar si es necesario):
    # hostAddress = "192.168.53.10";       # IP del host en br0
    # vmAddress = "192.168.53.12";         # IP de la VM
    # hostsFile = "/home/passh/src/vocento/autoenv/hosts_all.txt";  # Hosts adicionales
  };

  # ===========================================================================
  # POWER MANAGEMENT
  # ===========================================================================
  # El MacBook Pro 2016 tiene problemas para recuperarse del sleep en Linux.
  # El kernel carga pero la pantalla queda negra, forzando un hard reboot.
  # Solucion: deshabilitar completamente la suspension.

  # Configuracion de logind (lo que pasa al cerrar tapa, etc.)
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore"; # Cerrar tapa -> no hacer nada
    HandleLidSwitchExternalPower = "ignore"; # Cerrar tapa con cargador -> nada
    HandleLidSwitchDocked = "ignore"; # Cerrar tapa con dock -> nada
  };

  # Deshabilitar los targets de systemd relacionados con suspension
  # Esto evita que cualquier programa pueda suspender el sistema
  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
  };

  # ===========================================================================
  # SECURITY
  # ===========================================================================
  # Laptop de uso personal: no pedimos password para sudo
  # Esto es comodo pero MENOS SEGURO. En entornos corporativos o
  # multi-usuario se deberia cambiar a true.
  security.sudo.wheelNeedsPassword = false;

  # ===========================================================================
  # SYNCTHING (módulo centralizado en modules/services/syncthing.nix)
  # ===========================================================================
  dotfiles.syncthing.enable = true;
  # dotfiles.syncthing.guiPort = 8384;  # default

  # ===========================================================================
  # SSH
  # ===========================================================================
  # En macbook habilitamos password porque a veces nos conectamos desde
  # el movil u otros dispositivos donde no tenemos claves SSH configuradas.
  # El default en modules/core/services.nix es false (solo claves).
  services.openssh.settings.PasswordAuthentication = true;

  # ===========================================================================
  # STATE VERSION
  # ===========================================================================
  # IMPORTANTE: Este valor NO se debe cambiar despues de la instalacion.
  # Indica la version de NixOS con la que se instalo originalmente.
  # NixOS lo usa para mantener compatibilidad con datos antiguos.
  # Cambiar este valor puede romper la configuracion del sistema.
  system.stateVersion = "24.11";
}
