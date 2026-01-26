# =============================================================================
# HOME-MANAGER: libinput-gestures
# =============================================================================
# Gestos de trackpad para cambiar workspaces y otras acciones.
# Solo para maquinas con trackpad (MacBook).
#
# Uso en machines/macbook.nix:
#   dotfiles.libinput-gestures.enable = true;
#
# Requisitos:
#   - Usuario debe estar en grupo 'input'
#   - libinput debe estar habilitado (services.libinput.enable)
# =============================================================================

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.dotfiles.libinput-gestures;
in
{
  options.dotfiles.libinput-gestures = {
    enable = lib.mkEnableOption "libinput-gestures for trackpad gestures";

    extraGestures = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Additional gesture configurations";
      example = ''
        gesture swipe up 4 xdotool key super+w
        gesture swipe down 4 xdotool key super+s
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      libinput-gestures
      xdotool
      wmctrl
    ];

    home.file.".config/libinput-gestures.conf".text = ''
      # libinput-gestures configuration
      # Gestos para cambiar workspaces en XMonad

      # 3 dedos izquierda -> workspace anterior
      gesture swipe left 3 xdotool key super+Left

      # 3 dedos derecha -> workspace siguiente
      gesture swipe right 3 xdotool key super+Right

      ${cfg.extraGestures}
    '';

    systemd.user.services.libinput-gestures = {
      Unit = {
        Description = "Libinput gestures daemon";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Install.WantedBy = [ "graphical-session.target" ];
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.libinput-gestures}/bin/libinput-gestures";
        Restart = "on-failure";
        RestartSec = "3";
        # Variables de entorno X11 necesarias para xdotool
        Environment = [
          "DISPLAY=:0"
        ];
        PassEnvironment = [ "XAUTHORITY" ];
        # Evitar spam de reinicios si hay problemas de permisos
        StartLimitIntervalSec = "60";
        StartLimitBurst = "5";
      };
    };
  };
}
