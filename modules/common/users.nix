# =============================================================================
# MODULO COMPARTIDO: Usuarios
# =============================================================================
# Configuración del usuario 'passh' compartida entre máquinas
# =============================================================================

{ config, pkgs, lib, ... }:

{
  # ===== USUARIO: passh =====
  users.users.passh = {
    isNormalUser = true;
    description = "Pascual Munoz Galian";
    shell = pkgs.fish;

    extraGroups = [
      "wheel"          # sudo
      "networkmanager" # NetworkManager
      "audio"          # Audio
      "video"          # Video
      "input"          # Input devices
      "docker"         # Docker (si está habilitado)
      "libvirtd"       # Libvirt (si está habilitado)
      "kvm"            # KVM (si está habilitado)
    ];

    # SSH keys (añadir si tienes)
    # openssh.authorizedKeys.keys = [
    #   "ssh-ed25519 AAAA..."
    # ];
  };

  # ===== SUDO SIN PASSWORD =====
  security.sudo.wheelNeedsPassword = false;
}
