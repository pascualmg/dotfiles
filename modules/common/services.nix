# =============================================================================
# MODULO COMPARTIDO: Servicios Comunes
# =============================================================================
# Servicios que AMBAS máquinas (aurin + macbook) necesitan
# =============================================================================

{ config, pkgs, lib, ... }:

{
  # ===== SSH =====
  # Valores por defecto - cada maquina puede sobreescribir
  services.openssh = {
    enable = lib.mkDefault true;
    settings = {
      PermitRootLogin = lib.mkDefault "no";
      PasswordAuthentication = lib.mkDefault false;  # Macbook lo pone a true
    };
  };

  # ===== AVAHI (mDNS) =====
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      domain = true;
      hinfo = true;
      userServices = true;
      workstation = true;
    };
  };

  # ===== BLUETOOTH =====
  # mkDefault permite que configs de maquina sobreescriban
  hardware.bluetooth.enable = lib.mkDefault true;
  services.blueman.enable = lib.mkDefault true;

  # ===== AUDIO (PipeWire) =====
  # Moderno reemplazo de PulseAudio + JACK
  # mkDefault para que aurin pueda añadir config FiiO K7
  security.rtkit.enable = lib.mkDefault true;
  services.pipewire = {
    enable = lib.mkDefault true;
    alsa.enable = lib.mkDefault true;
    alsa.support32Bit = lib.mkDefault true;
    pulse.enable = lib.mkDefault true;
    jack.enable = lib.mkDefault true;
  };

  # ===== DBUS =====
  services.dbus.enable = true;

  # ===== UDISKS2 (Auto-mount USBs) =====
  services.udisks2.enable = true;

  # ===== RATBAGD (Logitech gaming mice) =====
  # Permite gestionar ratones Logitech (DPI, batería, botones)
  services.ratbagd.enable = true;

  # ===== LOCATE (Database de archivos) =====
  services.locate = {
    enable = true;
    package = pkgs.plocate;  # Mas rapido que mlocate (usa io_uring)
    interval = "hourly";
  };

  # ===== THERMALD (Solo Intel, deshabilitado si no aplica) =====
  # services.thermald.enable = lib.mkDefault false;  # Habilitar en macbook
}
