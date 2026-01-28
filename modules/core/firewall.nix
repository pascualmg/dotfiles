# =============================================================================
# MODULES/CORE/FIREWALL.NIX - Puertos comunes de desarrollo
# =============================================================================
# Puertos para desarrollo ad-hoc (servidores temporales sin módulo NixOS).
#
# IMPORTANTE: Los módulos con openFirewall=true ya abren sus puertos:
#   - Ollama (11434)      → services.ollama.openFirewall
#   - Syncthing (22000)   → services.syncthing.openDefaultPorts
#   - Avahi/mDNS (5353)   → services.avahi.openFirewall
#   - Sunshine (47984+)   → services.sunshine.openFirewall
#   - Steam (varios)      → programs.steam.remotePlay.openFirewall
#   - Minecraft (25565)   → services.minecraft-server.openFirewall
#
# NO duplicar esos puertos aquí.
#
# =============================================================================
# TROUBLESHOOTING - Desactivar firewall temporalmente
# =============================================================================
#
# OPCION 1 - Temporal (sin rebuild, se reactiva con reboot):
#   sudo systemctl stop firewall
#
# OPCION 2 - Permanente (requiere rebuild):
#   networking.firewall.enable = false;
#
# OPCION 3 - Ver qué puertos están abiertos:
#   sudo iptables -L -n | grep ACCEPT
#
# OPCION 4 - Abrir puerto temporal (hasta reboot):
#   sudo iptables -I nixos-fw -p tcp --dport 9999 -j ACCEPT
#
# =============================================================================

{ config, pkgs, lib, ... }:

{
  networking.firewall = {
    enable = lib.mkDefault true;

    # ===== PUERTOS TCP - Solo los que NO tienen módulo =====
    # Sin mkDefault para que se CONCATENE con los de hosts/
    allowedTCPPorts = [
      # Básicos (sin módulo específico)
      22                    # SSH
      80                    # HTTP
      443                   # HTTPS

      # Desarrollo web (servidores ad-hoc)
      3000                  # Node.js, React, Next.js
      4200                  # Angular
      5173                  # Vite
      8000                  # Python (Django, FastAPI)
      8080                  # PHP, Java, general dev
      8081                  # Alternative dev server
      8888                  # Jupyter notebooks

      # Remote desktop (x11vnc no tiene openFirewall)
      5900                  # VNC :0
      5901                  # VNC :1

      # Impresión
      631                   # CUPS
    ];

    # ===== PUERTOS UDP - Solo los que NO tienen módulo =====
    # (vacío - mDNS lo abre Avahi, Syncthing lo abre su módulo)
    # allowedUDPPorts se concatena automáticamente con los de hosts/
  };
}
