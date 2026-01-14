# =============================================================================
# XMobar Module - Configuracion parametrizable por maquina
# =============================================================================
# Este modulo genera xmobarrc dinamicamente basado en el hardware de cada
# maquina (DPI, GPU, interfaces de red).
#
# USO:
#   En machines/aurin.nix:
#     dotfiles.xmobar = {
#       enable = true;
#       fontSize = 16;
#       gpuType = "nvidia";
#       networkInterface = "enp10s0";
#       wifiInterface = "wlp8s5";
#     };
#
# NOTA: Usamos namespace "dotfiles.xmobar" para no colisionar con
# programs.xmobar nativo de home-manager.
# =============================================================================

{ config, lib, pkgs, ... }:

let
  cfg = config.dotfiles.xmobar;

  # Comando GPU segun tipo
  gpuCommand = {
    nvidia = ''
      Run Com "bash"
          ["-c", "nvidia-smi --query-gpu=temperature.gpu,utilization.gpu,memory.used,memory.total,power.draw --format=csv,noheader,nounits | awk -F',' '{printf \"GPU %.0f C %.0f%% %.1f/%.1fGB %.0fW\", $1, $2, $3/1024, $4/1024, $5}'"]
          "gpu"
          10
    '';
    intel = ''
      Run Com "bash"
          ["-c", "cat /sys/class/drm/card0/gt_cur_freq_mhz 2>/dev/null | awk '{printf \"Intel GPU %dMHz\", $1}' || echo 'Intel GPU'"]
          "gpu"
          30
    '';
    none = "";
  };

  # Template GPU en la barra segun tipo
  gpuTemplate = {
    nvidia = "<action=`nvidia-settings`><fc=#98c379><fn=1></fn> %gpu%</fc></action>";
    intel = "<fc=#61afef><fn=1></fn> %gpu%</fc>";
    none = "";
  };

  # Generar el xmobarrc completo
  # NOTA: Usamos sintaxis Pango (no Xft) - funciona correctamente en HiDPI
  # Sintaxis Pango: "Font Name Style Size" (ej: "Monoid Nerd Font Bold 16")
  xmobarConfig = ''
    Config {
        -- Apariencia basica (Pango para soporte HiDPI correcto)
        font = "HeavyData Nerd Font ${toString cfg.fontSize}"
        , additionalFonts = [ "HeavyData Nerd Font ${toString (cfg.fontSize + 4)}" ]
        , borderColor = "#282c34"
        , border = TopB
        , bgColor = "#282c34"
        , fgColor = "#abb2bf"
        , alpha = 255

        -- Posicionamiento (TopH = altura en pixels, calculada segun fontSize)
        , position = TopH ${toString (builtins.floor (cfg.fontSize * 1.8))}
        , textOffset = ${toString (builtins.floor (cfg.fontSize * 0.2))}
        , iconOffset = ${toString (builtins.floor (cfg.fontSize * 0.2))}

        -- Comportamiento
        , lowerOnStart = True
        , allDesktops = True
        , overrideRedirect = True
        , persistent = True
        , hideOnStart = False

        -- Comandos y monitores
        , commands = [
            ${lib.optionalString (cfg.gpuType != "none") (gpuCommand.${cfg.gpuType})}

            -- CPU con color dinámico (script externo)
            ${lib.optionalString (cfg.gpuType != "none") ","}Run Com "/home/passh/dotfiles/scripts/xmobar-cpu.sh" [] "cpu" 20

            -- Memoria con color dinámico (script externo)
            , Run Com "/home/passh/dotfiles/scripts/xmobar-memory.sh" [] "memory" 20

            ${lib.optionalString (cfg.networkInterface != null) ''
            -- Red Ethernet
            , Run Network "${cfg.networkInterface}"
                [ "-t", "<action=`alacritty -e nmtui`><fn=1>\xf0ac</fn> <rx>KB/<tx>KB</action>"
                , "-L", "1000"
                , "-H", "5000"
                , "-l", "#98c379"
                , "-n", "#e5c07b"
                , "-h", "#e06c75"
                ] 10
            ''}

            ${lib.optionalString (cfg.wifiInterface != null) ''
            -- WiFi con color dinámico (script externo)
            , Run Com "/home/passh/dotfiles/scripts/xmobar-wifi.sh" [] "wifi" 10
            ''}

            -- Docker containers
            , Run Com "bash"
                ["-c", "docker ps -q 2>/dev/null | wc -l | xargs -I{} echo '<fn=1>\xf308</fn> {}'"
                ] "docker" 50

            -- Fecha y hora con calendario
            , Run Date "<action=`gsimplecal`><fn=1>\xf017</fn> %a %d %b %H:%M</action>" "date" 10

            ${lib.optionalString (cfg.alsaMixer != null) ''
            -- Volumen
            , Run Alsa "default" "${cfg.alsaMixer}"
                [ "-t", "<action=`pavucontrol`><fn=1>\xf028</fn>  <volume>% <status></action>"
                , "--"
                , "--on", ""
                , "--off", "<fn=1>\xf026</fn>"
                , "--onc", "#98c379"
                , "--offc", "#e06c75"
                ]
            ''}

            ${lib.optionalString cfg.showDiskMonitor ''
            -- Monitor de discos genérico (NVMe + SATA + USB)
            , Run Com "/home/passh/dotfiles/scripts/xmobar-disks.sh" [] "disks" 60
            ''}

            -- Bateria con color dinámico (script externo)
            ${lib.optionalString cfg.showBattery ''
            , Run Com "/home/passh/dotfiles/scripts/xmobar-battery.sh" [] "battery" 50
            ''}

            -- Raton wireless (Logitech hidpp)
            ${lib.optionalString cfg.showWirelessMouse ''
            , Run Com "/home/passh/dotfiles/scripts/wireless-mouse.sh" [] "mouse" 100
            ''}

            -- XMonad Workspaces y Layout
            , Run StdinReader

            ${lib.optionalString cfg.showTrayer ''
            -- Bandeja del sistema
            , Run Com "trayer-padding-icon" [] "trayerpad" 10
            ''}
        ]

        -- Template
        -- LAYOUT: Izda (workspaces + fecha) | Dcha (menos importante → más importante)
        , sepChar = "%"
        , alignSep = "}{"
        , template = "%StdinReader% %date% }{${lib.optionalString cfg.showTrayer " %trayerpad% |"}${lib.optionalString (cfg.alsaMixer != null) " %alsa:default:${cfg.alsaMixer}%"}${lib.optionalString cfg.showWirelessMouse " %mouse%"}${lib.optionalString cfg.showBattery " %battery%"}${lib.optionalString (cfg.wifiInterface != null) " %wifi%"}${lib.optionalString (cfg.networkInterface != null) " %${cfg.networkInterface}%"} <fc=#56b6c2>%docker%</fc>${lib.optionalString cfg.showDiskMonitor " %disks%"}${lib.optionalString (cfg.gpuType != "none") (" " + gpuTemplate.${cfg.gpuType})} %memory% %cpu%"

    }
  '';

