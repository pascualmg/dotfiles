# =============================================================================
# MODULO COMPARTIDO: Servicios Comunes
# =============================================================================
# Servicios que AMBAS máquinas (aurin + macbook) necesitan
# =============================================================================

{ config, pkgs, lib, ... }:

{
  # ===== SSH =====
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
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
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # ===== AUDIO (PipeWire) =====
  # Moderno reemplazo de PulseAudio + JACK
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # ===== DBUS =====
  services.dbus.enable = true;

  # ===== UDISKS2 (Auto-mount USBs) =====
  services.udisks2.enable = true;

  # ===== LOCATE (Database de archivos) =====
  services.locate = {
    enable = true;
    locate = pkgs.mlocate;
    interval = "hourly";
  };

  # ===== THERMALD (Solo Intel, deshabilitado si no aplica) =====
  # services.thermald.enable = lib.mkDefault false;  # Habilitar en macbook
}
