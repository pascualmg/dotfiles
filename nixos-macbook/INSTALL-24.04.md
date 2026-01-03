# NixOS 24.04 en MacBook Pro 13,2 (2016) - Guia de Instalacion

## Resumen

Esta guia cubre la instalacion de NixOS 24.04 en un MacBook Pro 13,2 (Late 2016, 13" con Touch Bar) usando un USB externo de 128GB.

**IMPORTANTE:** NixOS 24.05 NO arranca en este hardware. Usar ISO de 24.04.

## Hardware Target

| Componente | Modelo | Driver |
|------------|--------|--------|
| CPU | Intel Core i5/i7-6xxx (Skylake) | intel_pstate |
| GPU | Intel Iris Graphics 550 | i915/modesetting |
| Display | Retina 2560x1600 (227 DPI) | HiDPI 2x scaling |
| Teclado | Apple SPI Keyboard | applespi |
| Trackpad | Force Touch (SPI) | applespi + libinput |
| Touch Bar | OLED T1 chip | tiny-dfr |
| WiFi | Broadcom BCM43602 | broadcom_sta (wl) |
| Storage | USB 128GB externo | usb_storage + uas |

## Prerequisitos

- USB NixOS 24.04 (ISO minimal o graphical)
- USB 128GB para instalacion (target)
- USB WiFi o Ethernet (Broadcom interno NO conecta en Live)
- Adaptador USB-C a USB-A (para los USBs)

## Paso 0: Descargar y Crear USB de Instalacion

```bash
# En otra maquina Linux/Mac, descargar ISO NixOS 24.04
# NOTA: Buscar "nixos-24.04" o usar la minimal
wget https://channels.nixos.org/nixos-24.05/latest-nixos-minimal-x86_64-linux.iso

# Escribir a USB (CUIDADO: /dev/sdX es el USB de instalacion, NO el de 128GB)
sudo dd if=latest-nixos-minimal-x86_64-linux.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

## Paso 1: Boot desde USB de Instalacion

1. Conectar ambos USBs al MacBook:
   - USB con ISO NixOS (boot)
   - USB 128GB vacio (target)
   - USB WiFi/Ethernet (red)

2. Apagar MacBook completamente

3. Encender manteniendo **Option/Alt** presionado

4. Seleccionar "EFI Boot" (el USB de instalacion)

5. En GRUB, seleccionar "NixOS Installer"

**NOTA:** El teclado interno FUNCIONA en Live USB 24.04 (ya verificado).

## Paso 2: Conectar a Internet

El WiFi Broadcom interno detecta redes pero NO conecta. Usar alternativa:

```bash
# Opcion A: USB Ethernet
# Conectar adaptador y verificar
ip a
# Deberia mostrar ethX o enpXsY con IP

# Opcion B: USB WiFi con drivers libres
nmcli device wifi list
nmcli device wifi connect "SSID" password "PASSWORD"

# Opcion C: USB Tethering desde movil
# Conectar movil con "Compartir Internet USB"
ip a  # Buscar usb0 o similar

# Verificar conexion
ping -c 3 google.com
```

## Paso 3: Identificar el USB 128GB Target

```bash
# Listar todos los discos
lsblk

# Ejemplo de output:
# NAME   SIZE TYPE
# sda    29G  disk   <- USB instalacion (ISO)
# sdb   119G  disk   <- USB 128GB (TARGET)
# nvme0 256G  disk   <- SSD interno Mac (NO TOCAR)

# IMPORTANTE: Confirmar cual es el USB 128GB antes de continuar
# Usar el tamano (119G = 128GB) para identificar

# Guardar el device en variable
TARGET=/dev/sdb   # AJUSTAR segun tu caso
```

## Paso 4: Particionar USB 128GB

```bash
# ADVERTENCIA: Esto borra TODO en el USB target

# Crear tabla GPT
sudo parted $TARGET -- mklabel gpt

# Particion 1: EFI (512MB)
sudo parted $TARGET -- mkpart ESP fat32 1MiB 512MiB
sudo parted $TARGET -- set 1 esp on

# Particion 2: root (resto menos 16GB para swap)
sudo parted $TARGET -- mkpart primary ext4 512MiB -16GiB

# Particion 3: swap (16GB)
sudo parted $TARGET -- mkpart primary linux-swap -16GiB 100%

# Verificar particiones
sudo parted $TARGET print

# Formatear
sudo mkfs.fat -F32 -n BOOT ${TARGET}1
sudo mkfs.ext4 -L nixos ${TARGET}2
sudo mkswap -L swap ${TARGET}3

# Verificar resultado
lsblk -f $TARGET
```

**Ejemplo de resultado:**
```
NAME   FSTYPE FSVER LABEL  UUID
sdb
├─sdb1 vfat   FAT32 BOOT   XXXX-XXXX
├─sdb2 ext4   1.0   nixos  xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
└─sdb3 swap   1     swap   xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

## Paso 5: Montar Particiones

```bash
# Montar root
sudo mount /dev/disk/by-label/nixos /mnt

# Crear y montar boot
sudo mkdir -p /mnt/boot
sudo mount /dev/disk/by-label/BOOT /mnt/boot

# Activar swap
sudo swapon /dev/disk/by-label/swap

# Verificar montaje
df -h /mnt /mnt/boot
swapon --show
```

## Paso 6: Generar Configuracion Base

```bash
# Generar hardware-configuration.nix automatico
sudo nixos-generate-config --root /mnt

# Ver lo generado (contiene UUIDs reales)
cat /mnt/etc/nixos/hardware-configuration.nix
```

## Paso 7: Obtener Archivos de Configuracion

**Opcion A: Clonar repositorio (si hay red)**
```bash
# Instalar git temporalmente
nix-shell -p git

# Clonar dotfiles
sudo mkdir -p /mnt/home/passh
sudo git clone https://github.com/TU_USUARIO/dotfiles.git /mnt/home/passh/dotfiles

# Copiar configuracion
sudo cp /mnt/home/passh/dotfiles/nixos-macbook/etc/nixos/configuration-24.04.nix \
        /mnt/etc/nixos/configuration.nix

# Copiar modulo hardware
sudo mkdir -p /mnt/etc/nixos/modules
sudo cp /mnt/home/passh/dotfiles/nixos-macbook/etc/nixos/modules/apple-hardware-24.04.nix \
        /mnt/etc/nixos/modules/apple-hardware.nix
```

**Opcion B: Copiar manualmente (si no hay red)**
```bash
# Si tienes los archivos en otro USB:
sudo mkdir -p /mnt/etc/nixos/modules

# Copiar configuration-24.04.nix como configuration.nix
sudo cp /media/usb/configuration-24.04.nix /mnt/etc/nixos/configuration.nix

# Copiar modulo
sudo cp /media/usb/apple-hardware-24.04.nix /mnt/etc/nixos/modules/apple-hardware.nix
```

## Paso 8: Editar Configuracion (IMPORTANTE)

```bash
# Editar configuration.nix
sudo nano /mnt/etc/nixos/configuration.nix

# CAMBIOS REQUERIDOS:
# 1. Verificar que importa ./modules/apple-hardware.nix (no apple-hardware-24.04.nix)
# 2. Descomentar initialPassword si quieres password por defecto
# 3. Ajustar timezone si no es Europe/Madrid

# OPCIONAL: Descomentar password inicial para primer boot
# Buscar la linea:
#   # initialPassword = "nixos";
# Y descomentar:
#   initialPassword = "nixos";
```

```bash
# Verificar hardware-configuration.nix generado
cat /mnt/etc/nixos/hardware-configuration.nix

# Debe contener los UUIDs correctos de tus particiones
# Si usas labels (BOOT, nixos, swap), verificar que coincidan
```

## Paso 9: Instalar NixOS

```bash
# Instalar (tarda 15-30 minutos dependiendo de conexion)
sudo nixos-install

# Durante la instalacion:
# - Se descargan todos los paquetes
# - Al final pregunta por password de root
# - Establecer un password temporal (cambiar despues)

# Si falla por red, verificar conexion:
ping -c 1 cache.nixos.org
```

## Paso 10: Primer Boot

```bash
# Desmontar
sudo umount /mnt/boot
sudo umount /mnt
sudo swapoff /dev/disk/by-label/swap

# Reiniciar
sudo reboot
```

**En el reinicio:**
1. Mantener **Option/Alt** presionado
2. Seleccionar "EFI Boot" (ahora sera el USB 128GB)
3. Deberia arrancar NixOS directamente

## Paso 11: Post-Instalacion

```bash
# Login como root (con el password establecido durante nixos-install)

# Establecer password para usuario passh
passwd passh

# Logout (Ctrl+D) y login como passh
```

### Verificar Hardware

```bash
# Diagnostico completo
macbook-diag

# Info del sistema
macbook-info

# Debug WiFi
wifi-debug
```

### Conectar WiFi (Broadcom)

```bash
# Verificar driver cargado
lsmod | grep wl
# Debe mostrar "wl" (broadcom_sta)

# Ver redes disponibles
nmcli device wifi list

# Conectar
nmcli device wifi connect "TU_SSID" password "TU_PASSWORD"

# Si falla, reiniciar NetworkManager
sudo systemctl restart NetworkManager
nmcli device wifi connect "TU_SSID" password "TU_PASSWORD"

# Si sigue fallando, usar USB WiFi externo
```

### Verificar Touch Bar

```bash
# Estado
touchbar-status

# Si no muestra F1-F12, iniciar servicio
sudo systemctl start tiny-dfr
sudo systemctl enable tiny-dfr
```

## Troubleshooting

### WiFi detecta redes pero no conecta

Este es un problema conocido con Broadcom BCM43602. Opciones:

1. **Reiniciar driver:**
   ```bash
   sudo modprobe -r wl
   sudo modprobe wl
   sudo systemctl restart NetworkManager
   ```

2. **Verificar no hay drivers conflictivos:**
   ```bash
   lsmod | grep -E "b43|bcma|brcm"
   # Debe estar vacio
   ```

3. **Usar USB WiFi como alternativa permanente**

### Teclado no funciona despues de instalar

```bash
# Verificar modulos SPI
lsmod | grep -E "applespi|spi_pxa|intel_lpss"

# Si faltan, cargar manualmente
sudo modprobe intel_lpss_pci
sudo modprobe spi_pxa2xx_platform
sudo modprobe applespi
```

### Pantalla muy pequena (sin HiDPI)

```bash
# Verificar variables de entorno
echo $GDK_SCALE  # Debe ser 2
echo $GDK_DPI_SCALE  # Debe ser 0.5

# Si no estan, cerrar sesion y volver a entrar
# O ejecutar manualmente:
export GDK_SCALE=2
export GDK_DPI_SCALE=0.5
```

### Error "hash mismatch" durante nixos-install

El fetchTarball sin sha256 puede fallar. Soluciones:

1. **Calcular hash:**
   ```bash
   nix-prefetch-url --unpack https://github.com/NixOS/nixos-hardware/archive/936e115319d90c5034c1918bac28ee85455bc5ba.tar.gz
   ```

2. **Usar version sin hash (menos seguro pero funciona):**
   Editar configuration.nix y quitar la linea sha256.

### Boot loop o kernel panic

1. En GRUB, seleccionar entrada anterior (si existe)
2. Boot en modo single user (editar entrada GRUB, agregar `single`)
3. Verificar hardware-configuration.nix tiene UUIDs correctos

## Archivos Creados

Despues de seguir esta guia, tendras:

```
/etc/nixos/
├── configuration.nix              # Basado en configuration-24.04.nix
├── hardware-configuration.nix     # Generado por nixos-generate-config
└── modules/
    └── apple-hardware.nix         # Basado en apple-hardware-24.04.nix
```

## Siguiente Paso: Dotfiles

Una vez el sistema funciona:

```bash
# Si no clonaste durante instalacion
git clone https://github.com/TU_USUARIO/dotfiles.git ~/dotfiles

# Aplicar configs con stow
cd ~/dotfiles
stow -v fish
stow -v alacritty
stow -v xmonad
stow -v xmobar

# Home Manager
home-manager switch
```

## Referencias

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [NixOS Hardware Repository](https://github.com/NixOS/nixos-hardware)
- [ArchWiki: MacBook Pro 13,2](https://wiki.archlinux.org/title/Mac)
- [broadcom-sta](https://wiki.archlinux.org/title/Broadcom_wireless)
- [tiny-dfr](https://github.com/kekrby/tiny-dfr)

---

**Ultima actualizacion:** 2026-01-03
**Probado con:** NixOS 24.04 en MacBook Pro 13,2 (2016)
