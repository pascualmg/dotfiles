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
#
# ┌─────────────────────────────────────────────────────────────────────────┐
# │                    GUIA PARA NOOBS DE NIX                               │
# ├─────────────────────────────────────────────────────────────────────────┤
# │                                                                         │
# │  STRINGS EN NIX:                                                        │
# │  ───────────────                                                        │
# │  "hola"           -> String simple (una linea)                          │
# │  ''hola           -> String multilinea (varias lineas)                  │
# │    mundo''                                                              │
# │  "${var}"         -> Interpolacion: inserta valor de var en string      │
# │  ''${var}''       -> En multilinea tambien funciona                     │
# │  "''$" + "{1:-}"  -> Escapar ${ en bash: se escribe ''$                 │
# │                                                                         │
# │  CONDICIONALES:                                                         │
# │  ──────────────                                                         │
# │  if cond then a else b   -> Ternario (siempre necesita else)            │
# │  optionalString cond s   -> Devuelve s si cond es true, "" si no        │
# │                                                                         │
# │  FUNCIONES:                                                             │
# │  ──────────                                                             │
# │  (x: x + 1)              -> Funcion anonima (lambda): recibe x, suma 1  │
# │  map (x: x*2) [1 2 3]    -> Aplica funcion a lista: [2 4 6]             │
# │                                                                         │
# │  LIBVIRT XML:                                                           │
# │  ────────────                                                           │
# │  libvirt usa XML para definir VMs. Aqui generamos ese XML desde Nix     │
# │  usando pkgs.writeText para crear un archivo con el contenido           │
# │                                                                         │
# └─────────────────────────────────────────────────────────────────────────┘

# Argumentos que recibe el modulo (igual que el otro archivo)
{ config, pkgs, lib, ... }:

# Importamos funciones de lib para no tener que escribir lib.mkOption, etc.
with lib;

let
  # Atajo para acceder a la configuracion de este modulo
  cfg = config.services.ivanti-vpn-vm;

  # Constantes: nombre de la VM y ruta del disco
  # Estas NO son opciones configurables, son valores fijos
  vmName = "ivanti-vpn";
  diskPath = "/var/lib/libvirt/images/ivanti-vpn-clone.qcow2";

  # Configuracion de red segun el modo elegido
  # if-then-else en Nix SIEMPRE necesita ambas ramas (then y else)
  # El resultado es un string con XML de libvirt
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

  # pkgs.writeText crea un archivo en /nix/store/ con el contenido dado
  # Usamos esto para generar el XML de definicion de la VM
  # El XML es el formato que usa libvirt para definir maquinas virtuales
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

