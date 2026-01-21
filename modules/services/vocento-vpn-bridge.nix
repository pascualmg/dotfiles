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

{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.services.vocento-vpn-bridge;
in
{
  # ===========================================================================
  # OPTIONS
  # ===========================================================================
  options.services.vocento-vpn-bridge = {
    enable = mkEnableOption "Vocento VPN Bridge networking";

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
      type = types.listOf types.str;
      default = [ "192.168.201.38" "192.168.201.43" "8.8.8.8" ];
      description = "Servidores DNS Vocento + fallback publico";
    };

    searchDomains = mkOption {
      type = types.listOf types.str;
      default = [ "grupo.vocento" ];
      description = "Dominios de busqueda DNS";
    };

    hostsFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Archivo hosts adicional (requiere --impure)";
      example = "/home/passh/src/vocento/autoenv/hosts_all.txt";
    };
  };

  # ===========================================================================
  # CONFIG
  # ===========================================================================
  config = mkIf cfg.enable {
    # -------------------------------------------------------------------------
    # NETWORKING
    # -------------------------------------------------------------------------
    networking = {
      useHostResolvConf = false;
      resolvconf.enable = false;

      # Hosts adicionales (Vocento)
      extraHosts = mkIf (cfg.hostsFile != null) (
        if builtins.pathExists cfg.hostsFile
        then builtins.readFile cfg.hostsFile
        else ""
      );

      # Bridge br0 (sin interfaces fisicas - la VM se conecta via libvirt)
      bridges.br0.interfaces = [ ];

      interfaces.br0 = {
        useDHCP = false;
        ipv4 = {
          addresses = [{
            address = cfg.hostAddress;
            prefixLength = 24;
          }];
          # Rutas corporativas via la VM VPN
          routes = map (route: {
            inherit (route) address prefixLength;
            via = cfg.vmAddress;
          }) cfg.vpnRoutes;
        };
      };

      # NAT para que la VM pueda salir a internet
      nat = {
        enable = true;
        internalInterfaces = [ "br0" ];
        externalInterface = cfg.externalInterface;
        extraCommands = ''
          iptables -t nat -A POSTROUTING -s ${cfg.bridgeSubnet} -j MASQUERADE
        '';
      };

      # NetworkManager no gestiona el bridge
      networkmanager.unmanaged = [
        "interface-name:br0"
        "interface-name:vnet*"
      ];

      # Firewall
      firewall = {
        # =====================================================================
        # checkReversePath = false (Reverse Path Filtering deshabilitado)
        # =====================================================================
        # NECESARIO para el setup VPN con VM bridge. Sin esto, el kernel
        # descarta paquetes que vienen de la VM con IPs de redes Vocento
        # (10.180.x.x, etc.) porque la ruta de entrada (br0) no coincide
        # con la ruta de salida esperada.
        #
        # El flujo es:
        #   1. Host envia paquete a 10.180.x.x -> via br0 -> VM -> VPN tunnel
        #   2. Respuesta llega: VPN tunnel -> VM -> br0 -> Host
        #   3. Kernel verifica: "Si yo enviara a esta IP origen, usaria br0?"
        #   4. Con RPF estricto: NO (porque 10.180.x.x no esta en br0 subnet)
        #   5. Kernel descarta el paquete -> conexion rota
        #
        # Con checkReversePath = false, el kernel acepta estos paquetes
        # asimetricos que son normales en configuraciones VPN con bridge.
        #
        # Alternativa mas segura (si fuera necesario):
        #   boot.kernel.sysctl."net.ipv4.conf.br0.rp_filter" = 0;
        # Esto deshabilitaria RPF solo para br0, no globalmente.
        # =====================================================================
        checkReversePath = false;
        allowedTCPPorts = [ 53 ];
        allowedUDPPorts = [ 53 ];
      };
    };

    # -------------------------------------------------------------------------
    # DNS (via VM)
    # -------------------------------------------------------------------------
    environment.etc."resolv.conf" = {
      text = ''
        ${concatMapStrings (ns: "nameserver ${ns}\n") cfg.dnsServers}
        ${optionalString (cfg.searchDomains != []) "search ${concatStringsSep " " cfg.searchDomains}"}
        options timeout:1 attempts:1 rotate
      '';
      mode = "0644";
    };

    services.resolved.enable = false;

    # -------------------------------------------------------------------------
    # NSSWITCH (files antes que dns)
    # -------------------------------------------------------------------------
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
    # SCRIPTS HELPER
    # -------------------------------------------------------------------------
    environment.systemPackages = [
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
