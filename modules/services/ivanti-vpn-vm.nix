# =============================================================================
# MODULES/SERVICES/IVANTI-VPN-VM.NIX - VM Ubuntu para Ivanti VPN (declarativa)
# =============================================================================
# Define una VM Ubuntu con el cliente Ivanti VPN de forma declarativa.
#
# La VM se define automaticamente en libvirt al hacer nixos-rebuild.
# El disco QCOW2 debe existir en /var/lib/libvirt/images/
#
# Uso:
#   virsh start ivanti-vpn     # Arrancar VM
#   virsh shutdown ivanti-vpn  # Apagar VM
#   virt-manager               # GUI para gestionar
#
# Conectar VPN:
#   1. Arrancar VM: virsh start ivanti-vpn
#   2. Abrir virt-manager o virt-viewer
#   3. En Ubuntu: abrir cliente Ivanti y conectar
#   4. El trafico VPN pasa por la VM
# =============================================================================

{ config, pkgs, lib, ... }:

let
  vmName = "ivanti-vpn";
  diskPath = "/var/lib/libvirt/images/ivanti-vpn-clone.qcow2";

  # XML de definicion de la VM
  vmXml = pkgs.writeText "ivanti-vpn.xml" ''
    <domain type='kvm'>
      <name>${vmName}</name>
      <uuid>8b9e4e4b-c2b0-4a60-a78b-c6ff31d328bc</uuid>
      <memory unit='KiB'>4194304</memory>
      <currentMemory unit='KiB'>4194304</currentMemory>
      <vcpu placement='static'>2</vcpu>
      <os>
        <type arch='x86_64' machine='pc-i440fx-10.1'>hvm</type>
        <boot dev='hd'/>
      </os>
      <features>
        <acpi/>
        <apic/>
      </features>
      <cpu mode='host-passthrough' check='none' migratable='on'/>
      <clock offset='utc'/>
      <on_poweroff>destroy</on_poweroff>
      <on_reboot>restart</on_reboot>
      <on_crash>destroy</on_crash>
      <devices>
        <emulator>/run/current-system/sw/bin/qemu-system-x86_64</emulator>
        <disk type='file' device='disk'>
          <driver name='qemu' type='qcow2'/>
          <source file='${diskPath}'/>
          <target dev='vda' bus='virtio'/>
          <address type='pci' domain='0x0000' bus='0x00' slot='0x05' function='0x0'/>
        </disk>
        <controller type='usb' index='0' model='piix3-uhci'>
          <address type='pci' domain='0x0000' bus='0x00' slot='0x01' function='0x2'/>
        </controller>
        <controller type='pci' index='0' model='pci-root'/>
        <controller type='virtio-serial' index='0'>
          <address type='pci' domain='0x0000' bus='0x00' slot='0x04' function='0x0'/>
        </controller>
        <interface type='network'>
          <mac address='52:54:00:04:89:fa'/>
          <source network='default'/>
          <model type='virtio'/>
          <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x0'/>
        </interface>
        <channel type='spicevmc'>
          <target type='virtio' name='com.redhat.spice.0'/>
          <address type='virtio-serial' controller='0' bus='0' port='1'/>
        </channel>
        <input type='tablet' bus='usb'>
          <address type='usb' bus='0' port='1'/>
        </input>
        <input type='mouse' bus='ps2'/>
        <input type='keyboard' bus='ps2'/>
        <graphics type='spice' autoport='yes' listen='127.0.0.1'>
          <listen type='address' address='127.0.0.1'/>
        </graphics>
        <audio id='1' type='spice'/>
        <video>
          <model type='qxl' ram='65536' vram='65536' vgamem='16384' heads='1' primary='yes'/>
          <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x0'/>
        </video>
        <memballoon model='virtio'>
          <address type='pci' domain='0x0000' bus='0x00' slot='0x06' function='0x0'/>
        </memballoon>
      </devices>
    </domain>
  '';

in
{
  # Asegurar que libvirtd esta habilitado (ya lo esta en virtualization.nix)
  # Solo definimos la VM

  # Servicio para definir la VM en libvirt
  systemd.services.define-ivanti-vpn-vm = {
    description = "Define Ivanti VPN VM in libvirt";
    after = [ "libvirtd.service" ];
    requires = [ "libvirtd.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    # Solo define si no existe o si el XML cambio
    script = ''
      # Esperar a que libvirtd este listo
      sleep 2

      # Asegurar que la red default existe y tiene autostart
      ${pkgs.libvirt}/bin/virsh net-autostart default 2>/dev/null || true
      ${pkgs.libvirt}/bin/virsh net-start default 2>/dev/null || true

      # Verificar si la VM ya existe
      if ${pkgs.libvirt}/bin/virsh dominfo ${vmName} &>/dev/null; then
        echo "VM ${vmName} ya existe, verificando si necesita actualizacion..."
        # Redefinir para aplicar cambios (no afecta VM corriendo)
        ${pkgs.libvirt}/bin/virsh define ${vmXml} || true
      else
        echo "Definiendo VM ${vmName}..."
        ${pkgs.libvirt}/bin/virsh define ${vmXml}
      fi

      echo "VM ${vmName} lista. Usar: virsh start ${vmName}"
    '';
  };

  # Script helper para conectar rapidamente
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "vpn-vm" ''
      set -euo pipefail

      case "''${1:-}" in
        start)
          echo "Arrancando VM Ivanti VPN..."
          # Asegurar que la red default esta activa
          virsh net-start default 2>/dev/null || true
          virsh start ${vmName} 2>/dev/null || echo "VM ya esta corriendo"
          echo "Abriendo virt-viewer..."
          virt-viewer ${vmName} &
          ;;
        stop)
          echo "Apagando VM Ivanti VPN..."
          virsh shutdown ${vmName}
          ;;
        status)
          virsh domstate ${vmName}
          ;;
        viewer)
          virt-viewer ${vmName} &
          ;;
        *)
          echo "Uso: vpn-vm <start|stop|status|viewer>"
          echo ""
          echo "Comandos:"
          echo "  start   - Arranca la VM y abre virt-viewer"
          echo "  stop    - Apaga la VM"
          echo "  status  - Muestra estado de la VM"
          echo "  viewer  - Abre virt-viewer (VM debe estar corriendo)"
          ;;
      esac
    '')
  ];
}
