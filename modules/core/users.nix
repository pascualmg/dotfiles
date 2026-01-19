# =============================================================================
# MODULO COMPARTIDO: Usuarios
# =============================================================================
# Configuracion del usuario 'passh' compartida entre TODAS las maquinas
#
# CONSOLIDADO DE:
#   - nixos-aurin/etc/nixos/configuration.nix
#   - nixos-macbook/etc/nixos/configuration.nix
#   - nixos-vespino/etc/nixos/configuration.nix
#
# NOTA: Los grupos que no existen en una maquina simplemente se ignoran.
#       Por ejemplo, 'davfs2' solo existe en vespino si davfs2 esta instalado.
#
# IMPORTANTE: security.sudo.wheelNeedsPassword NO esta aqui porque es
#             politica de seguridad local (laptop vs workstation).
#             Cada maquina lo define en su configuration.nix.
# =============================================================================

{ config, pkgs, lib, ... }:

{
  # ===== USUARIO: passh =====
  users.users.passh = {
    isNormalUser = true;
    description = "Pascual Munoz Galian";
    shell = pkgs.fish;

    # Union de todos los grupos de todas las maquinas
    # Los grupos inexistentes se ignoran silenciosamente
    extraGroups = [
      # --- Grupos basicos (todas las maquinas) ---
      "wheel"          # sudo
      "networkmanager" # NetworkManager
      "audio"          # Audio
      "video"          # Video
      "input"          # Input devices (teclados, ratones)

      # --- Virtualizacion (aurin, vespino, macbook) ---
      "docker"         # Docker
      "libvirtd"       # Libvirt VMs
      "kvm"            # KVM hypervisor

      # --- Hardware (aurin, vespino) ---
      "storage"        # Acceso a storage
      "disk"           # Acceso a discos
      "plugdev"        # Dispositivos USB hotplug
      "render"         # GPU rendering (NVIDIA)

      # --- Audio (vespino) ---
      "pipewire"       # PipeWire audio (grupo opcional)

      # --- Otros (vespino) ---
      "davfs2"         # WebDAV filesystem
    ];

    # SSH keys para acceso remoto
    # Descomentar y agregar tu clave publica si usas SSH
    # openssh.authorizedKeys.keys = [
    #   "ssh-ed25519 AAAA..."
    # ];
  };

  # ===== NOTA SOBRE SUDO =====
  # security.sudo.wheelNeedsPassword se define en cada maquina:
  #   - aurin:   false (workstation, sudo sin password)
  #   - macbook: true  (laptop, seguridad)
  #   - vespino: true  (servidor, seguridad)
}
