# =============================================================================
# MODULES/SERVICES/VOCENTO-VPN-BRIDGE.NIX - Bridge networking para VPN Vocento
# =============================================================================
# Configura networking con bridge para que una VM con VPN pueda actuar como
# gateway para las redes corporativas.
#
# La VM tiene el cliente Ivanti/Pulse VPN y se conecta al bridge br0.
# El host enruta el trafico de las redes corporativas via la VM.
#
# Arquitectura:
#   Internet <-> [Interface Externa] <-> Host <-> [br0] <-> VM VPN <-> Redes Vocento
#
# Uso en hosts/<machine>/default.nix:
#   imports = [ ../../modules/services/vocento-vpn-bridge.nix ];
#   services.vocento-vpn-bridge = {
#     enable = true;
#     externalInterface = "wlp0s20f0u7u4";  # Interface con internet
#   };
# =============================================================================
#
# ┌─────────────────────────────────────────────────────────────────────────┐
# │                    GUIA PARA NOOBS DE NIX                               │
# ├─────────────────────────────────────────────────────────────────────────┤
# │                                                                         │
# │  ESTRUCTURA DE UN MODULO NIXOS:                                         │
# │  ─────────────────────────────                                          │
# │  { config, pkgs, lib, ... }:    <- Funcion que recibe argumentos        │
# │  {                                                                      │
# │    options.foo = { ... };       <- Define opciones configurables        │
# │    config = { ... };            <- Aplica config si opciones activas    │
# │  }                                                                      │
# │                                                                         │
# │  CONCEPTOS CLAVE:                                                       │
# │  ────────────────                                                       │
# │  • with lib;      -> Importa funciones de lib (mkOption, mkIf, etc.)    │
# │  • let x = y; in  -> Define variable local x con valor y                │
# │  • mkOption       -> Crea una opcion configurable desde fuera           │
# │  • mkIf cond val  -> Solo aplica val si cond es true                    │
# │  • mkEnableOption -> Atajo para crear opcion enable = true/false        │
# │  • types.str      -> El valor debe ser un string                        │
# │  • types.listOf   -> El valor debe ser una lista de algo                │
# │  • cfg.algo       -> Accede al valor que el usuario puso en la opcion   │
# │                                                                         │
# └─────────────────────────────────────────────────────────────────────────┘

# Esta linea define el modulo como una FUNCION que recibe:
#   - config: la configuracion completa del sistema (para leer valores)
#   - pkgs: todos los paquetes de nixpkgs (para instalar programas)
#   - lib: funciones auxiliares de NixOS (mkOption, mkIf, types, etc.)
#   - ...: otros argumentos que no usamos pero podrian venir
{ config, pkgs, lib, ... }:

# "with lib;" importa todas las funciones de lib al scope actual
# Sin esto tendriamos que escribir lib.mkOption, lib.mkIf, lib.types.str, etc.
with lib;

# El bloque "let ... in" define variables locales que solo existen dentro
# del bloque que viene despues del "in"
let
  # cfg es un atajo para no escribir config.services.vocento-vpn-bridge cada vez
  # Cuando el usuario escribe: services.vocento-vpn-bridge.enable = true;
  # Nosotros lo leemos como: cfg.enable (que sera true)
  cfg = config.services.vocento-vpn-bridge;
