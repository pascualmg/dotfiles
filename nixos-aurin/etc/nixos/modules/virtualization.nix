# =============================================================================
# MODULO: Virtualization - Docker + libvirt/QEMU
# =============================================================================
# Configuracion completa de virtualizacion para desarrollo y VMs
#
# Componentes:
#   - Docker: Contenedores para microservicios
#   - libvirt/QEMU: Maquinas virtuales completas
#   - SPICE: Mejor integracion VM
#   - OVMF: UEFI para VMs
#
# Caracteristicas:
#   - IOMMU habilitado para passthrough
#   - Bridge br0 configurado para VMs
#   - Auto-prune semanal de Docker
#
# Grupos de usuario requeridos:
#   - docker: Para usar Docker sin sudo
#   - libvirtd: Para gestionar VMs
#   - kvm: Para aceleracion KVM
#
# Comandos utiles:
#   - docker ps: Ver contenedores activos
#   - virsh list --all: Ver VMs
#   - virt-manager: GUI para VMs
# =============================================================================

{ config, pkgs, lib, ... }:

{
  # ===== BOOT: IOMMU para passthrough =====
  boot = {
    kernelParams = [
      "intel_iommu=on"
      "amd_iommu=on"
      "iommu=pt"
    ];

    kernelModules = [
      "kvm-amd"
      "kvm-intel"
      "vfio"
      "vfio_iommu_type1"
      "vfio_pci"
    ];
  };

  # ===== SYSCTL: IP Forwarding para VMs =====
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv4.conf.all.forwarding" = 1;
    "net.ipv4.conf.default.forwarding" = 1;
  };

  # ===== ENVIRONMENT: Variables libvirt =====
  environment.sessionVariables = {
    LIBVIRT_DEFAULT_URI = "qemu:///system";
  };

  # ===== SERVICES: SPICE + QEMU Guest =====
  services = {
    spice-vdagentd.enable = true;  # Mejor integracion SPICE
    qemuGuest.enable = true;       # Soporte guest
  };

  # ===== VIRTUALIZATION: Docker + libvirt =====
  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        # ovmf.enable = true;  # REMOVIDO: OVMF ahora disponible por defecto
        runAsRoot = true;
      };
      onBoot = "ignore";
      onShutdown = "shutdown";
      allowedBridges = [ "br0" "virbr0" ];
    };

    docker = {
      enable = true;
      autoPrune = {
        enable = true;
        dates = "weekly";
      };
    };
  };

  # ===== PAQUETES: Herramientas virtualizacion =====
  environment.systemPackages = with pkgs; [
    # VM Management
    virt-manager
    virt-viewer
    qemu
    OVMF

    # SPICE
    spice-gtk
    spice-protocol

    # Windows VMs
    virtio-win  # Antes: win-virtio (renombrado)
    swtpm

    # Networking
    bridge-utils
    dnsmasq
    iptables
  ];
}