# Fin del bloque "let", ahora viene el cuerpo del modulo
in
{
  # ===========================================================================
  # OPTIONS - Lo que el usuario puede configurar
  # ===========================================================================
  options.services.ivanti-vpn-vm = {

    # Opcion para habilitar/deshabilitar el modulo completo
    enable = mkEnableOption "Ivanti VPN VM";

    # types.enum restringe los valores posibles a una lista cerrada
    # Solo puede ser "nat" o "bridge", cualquier otro valor da error
    networkMode = mkOption {
      type = types.enum [ "nat" "bridge" ];
      default = "nat";
      description = ''
        Modo de red para la VM:
        - nat: Red NAT de libvirt (192.168.122.x) - para testing
        - bridge: Bridge br0 (192.168.53.x) - para produccion con rutas
      '';
    };

    # Nota: el default usa cfg.networkMode, lo cual es evaluacion lazy
    # Nix evalua esto SOLO cuando se necesita el valor, no antes
    vmAddress = mkOption {
      type = types.str;
      default = if cfg.networkMode == "bridge" then "192.168.53.12" else "192.168.122.192";
      description = "IP de la VM (para SSH y scripts)";
    };

    hostAddress = mkOption {
      type = types.str;
      default = if cfg.networkMode == "bridge" then "192.168.53.10" else "192.168.122.1";
      description = "IP del host/gateway (para configurar red en la VM)";
    };
  };

  # ===========================================================================
  # CONFIG - La implementacion real del modulo
  # ===========================================================================
  config = mkIf cfg.enable {

    # -------------------------------------------------------------------------
    # SERVICIO SYSTEMD - Define la VM en libvirt al arrancar
    # -------------------------------------------------------------------------
    # systemd.services crea un servicio que systemd gestiona
    # Este servicio se ejecuta una vez al arrancar y define la VM
    systemd.services.define-ivanti-vpn-vm = {
      description = "Define Ivanti VPN VM in libvirt";
      # after/requires: este servicio necesita que libvirtd este corriendo
      after = [ "libvirtd.service" ];
      requires = [ "libvirtd.service" ];
      # wantedBy: hace que el servicio arranque automaticamente con el sistema
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "oneshot";         # Se ejecuta una vez y termina
        RemainAfterExit = true;   # systemd lo considera "activo" aunque haya terminado
      };

      # El script que se ejecuta (bash)
      # optionalString solo incluye el bloque si la condicion es true
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

    # -------------------------------------------------------------------------
    # PAQUETES Y SCRIPT HELPER
    # -------------------------------------------------------------------------
    # environment.systemPackages instala paquetes disponibles para todos los usuarios
    environment.systemPackages = with pkgs; [
      guestfs-tools  # Para virt-customize (modificar discos de VM)

      # writeShellScriptBin crea un comando ejecutable
      # El script vpn-vm simplifica el uso diario de la VM
      #
      # NOTA IMPORTANTE sobre sintaxis bash en Nix:
      # En bash normal escribirias: case "${1:-}" in
      # Pero en Nix, ${ inicia interpolacion de variables
      # Para escribir un literal ${ usamos: ''$  seguido de {
      # Asi que "${1:-}" se escribe como: "''${1:-}"
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
          setup-network)
            # Configura IP estatica en la VM (requiere VM apagada)
            # Usa virt-customize para inyectar archivos en el disco qcow2
            echo "Configurando red en la VM..."

            STATE=$(virsh domstate ${vmName} 2>/dev/null || echo "unknown")
            if [ "$STATE" = "running" ]; then
              echo "ERROR: La VM debe estar apagada. Ejecuta: vpn-vm stop"
              exit 1
            fi

            DISK="${diskPath}"
            if [ ! -f "$DISK" ]; then
              echo "ERROR: Disco no encontrado: $DISK"
              exit 1
            fi

            # Crear archivo netplan temporal
            # netplan es el sistema de configuracion de red de Ubuntu
            NETPLAN=$(mktemp)
            cat > "$NETPLAN" << 'YAML'
        network:
          version: 2
          ethernets:
            ens3:
              addresses:
                - ${cfg.vmAddress}/24
              routes:
                - to: default
                  via: ${cfg.hostAddress}
              nameservers:
                addresses:
                  - 8.8.8.8
                  - 8.8.4.4
        YAML

            echo "Inyectando configuracion de red en el disco..."
            # virt-customize modifica el disco sin arrancar la VM
            sudo virt-customize -a "$DISK" \
              --upload "$NETPLAN":/etc/netplan/01-bridge.yaml \
              --run-command 'chmod 600 /etc/netplan/01-bridge.yaml' \
              --run-command 'rm -f /etc/netplan/00* /etc/netplan/50*' \
              2>&1

            rm -f "$NETPLAN"
            echo ""
            echo "Red configurada! IP: ${cfg.vmAddress}"
            echo "Ahora puedes arrancar la VM: vpn-vm start"
            ;;
          *)
            echo "Uso: vpn-vm <start|stop|status|ssh|viewer|ip|setup-network>"
            echo ""
            echo "Comandos:"
            echo "  start         - Arranca la VM y abre virt-viewer"
            echo "  stop          - Apaga la VM"
            echo "  status        - Muestra estado de la VM"
            echo "  ssh           - Conectar por SSH a la VM"
            echo "  viewer        - Abre virt-viewer (VM debe estar corriendo)"
            echo "  ip            - Muestra IP de la VM"
            echo "  setup-network - Configura IP estatica (VM debe estar apagada)"
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
