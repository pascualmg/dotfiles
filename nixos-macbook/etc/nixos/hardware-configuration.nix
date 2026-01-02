# =============================================================================
# HARDWARE CONFIGURATION - MacBook Pro 13,2
# =============================================================================
# IMPORTANTE: Este archivo es un TEMPLATE/PLACEHOLDER
#
# Durante la instalacion real, REEMPLAZAR este archivo con el generado por:
#   sudo nixos-generate-config --root /mnt
#
# El comando detectara automaticamente:
#   - UUIDs de tus particiones
#   - Modulos kernel necesarios para tu hardware especifico
#   - Configuracion de red detectada
#
# Este template muestra la estructura esperada para un SSD externo TB3
# con particionado tipico: EFI + root ext4 + swap
#
# Particionado recomendado para SSD 4TB:
#   - /dev/sdX1: 512MB  - EFI System Partition (FAT32)
#   - /dev/sdX2: ~3.9TB - root (ext4)
#   - /dev/sdX3: 32GB   - swap (opcional, para hibernate)
#
# Comandos particionado (ejemplo con parted):
#   parted /dev/sdX -- mklabel gpt
#   parted /dev/sdX -- mkpart ESP fat32 1MiB 512MiB
#   parted /dev/sdX -- set 1 esp on
#   parted /dev/sdX -- mkpart primary ext4 512MiB -32GiB
#   parted /dev/sdX -- mkpart primary linux-swap -32GiB 100%
#   mkfs.fat -F32 -n BOOT /dev/sdX1
#   mkfs.ext4 -L nixos /dev/sdX2
#   mkswap -L swap /dev/sdX3
# =============================================================================

{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # ===========================================================================
  # KERNEL MODULES
  # ===========================================================================
  # Estos seran detectados automaticamente por nixos-generate-config
  # Los modulos SPI para teclado/trackpad estan en modules/apple-hardware.nix

  boot.initrd.availableKernelModules = [
    "xhci_pci"        # USB 3.0 / Thunderbolt 3
    "nvme"            # NVMe SSD (si el SSD TB3 es NVMe)
    "ahci"            # SATA (alternativa)
    "usbhid"          # USB Human Interface Devices
    "usb_storage"     # USB Mass Storage
    "sd_mod"          # SCSI disk
    "thunderbolt"     # Thunderbolt 3 controller
  ];

  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # ===========================================================================
  # FILE SYSTEMS
  # ===========================================================================
  # REEMPLAZAR los UUIDs con los reales de tu instalacion
  # Obtener UUIDs: blkid /dev/sdX1 /dev/sdX2

  # Root filesystem (SSD externo TB3)
  # Optimizado para SSD: noatime, discard (TRIM)
  fileSystems."/" = {
    # REEMPLAZAR con UUID real: blkid /dev/sdX2
    device = "/dev/disk/by-uuid/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX";
    fsType = "ext4";
    options = [
      "noatime"           # No actualizar access time (reduce writes)
      "nodiratime"        # No actualizar directory access time
      "discard"           # TRIM continuo para SSD
      "errors=remount-ro" # Seguridad: remount read-only on errors
      "commit=60"         # Sync cada 60s (balance seguridad/rendimiento)
    ];
  };

  # EFI System Partition
  fileSystems."/boot" = {
    # REEMPLAZAR con UUID real: blkid /dev/sdX1
    device = "/dev/disk/by-uuid/XXXX-XXXX";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
      "noatime"
      "discard"
    ];
  };

  # ===========================================================================
  # SWAP
  # ===========================================================================
  # Opcional pero recomendado para hibernate
  # REEMPLAZAR con UUID real: blkid /dev/sdX3

  swapDevices = [
    {
      # REEMPLAZAR con UUID real
      device = "/dev/disk/by-uuid/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX";
      # Alternativa por label: device = "/dev/disk/by-label/swap";
      options = [ "discard" ];  # TRIM para swap en SSD
    }
  ];

  # Alternativa: Swap file (si no quieres particion dedicada)
  # swapDevices = [{
  #   device = "/swapfile";
  #   size = 32 * 1024;  # 32GB en MB
  # }];

  # ===========================================================================
  # NETWORKING
  # ===========================================================================
  # Detectado automaticamente por nixos-generate-config

  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp3s0.useDHCP = lib.mkDefault true;

  # ===========================================================================
  # PLATFORM
  # ===========================================================================

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # Intel CPU microcode (tambien en modules/apple-hardware.nix via nixos-hardware)
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