in {
  options.dotfiles.xmobar = {
    enable = lib.mkEnableOption "XMobar status bar configuration (dotfiles module)";

    fontSize = lib.mkOption {
      type = lib.types.int;
      default = 16;
      description = "Font size for xmobar (adjust for DPI)";
      example = 24;
    };

    gpuType = lib.mkOption {
      type = lib.types.enum [ "nvidia" "intel" "none" ];
      default = "none";
      description = "Type of GPU for monitoring";
      example = "nvidia";
    };

    networkInterface = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Primary network interface name";
      example = "enp10s0";
    };

    wifiInterface = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "WiFi interface name";
      example = "wlp8s5";
    };

    showBattery = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Show battery indicator (for laptops)";
    };

    showWirelessMouse = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Show wireless mouse battery indicator (Logitech hidpp)";
    };

    showDiskMonitor = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Show disk monitor (NVMe + SATA + USB, auto-detected)";
    };

    showTrayer = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Show trayer padding (requires trayer-padding-icon script)";
    };

    alsaMixer = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "Master";
      description = "Alsa mixer control name (null to disable volume)";
      example = "PCM";
    };
  };

  config = lib.mkIf cfg.enable {
    # Generar el archivo xmobarrc
    xdg.configFile."xmobar/xmobarrc".text = xmobarConfig;

    # Asegurar que xmobar esta instalado
    home.packages = [ pkgs.xmobar ];
  };
}
