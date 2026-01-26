# =============================================================================
# XMobar Module - Configuracion parametrizable por maquina
# =============================================================================
# Este modulo genera xmobarrc dinamicamente con 26 monitores que auto-detectan
# hardware. Los scripts no muestran nada si el hardware no existe.
#
# USO:
#   En machines/aurin.nix:
#     dotfiles.xmobar = {
#       enable = true;
#       fontSize = 16;              # Ajustar según DPI (16=96dpi, 22=168dpi)
#       showBattery = false;        # true para laptops
#       showDiskMonitor = true;     # Monitores de disco
#       alsaMixer = "Master";       # Control ALSA (default: Master)
#     };
#
# MONITORES (26 total, auto-detectan hardware):
#   - Estado/Servicios: vpn, docker, updates, machines, ssh
#   - Dispositivos: bt, volume, bright, battery, hhkb, mouse
#   - Red: wifi, network, disks
#   - Hardware: gpu, swap, memory, load, cpufreq, cpu, uptime
#
# MODOS DE USO:
#   - SPLIT (default en xmonad.hs): xmobar-workspaces.hs (top) + xmobar-monitors.hs (bottom)
#   - FULL: xmobarrc (top) - todos los monitores en 1 barra (disponible pero no usado por defecto)
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

        -- Comandos y monitores (26 total, auto-detectan hardware)
        , commands = [
            -- Estado/Servicios
            Run Com "/home/passh/dotfiles/scripts/xmobar-vpn.sh" [] "vpn" 30
            , Run Com "/home/passh/dotfiles/scripts/xmobar-docker.sh" [] "docker" 50
            , Run Com "/home/passh/dotfiles/scripts/xmobar-updates.sh" [] "updates" 3600
            , Run Com "/home/passh/dotfiles/scripts/xmobar-machines.sh" [] "machines" 60
            , Run Com "/home/passh/dotfiles/scripts/xmobar-ssh.sh" [] "ssh" 30
            
            -- Dispositivos
            , Run Com "/home/passh/dotfiles/scripts/xmobar-bluetooth.sh" [] "bt" 30
            ${lib.optionalString (cfg.alsaMixer != null) ''
              , Run Com "/home/passh/dotfiles/scripts/xmobar-volume.sh" [] "volume" 10
            ''}
            , Run Com "/home/passh/dotfiles/scripts/xmobar-brightness.sh" [] "bright" 30
            ${lib.optionalString cfg.showBattery ''
              , Run Com "/home/passh/dotfiles/scripts/xmobar-battery.sh" [] "battery" 50
            ''}
            , Run Com "/home/passh/dotfiles/scripts/xmobar-hhkb-battery.sh" [] "hhkb" 60
            , Run Com "/home/passh/dotfiles/scripts/xmobar-mouse-battery.sh" [] "mouse" 60
            
            -- Red
            , Run Com "/home/passh/dotfiles/scripts/xmobar-wifi.sh" [] "wifi" 30
            , Run Com "/home/passh/dotfiles/scripts/xmobar-network.sh" [] "network" 10
            
            -- Hardware
            ${lib.optionalString cfg.showDiskMonitor ''
              , Run Com "/home/passh/dotfiles/scripts/xmobar-disks.sh" [] "disks" 60
            ''}
            , Run Com "/home/passh/dotfiles/scripts/xmobar-gpu.sh" [] "gpu" 20
            , Run Com "/home/passh/dotfiles/scripts/xmobar-swap.sh" [] "swap" 30
            , Run Com "/home/passh/dotfiles/scripts/xmobar-memory.sh" [] "memory" 20
            , Run Com "/home/passh/dotfiles/scripts/xmobar-load.sh" [] "load" 20
            , Run Com "/home/passh/dotfiles/scripts/xmobar-cpu-freq.sh" [] "cpufreq" 20
            , Run Com "/home/passh/dotfiles/scripts/xmobar-cpu.sh" [] "cpu" 20
            , Run Com "/home/passh/dotfiles/scripts/xmobar-uptime.sh" [] "uptime" 60
            
            -- Fecha y hora
            , Run Date "<action=`gsimplecal`><fn=1>\xf017</fn> %a %d %b %H:%M</action>" "date" 10
            
            -- XMonad Workspaces
            , Run StdinReader
        ]

        -- Template
        -- LAYOUT: Workspaces (izda) | Servicios → Dispositivos → Red → Hardware → Fecha (dcha)
        -- Grupos separados por nixSep (󱄅)
        , sepChar = "%"
        , alignSep = "}{"
        , template = " %StdinReader% }{ %vpn%%docker%%updates%%machines%%ssh% ${nixSep} %bt%${
          lib.optionalString (cfg.alsaMixer != null) "%volume%"
        }%bright%${lib.optionalString cfg.showBattery "%battery%"}%hhkb%%mouse% ${nixSep} %wifi%%network%${lib.optionalString cfg.showDiskMonitor "%disks%"} ${nixSep} %gpu%%swap%%memory%%load%%cpufreq%%cpu%%uptime% ${nixSep} %date% "

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

    showBattery = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Show battery indicator (for laptops)";
    };

    showDiskMonitor = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Show disk monitor (NVMe + SATA + USB, auto-detected)";
    };

    alsaMixer = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "Master";
      description = "Alsa mixer control name (null to disable volume)";
      example = "PCM";
    };
  };

  config = lib.mkIf cfg.enable {
    # Generar el archivo xmobarrc (full - todo junto)
    xdg.configFile."xmobar/xmobarrc".text = xmobarConfig;

    # Configs para modo split (workspaces arriba, monitors abajo)
    xdg.configFile."xmobar/xmobar-workspaces.hs".source =
      ../../../xmobar/.config/xmobar/xmobar-workspaces.hs;
    xdg.configFile."xmobar/xmobar-monitors.hs".source =
      ../../../xmobar/.config/xmobar/xmobar-monitors.hs;

    # Asegurar que xmobar esta instalado
    home.packages = [ pkgs.xmobar ];
  };
}
