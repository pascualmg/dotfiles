# =============================================================================
# MODULES/SERVICES/SYNCTHING.NIX - Syncthing centralizado (clone-first)
# =============================================================================
# Todos los device IDs en un solo lugar. Cada máquina se excluye a sí misma.
#
# USO EN HOSTS:
#   dotfiles.syncthing.enable = true;
#   dotfiles.syncthing.guiPort = 8385;  # opcional, default 8384
#
# AÑADIR NUEVA MÁQUINA:
#   1. Habilitar syncthing temporalmente en la máquina
#   2. Obtener ID: syncthing cli show system | grep myID
#   3. Añadir a allDevices abajo
#   4. Añadir a orgDevices si debe sincronizar ~/org
#
# =============================================================================

{ config, lib, pkgs, ... }:

let
  cfg = config.dotfiles.syncthing;

  # =========================================================================
  # TODOS LOS DEVICES CONOCIDOS
  # =========================================================================
  allDevices = {
    # Máquinas NixOS
    aurin = {
      id = "I5C3RVM-G3NN7HI-PU44PDV-GHSR7XK-3TKCRT5-L3SG4QW-GDT2O5D-YOT3DQJ";
    };
    vespino = {
      id = "C2DZIRD-A65IMBL-34MTS3M-ULVUMOL-6436UPS-DNZU5QI-ITPPIER-LWZCOAG";
    };
    macbook = {
      id = "Q5FFDRL-XIDVJRA-U5N4BG7-C6KXWOX-XY4UGS7-OLL56U6-BMKW4WP-JOW2KQN";
    };

    # Otros dispositivos
    cohete = {
      id = "MJCXI4B-EA5DX64-SY4QGGI-TKPDYG5-Y3OKBIU-XXAAWML-7TXS57Q-GLNQ4AY";
    };
    pocapullos = {
      id = "OYORVJB-XKOUBKT-NPILWWO-FYXSBAB-Q2FFRMC-YIZB4FW-XX5HDWR-X6K65QE";
    };
  };

  # =========================================================================
  # DEVICES POR FOLDER
  # =========================================================================
  # Qué devices sincronizan cada folder
  orgDevices = [ "aurin" "vespino" "macbook" "cohete" "pocapullos" ];

  # =========================================================================
  # HOSTNAME ACTUAL
  # =========================================================================
  hostname = config.networking.hostName;

  # Devices SIN el actual (no puedes añadirte a ti mismo)
  otherDevices = lib.filterAttrs (name: _: name != hostname) allDevices;

  # Devices para ~/org SIN el actual
  otherOrgDevices = lib.filter (name: name != hostname) orgDevices;

in
{
  # =========================================================================
  # OPTIONS
  # =========================================================================
  options.dotfiles.syncthing = {
    enable = lib.mkEnableOption "Syncthing file sync (centralizado)";

    guiPort = lib.mkOption {
      type = lib.types.port;
      default = 8384;
      description = "Puerto para la GUI web de Syncthing";
    };

    extraFolders = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Folders adicionales específicos de este host";
    };
  };

  # =========================================================================
  # CONFIG
  # =========================================================================
  config = lib.mkIf cfg.enable {
    services.syncthing = {
      enable = true;
      user = "passh";
      group = "users";
      dataDir = "/home/passh";
      openDefaultPorts = true;
      guiAddress = "0.0.0.0:${toString cfg.guiPort}";

      # CRITICO: Sin esto, syncthing ignora la config declarativa
      overrideDevices = true;    # Reemplaza devices del XML con los de Nix
      overrideFolders = true;    # Reemplaza folders del XML con los de Nix

      settings = {
        # Todos los devices menos yo
        devices = otherDevices;

        # Folders compartidos
        folders = {
          # ~/org - Sincronizado entre todas las máquinas
          "org" = {
            id = "pgore-xe7pu";
            path = "/home/passh/org";
            devices = otherOrgDevices;
            type = "sendreceive";
            ignorePerms = false;
          };
        } // cfg.extraFolders;

        # GUI credentials
        gui = {
          user = "passh";
          password = "capullo100";  # TODO: mover a sops-nix
        };
      };
    };
  };
}
