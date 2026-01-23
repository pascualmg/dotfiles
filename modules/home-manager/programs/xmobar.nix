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
#
# TODO (Phase 3 - Portability refactor):
#   - Reemplazar /home/passh/dotfiles/scripts/ con ${config.home.homeDirectory}/dotfiles/scripts/
#   - Usar helper: let scriptsDir = "${config.home.homeDirectory}/dotfiles/scripts"; in
#   - Afecta: todas las lineas Run Com "/home/passh/dotfiles/scripts/xmobar-*.sh"
#   - Ver xmonad.nix para TODO similar (mismo problema)
#   - Consultar nixos-guru: ~/dotfiles/claude-code/.claude/agents/nixos-guru.md
# =============================================================================

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.dotfiles.xmobar;

  # Comando GPU segun tipo
  gpuCommand = {
    nvidia = ''
      Run Com "/home/passh/dotfiles/scripts/xmobar-gpu-nvidia.sh" [] "gpu" 10
    '';
    intel = ''
      Run Com "/home/passh/dotfiles/scripts/xmobar-gpu-intel.sh" [] "gpu" 20
    '';
    none = "";
  };

  # Template GPU en la barra segun tipo
  gpuTemplate = {
    nvidia = "%gpu%"; # Script ya incluye formato, color y click action
    intel = "%gpu%"; # Script ya incluye formato y color
    none = "";
  };

  # Separador entre grupos de monitores (NixOS icon en gris sutil)
  nixSep = "<fc=#555555><fn=1>󱄅</fn></fc>";

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

            -- CPU frecuencia y governor (click abre cpupower-gui)
            ${
              lib.optionalString (cfg.gpuType != "none") ","
            }Run Com "/home/passh/dotfiles/scripts/xmobar-cpu-freq.sh" [] "cpufreq" 20

            -- CPU uso, temperatura y consumo (script externo)
            , Run Com "/home/passh/dotfiles/scripts/xmobar-cpu.sh" [] "cpu" 20

            -- Memoria con color dinámico (script externo)
            , Run Com "/home/passh/dotfiles/scripts/xmobar-memory.sh" [] "memory" 20

            -- Red genérica (auto-detecta eth/wifi, muestra IP)
            , Run Com "/home/passh/dotfiles/scripts/xmobar-network.sh" [] "network" 10

            -- Docker containers (click abre lazydocker)
            , Run Com "/home/passh/dotfiles/scripts/xmobar-docker.sh" [] "docker" 50

            -- Fecha y hora con calendario
            , Run Date "<action=`gsimplecal`><fn=1>\xf017</fn> %a %d %b %H:%M</action>" "date" 10

            ${lib.optionalString (cfg.alsaMixer != null) ''
              -- Volumen con color gradiente (script externo)
              , Run Com "/home/passh/dotfiles/scripts/xmobar-volume.sh" [] "volume" 10
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
              , Run Com "/home/passh/dotfiles/scripts/trayer-padding-icon.sh" [] "trayerpad" 10
            ''}
        ]

        -- Template
        -- LAYOUT: Izda (workspaces + fecha) | Dcha (menos importante → más importante)
        , sepChar = "%"
        , alignSep = "}{"
        , template = "%date% %StdinReader% }{${lib.optionalString cfg.showTrayer " %trayerpad% |"} ${nixSep} %docker% ${
          lib.optionalString (cfg.alsaMixer != null) "%volume% "
        }${lib.optionalString cfg.showWirelessMouse "%mouse% "}${lib.optionalString cfg.showBattery "%battery% "}%network% ${lib.optionalString cfg.showDiskMonitor "%disks% "}${nixSep} ${
          lib.optionalString (cfg.gpuType != "none") (gpuTemplate.${cfg.gpuType} + " " + nixSep + " ")
        }%memory% %cpufreq% %cpu% "

    }
  '';

in
{
  options.dotfiles.xmobar = {
    enable = lib.mkEnableOption "XMobar status bar configuration (dotfiles module)";

    fontSize = lib.mkOption {
      type = lib.types.int;
      default = 16;
      description = "Font size for xmobar (adjust for DPI)";
      example = 24;
    };

    gpuType = lib.mkOption {
      type = lib.types.enum [
        "nvidia"
        "intel"
        "none"
      ];
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
      default = false; # Trayer ahora es toggle con Mod+t, no necesita padding
      description = "Show trayer padding (deprecated, usar Mod+t para toggle)";
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
