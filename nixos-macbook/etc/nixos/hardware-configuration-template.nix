# =============================================================================
# HARDWARE CONFIGURATION TEMPLATE - MacBook Pro 13,2
# =============================================================================
# INSTRUCCIONES:
#
# 1. Durante la instalacion, PRIMERO ejecutar:
#      sudo nixos-generate-config --root /mnt
#
# 2. Ese comando genera /mnt/etc/nixos/hardware-configuration.nix con
#    los UUIDs REALES de tus particiones.
#
# 3. MODIFICAR el archivo generado para agregar:
#    - Opciones de montaje optimizadas (noatime, discard)
#    - Modulos initrd adicionales si necesario
#
# Este template muestra la estructura para USB 128GB con:
#   - Particion 1: EFI (512MB, FAT32)
#   - Particion 2: root (115GB aprox, ext4)
#   - Particion 3: swap (8-16GB, linux-swap)
#
# PARTICIONADO USB 128GB:
#   parted /dev/sdX -- mklabel gpt
#   parted /dev/sdX -- mkpart ESP fat32 1MiB 512MiB
#   parted /dev/sdX -- set 1 esp on
#   parted /dev/sdX -- mkpart primary ext4 512MiB -16GiB
#   parted /dev/sdX -- mkpart primary linux-swap -16GiB 100%
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
  # Los modulos SPI para teclado/trackpad estan en modules/apple-hardware.nix
  # Estos son los modulos base para arranque

  boot.initrd.availableKernelModules = [
    "xhci_pci"        # USB 3.0 / Thunderbolt 3
    "ahci"            # SATA (para USBs que usan SATA)
    "nvme"            # NVMe SSD
    "usbhid"          # USB Human Interface Devices
    "usb_storage"     # USB Mass Storage (CRITICO para USB)
    "uas"             # USB Attached SCSI (mejor rendimiento USB 3.0)
    "sd_mod"          # SCSI disk
    "thunderbolt"     # Thunderbolt 3 controller
  ];

  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # ===========================================================================
  # FILE SYSTEMS - REEMPLAZAR UUIDs
  # ===========================================================================
  # Obtener UUIDs con: blkid /dev/sdX1 /dev/sdX2 /dev/sdX3

  # Root filesystem (USB 128GB)
  fileSystems."/" = {
    # REEMPLAZAR con UUID real: blkid /dev/sdX2
    device = "/dev/disk/by-label/nixos";  # O usar by-uuid
    fsType = "ext4";
    options = [
      "noatime"           # No actualizar access time (reduce writes)
      "nodiratime"        # No actualizar directory access time
      "discard"           # TRIM (si el USB lo soporta)
      "errors=remount-ro" # Seguridad
      "commit=120"        # Sync cada 2 min (mejor para USB, reduce writes)
    ];
  };

  # EFI System Partition
  fileSystems."/boot" = {
    # REEMPLAZAR con UUID real: blkid /dev/sdX1
    device = "/dev/disk/by-label/BOOT";  # O usar by-uuid
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
      "noatime"
    ];
  };

  # ===========================================================================
  # SWAP
  # ===========================================================================
  # 8-16GB para USB 128GB
  # Hibernate requiere swap >= RAM

  swapDevices = [
    {
      device = "/dev/disk/by-label/swap";  # O usar by-uuid
      # Para USB, considerar priority bajo si hay swap en otro disco
      priority = 10;
    }
  ];

  # Alternativa: Sin swap (si USB es lento)
  # swapDevices = [ ];

  # ===========================================================================
  # NETWORKING
  # ===========================================================================
  networking.useDHCP = lib.mkDefault true;

  # ===========================================================================
  # PLATFORM
  # ===========================================================================
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # Intel CPU microcode
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