in
{
  # ===========================================================================
  # OPTIONS - Definimos que puede configurar el usuario
  # ===========================================================================
  # Cada opcion tiene:
  #   - type: que tipo de valor acepta (str, int, bool, listOf str, etc.)
  #   - default: valor por defecto si el usuario no lo especifica
  #   - description: documentacion para nixos-option y manpages
  #   - example: ejemplo de uso (opcional)
  options.services.vocento-vpn-bridge = {

    # mkEnableOption crea automaticamente una opcion tipo bool
    # que el usuario activa con: services.vocento-vpn-bridge.enable = true;
    enable = mkEnableOption "Vocento VPN Bridge networking";

    # Esta opcion NO tiene default, asi que es OBLIGATORIA cuando enable = true
    externalInterface = mkOption {
      type = types.str;
      description = "Interface con acceso a internet (ej: enp7s0, wlp0s20f0u7u4)";
      example = "enp7s0";
    };

    hostAddress = mkOption {
      type = types.str;
      default = "192.168.53.10";
      description = "IP del host en el bridge br0";
    };

    vmAddress = mkOption {
      type = types.str;
      default = "192.168.53.12";
      description = "IP de la VM VPN (gateway para rutas corporativas)";
    };

    bridgeSubnet = mkOption {
      type = types.str;
      default = "192.168.53.0/24";
      description = "Subred del bridge";
    };

    # Esta opcion es una LISTA de objetos (submodules)
    # Cada objeto tiene sus propias opciones: address y prefixLength
    vpnRoutes = mkOption {
      type = types.listOf (types.submodule {
        options = {
          address = mkOption { type = types.str; };
          prefixLength = mkOption { type = types.int; };
        };
      });
      default = [
        { address = "10.180.0.0"; prefixLength = 16; }
        { address = "10.182.0.0"; prefixLength = 16; }
        { address = "192.168.196.0"; prefixLength = 24; }
        { address = "10.200.26.0"; prefixLength = 24; }
        { address = "10.184.0.0"; prefixLength = 16; }
        { address = "10.186.0.0"; prefixLength = 16; }
        { address = "34.175.0.0"; prefixLength = 16; }
        { address = "34.13.0.0"; prefixLength = 16; }
        { address = "192.168.201.0"; prefixLength = 24; }  # DNS Vocento
      ];
      description = "Redes corporativas a enrutar via la VM VPN";
    };

    dnsServers = mkOption {
      type = types.listOf types.str;  # Lista de strings
      default = [ "192.168.201.38" "192.168.201.43" "8.8.8.8" ];
      description = "Servidores DNS Vocento + fallback publico";
    };

    searchDomains = mkOption {
      type = types.listOf types.str;
      default = [ "grupo.vocento" ];
      description = "Dominios de busqueda DNS";
    };

    # types.nullOr permite que el valor sea null O el tipo indicado
    hostsFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Archivo hosts adicional (requiere --impure)";
      example = "/home/passh/src/vocento/autoenv/hosts_all.txt";
    };
  };

  # ===========================================================================
  # CONFIG - Lo que realmente se aplica al sistema
  # ===========================================================================
  # mkIf cfg.enable { ... } significa:
  # "Solo aplica esta configuracion si el usuario puso enable = true"
  # Si enable = false, todo este bloque se ignora completamente
  config = mkIf cfg.enable {

    # -------------------------------------------------------------------------
    # NETWORKING - Configuracion de red del sistema
    # -------------------------------------------------------------------------
    networking = {
      # Deshabilitamos el manejo automatico de DNS
      useHostResolvConf = false;
      resolvconf.enable = false;

      # Hosts adicionales (como /etc/hosts pero desde archivo externo)
      # mkIf anidado: solo si hostsFile no es null
      extraHosts = mkIf (cfg.hostsFile != null) (
        # builtins.pathExists comprueba si el archivo existe
        # builtins.readFile lee el contenido del archivo
        if builtins.pathExists cfg.hostsFile
        then builtins.readFile cfg.hostsFile
        else ""
      );

      # Bridge br0: interfaz virtual que conecta el host con la VM
      # interfaces = [] significa que NO conectamos interfaces fisicas al bridge
      # La VM se conecta al bridge via libvirt (vnet*)
      bridges.br0.interfaces = [ ];

      # Configuramos la IP del host en el bridge
      interfaces.br0 = {
        useDHCP = false;  # IP estatica, no DHCP
        ipv4 = {
          addresses = [{
            address = cfg.hostAddress;  # 192.168.53.10
            prefixLength = 24;          # /24 = 255.255.255.0
          }];

          # RUTAS ESTATICAS: el corazon del sistema VPN
          # "map" transforma cada elemento de vpnRoutes en una ruta
          # Cada ruta dice: "para llegar a address/prefix, pasa por vmAddress"
          routes = map (route: {
            # "inherit (route) x y" es atajo para: x = route.x; y = route.y;
            inherit (route) address prefixLength;
            via = cfg.vmAddress;  # La VM es el gateway para estas redes
          }) cfg.vpnRoutes;
        };
      };

      # NAT: permite que la VM salga a internet a traves del host
      # Sin esto, la VM podria hablar con el host pero no con internet
      nat = {
        enable = true;
        internalInterfaces = [ "br0" ];         # Desde donde viene trafico
        externalInterface = cfg.externalInterface;  # Por donde sale
        # iptables MASQUERADE: reescribe IP origen de paquetes del bridge
        extraCommands = ''
          iptables -t nat -A POSTROUTING -s ${cfg.bridgeSubnet} -j MASQUERADE
        '';
      };

      # Decimos a NetworkManager que NO toque estas interfaces
      # NixOS las gestiona, NM solo las estropearia
      networkmanager.unmanaged = [
        "interface-name:br0"
        "interface-name:vnet*"
      ];

      # Firewall: permisos de red
      firewall = {
        # checkReversePath = false es CRITICO para VPN
        # Normalmente Linux descarta paquetes que llegan por una interfaz
        # distinta a la que usaria para responder (anti-spoofing)
        # Pero con VPN, los paquetes llegan por br0 y responden por otra
        # interfaz, asi que deshabilitamos esta comprobacion
        checkReversePath = false;
        # Abrimos puerto 53 (DNS) por si la VM hace de servidor DNS
        allowedTCPPorts = [ 53 ];
        allowedUDPPorts = [ 53 ];
      };
    };

    # -------------------------------------------------------------------------
    # DNS - Configuracion manual de /etc/resolv.conf
    # -------------------------------------------------------------------------
    # Creamos el archivo nosotros en vez de dejar que lo gestione resolved
    environment.etc."resolv.conf" = {
      # La sintaxis '' ... '' es un string multilinea en Nix
      # ${variable} dentro del string se interpola (reemplaza por su valor)
      text = ''
        ${concatMapStrings (ns: "nameserver ${ns}\n") cfg.dnsServers}
        ${optionalString (cfg.searchDomains != []) "search ${concatStringsSep " " cfg.searchDomains}"}
        options timeout:1 attempts:1 rotate
      '';
      # concatMapStrings: aplica funcion a cada elemento y concatena resultados
      # optionalString: solo incluye el string si la condicion es true
      # concatStringsSep: une lista con separador (como join en otros lenguajes)
      mode = "0644";  # Permisos del archivo: rw-r--r--
    };

    # Deshabilitamos systemd-resolved porque gestionamos DNS manualmente
    services.resolved.enable = false;

    # -------------------------------------------------------------------------
    # NSSWITCH - Orden de resolucion de nombres
    # -------------------------------------------------------------------------
    # nsswitch.conf dice al sistema DONDE buscar informacion
    # Para hosts: primero files (/etc/hosts), luego dns
    environment.etc."nsswitch.conf" = {
      enable = true;
      text = ''
        passwd:    files systemd
        group:     files [success=merge] systemd
        shadow:    files
        sudoers:   files
        hosts:     files mymachines myhostname dns
        networks:  files
        ethers:    files
        services:  files
        protocols: files
        rpc:       files
      '';
    };

    # -------------------------------------------------------------------------
    # SCRIPTS HELPER - Comandos para diagnostico
    # -------------------------------------------------------------------------
    # Instalamos un script que el usuario puede ejecutar para ver el estado
    environment.systemPackages = [
      # pkgs.writeShellScriptBin crea un script ejecutable en /run/current-system/sw/bin/
      # Primer argumento: nombre del comando
      # Segundo argumento: contenido del script (bash)
      (pkgs.writeShellScriptBin "vpn-bridge-status" ''
        echo "=== VOCENTO VPN BRIDGE STATUS ==="
        echo ""
        echo "Bridge br0:"
        ip addr show br0 2>/dev/null | grep -E 'inet |state' || echo "  [ERROR] br0 no existe"
        echo ""
        echo "VM VPN (${cfg.vmAddress}):"
        ping -c 1 -W 1 ${cfg.vmAddress} >/dev/null 2>&1 && echo "  [OK] Alcanzable" || echo "  [ERROR] No alcanzable"
        echo ""
        echo "Rutas corporativas:"
        ip route | grep "via ${cfg.vmAddress}" | head -5 || echo "  [WARN] Sin rutas via VM"
        echo ""
        echo "DNS:"
        cat /etc/resolv.conf | grep -E '^nameserver|^search'
        echo ""
        echo "Test conectividad Vocento:"
        ping -c 1 -W 2 10.180.0.1 >/dev/null 2>&1 && echo "  [OK] 10.180.0.1 alcanzable" || echo "  [WARN] 10.180.0.1 no alcanzable (VPN conectada?)"
      '')
    ];
  };
}
