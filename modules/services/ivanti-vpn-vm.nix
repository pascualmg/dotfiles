# =============================================================================
# MODULES/SERVICES/IVANTI-VPN-VM.NIX - VM Ubuntu para Ivanti VPN (declarativa)
# =============================================================================
# Define una VM Ubuntu con el cliente Ivanti VPN de forma declarativa.
#
# La VM se define automaticamente en libvirt al hacer nixos-rebuild.
# El disco QCOW2 debe existir en /var/lib/libvirt/images/
#
# Modos de red:
#   - nat (default): Usa red NAT de libvirt (192.168.122.x) - para testing
#   - bridge: Usa bridge br0 (192.168.53.x) - para produccion con rutas
#
# Uso:
#   vpn-vm start   # Arrancar VM y abrir viewer
#   vpn-vm stop    # Apagar VM
#   vpn-vm status  # Ver estado
#   vpn-vm ssh     # Conectar por SSH
#
# Conectar VPN:
#   1. vpn-vm start
#   2. En Ubuntu: abrir cliente Ivanti y conectar
#   3. El trafico VPN pasa por la VM
# =============================================================================

{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.services.ivanti-vpn-vm;

  vmName = "ivanti-vpn";
  diskPath = "/var/lib/libvirt/images/ivanti-vpn-clone.qcow2";

  # Configuracion de red segun modo
  networkConfig = if cfg.networkMode == "bridge" then ''
    <interface type='bridge'>
      <mac address='52:54:00:04:89:fa'/>
      <source bridge='br0'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x0'/>
    </interface>
  '' else ''
    <interface type='network'>
      <mac address='52:54:00:04:89:fa'/>
      <source network='default'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x0'/>
    </interface>
  '';

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
        ${networkConfig}
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
  # ===========================================================================
  # OPTIONS
  # ===========================================================================
  options.services.ivanti-vpn-vm = {
    enable = mkEnableOption "Ivanti VPN VM";

    networkMode = mkOption {
      type = types.enum [ "nat" "bridge" ];
      default = "nat";
      description = ''
        Modo de red para la VM:
        - nat: Red NAT de libvirt (192.168.122.x) - para testing
        - bridge: Bridge br0 (192.168.53.x) - para produccion con rutas
      '';
    };

    vmAddress = mkOption {
      type = types.str;
      default = if cfg.networkMode == "bridge" then "192.168.53.12" else "192.168.122.192";
      description = "IP de la VM (para SSH y scripts)";
    };
  };

  # ===========================================================================
  # CONFIG
  # ===========================================================================
  config = mkIf cfg.enable {
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

      script = ''
        # Esperar a que libvirtd este listo
        sleep 2

        # Asegurar que la red default existe y tiene autostart (solo modo NAT)
        ${optionalString (cfg.networkMode == "nat") ''
          ${pkgs.libvirt}/bin/virsh net-autostart default 2>/dev/null || true
          ${pkgs.libvirt}/bin/virsh net-start default 2>/dev/null || true
        ''}

        # Verificar si la VM ya existe
        if ${pkgs.libvirt}/bin/virsh dominfo ${vmName} &>/dev/null; then
          echo "VM ${vmName} ya existe, verificando si necesita actualizacion..."
          # Redefinir para aplicar cambios (no afecta VM corriendo)
          ${pkgs.libvirt}/bin/virsh define ${vmXml} || true
        else
          echo "Definiendo VM ${vmName}..."
          ${pkgs.libvirt}/bin/virsh define ${vmXml}
        fi

        echo "VM ${vmName} lista (modo: ${cfg.networkMode}). Usar: vpn-vm start"
      '';
    };

    # Script helper para conectar rapidamente
    environment.systemPackages = [
      (pkgs.writeShellScriptBin "vpn-vm" ''
        set -euo pipefail

        VM_IP="${cfg.vmAddress}"

        case "''${1:-}" in
          start)
            echo "Arrancando VM Ivanti VPN (modo: ${cfg.networkMode})..."
            ${optionalString (cfg.networkMode == "nat") ''
              # Asegurar que la red default esta activa
              virsh net-start default 2>/dev/null || true
            ''}
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
            echo "IP: $VM_IP"
            echo "Modo: ${cfg.networkMode}"
            ping -c 1 -W 1 "$VM_IP" >/dev/null 2>&1 && echo "Ping: OK" || echo "Ping: FAIL"
            ;;
          ssh)
            echo "Conectando a VM ($VM_IP)..."
            SSH_AUTH_SOCK= ssh passh@"$VM_IP"
            ;;
          viewer)
            virt-viewer ${vmName} &
            ;;
          ip)
            echo "$VM_IP"
            ;;
          *)
            echo "Uso: vpn-vm <start|stop|status|ssh|viewer|ip>"
            echo ""
            echo "Comandos:"
            echo "  start   - Arranca la VM y abre virt-viewer"
            echo "  stop    - Apaga la VM"
            echo "  status  - Muestra estado de la VM"
            echo "  ssh     - Conectar por SSH a la VM"
            echo "  viewer  - Abre virt-viewer (VM debe estar corriendo)"
            echo "  ip      - Muestra IP de la VM"
            echo ""
            echo "Configuracion actual:"
            echo "  Modo de red: ${cfg.networkMode}"
            echo "  IP VM: $VM_IP"
            ;;
        esac
      '')
    ];
  };
}
