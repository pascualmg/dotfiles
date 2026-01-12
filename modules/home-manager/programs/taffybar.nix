# =============================================================================
# Taffybar Module - Barra GTK3 con systray nativo
# =============================================================================
# Alternativa a xmobar con systray integrado, escrita en Haskell.
#
# USO:
#   En machines/macbook.nix:
#     dotfiles.taffybar = {
#       enable = true;
#       fontSize = 14;
#       showBattery = true;
#       showSystray = true;
#     };
# =============================================================================

{ config, lib, pkgs, ... }:

let
  cfg = config.dotfiles.taffybar;

  # Configuración Haskell de taffybar
  taffybarConfig = ''
    {-# LANGUAGE OverloadedStrings #-}
    -- ==========================================================================
    -- Taffybar Configuration
    -- ==========================================================================
    -- Barra de estado GTK3 con systray nativo
    -- Generado automáticamente por NixOS Home Manager
    -- ==========================================================================

    import System.Taffybar
    import System.Taffybar.Context (TaffybarConfig(..))
    import System.Taffybar.Hooks
    import System.Taffybar.Information.CPU
    import System.Taffybar.Information.Memory
    import System.Taffybar.SimpleConfig
    import System.Taffybar.Widget
    import System.Taffybar.Widget.Generic.PollingGraph
    import System.Taffybar.Widget.Generic.PollingLabel
    import System.Taffybar.Widget.Util
    import System.Taffybar.Widget.Workspaces
    import Text.Printf

    -- Colores (One Dark theme)
    cpuColor, memColor, batColor :: (Double, Double, Double, Double)
    cpuColor = (0.596, 0.765, 0.475, 1.0)  -- #98c379 verde
    memColor = (0.898, 0.753, 0.478, 1.0)  -- #e5c07b amarillo
    batColor = (0.380, 0.686, 0.937, 1.0)  -- #61afef azul

    -- ==========================================================================
    -- Widgets
    -- ==========================================================================

    -- CPU Graph
    cpuCallback :: IO [Double]
    cpuCallback = do
      (_, systemLoad, totalLoad) <- cpuLoad
      return [totalLoad, systemLoad]

    cpuCfg :: GraphConfig
    cpuCfg = defaultGraphConfig
      { graphDataColors = [cpuColor, (0.878, 0.424, 0.459, 0.5)]
      , graphLabel = Just "CPU"
      , graphWidth = 50
      , graphPadding = 0
      }

    -- Memory Graph
    memCallback :: IO [Double]
    memCallback = do
      mi <- parseMeminfo
      return [memoryUsedRatio mi]

    memCfg :: GraphConfig
    memCfg = defaultGraphConfig
      { graphDataColors = [memColor]
      , graphLabel = Just "MEM"
      , graphWidth = 50
      , graphPadding = 0
      }

    -- ==========================================================================
    -- Main
    -- ==========================================================================

    main :: IO ()
    main = do
      let myWorkspacesConfig = defaultWorkspacesConfig
            { minIcons = 1
            , widgetGap = 0
            , showWorkspaceFn = hideEmpty
            }

          myConfig = defaultSimpleTaffyConfig
            { startWidgets =
                workspacesNew myWorkspacesConfig
                : map (>>= buildContentsBox) [layoutNew defaultLayoutConfig]
            , centerWidgets = map (>>= buildContentsBox)
                [ windowsNew defaultWindowsConfig ]
            , endWidgets = map (>>= buildContentsBox) $ reverse
                [ textClockNewWith defaultClockConfig
                    { clockFormatString = "%a %d %b  %H:%M" }
                ${lib.optionalString cfg.showBattery ", batteryIconNew"}
                ${lib.optionalString cfg.showSystray ", sniTrayNew"}
                , pollingGraphNew memCfg 1 memCallback
                , pollingGraphNew cpuCfg 0.5 cpuCallback
                ]
            , barPosition = ${cfg.barPosition}
            , barHeight = ExactSize ${toString cfg.barHeight}
            , widgetSpacing = 8
            }

      startTaffybar $ withBatteryRefresh $ withLogServer $
                      withToggleServer $ toTaffybarConfig myConfig
  '';

  # CSS para estilo visual
  taffybarCSS = ''
    /* ==========================================================================
       Taffybar CSS - One Dark Theme
       ========================================================================== */

    /* Fondo de la barra */
    .taffy-window * {
      font-family: "Monoid Nerd Font", "Symbols Nerd Font", monospace;
      font-size: ${toString cfg.fontSize}px;
      color: #abb2bf;
    }

    .taffy-box {
      background-color: #282c34;
    }

    /* Workspaces */
    .workspace-label {
      padding: 0 6px;
    }

    .workspace-label.visible {
      color: #98c379;
      font-weight: bold;
    }

    .workspace-label.active {
      color: #61afef;
      font-weight: bold;
    }

    .workspace-label.hidden {
      color: #5c6370;
    }

    .workspace-label.urgent {
      color: #e06c75;
    }

    /* Título de ventana */
    .window-title {
      padding: 0 8px;
    }

    /* Reloj */
    .clock {
      padding: 0 8px;
      color: #abb2bf;
    }

    /* Batería */
    .battery {
      padding: 0 4px;
    }

    /* Graphs */
    .graph {
      padding: 0 2px;
    }

    .graph-label {
      font-size: ${toString (cfg.fontSize - 2)}px;
      color: #5c6370;
    }

    /* Systray */
    .sni-tray {
      padding: 0 4px;
    }

    /* Layout */
    .layout-label {
      padding: 0 8px;
      color: #c678dd;
    }
  '';

in {
  options.dotfiles.taffybar = {
    enable = lib.mkEnableOption "Taffybar status bar (GTK3 con systray nativo)";

    fontSize = lib.mkOption {
      type = lib.types.int;
      default = 14;
      description = "Font size for taffybar";
      example = 16;
    };

    barHeight = lib.mkOption {
      type = lib.types.int;
      default = 30;
      description = "Height of the bar in pixels";
      example = 36;
    };

    showBattery = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Show battery indicator (for laptops)";
    };

    showSystray = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Show system tray (SNI - StatusNotifierItem)";
    };

    barPosition = lib.mkOption {
      type = lib.types.enum [ "Top" "Bottom" ];
      default = "Top";
      description = "Position of the bar (Top or Bottom)";
    };
  };

  config = lib.mkIf cfg.enable {
    # Archivo de configuración Haskell
    xdg.configFile."taffybar/taffybar.hs".text = taffybarConfig;

    # Archivo CSS para estilos
    xdg.configFile."taffybar/taffybar.css".text = taffybarCSS;

    # Paquetes necesarios
    home.packages = with pkgs; [
      taffybar
      hicolor-icon-theme  # Iconos básicos
      gnome-icon-theme    # Iconos adicionales
    ];

    # Servicios para systray
    services.status-notifier-watcher.enable = cfg.showSystray;
  };
}
