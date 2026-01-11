-- =============================================================================
-- XMONAD CONFIGURATION
-- =============================================================================
-- Tiling window manager para X11 escrito en Haskell
--
-- Conceptos clave:
--   - Workspace: Escritorio virtual (1-9)
--   - Layout: Forma de organizar ventanas (Tall, Full, Grid, etc.)
--   - Mod key: Tecla modificadora (Super/Windows = mod4)
--   - Scratchpad: Ventana flotante que aparece/desaparece con un keybinding
--
-- Archivo: ~/.config/xmonad/xmonad.hs
-- Recompilar: xmonad --recompile && xmonad --restart
-- =============================================================================

-- -----------------------------------------------------------------------------
-- IMPORTS
-- -----------------------------------------------------------------------------
-- XMonad funciona con imports de módulos. Cada módulo añade funcionalidad.

import XMonad                           -- Core de XMonad
import XMonad.Util.EZConfig (additionalKeysP)  -- Keybindings estilo Emacs "M-x"
import XMonad.Util.SpawnOnce            -- Ejecutar comandos solo una vez al inicio
import XMonad.Hooks.ManageDocks         -- Integración con barras (xmobar, polybar)
import XMonad.Actions.WithAll (sinkAll) -- Acciones sobre todas las ventanas
import XMonad.Util.NamedScratchpad      -- Ventanas flotantes toggle (terminal, etc)
import qualified XMonad.StackSet as W   -- Manipulación de ventanas/workspaces
import XMonad.Hooks.DynamicLog          -- Enviar info a xmobar
import XMonad.Util.Run (spawnPipe)      -- Ejecutar procesos con pipe
import System.IO (hPutStrLn)            -- Escribir a handles (para xmobar)
import XMonad.Hooks.EwmhDesktops (ewmh, ewmhFullscreen)  -- Compatibilidad EWMH
import XMonad.Actions.GridSelect        -- Selector visual de ventanas
import XMonad.Layout.ThreeColumns       -- Layout 3 columnas
import XMonad.Layout.ResizableTile      -- Layout con resize flexible
import XMonad.Layout.MultiColumns       -- Layout múltiples columnas
import XMonad.Hooks.ManageHelpers       -- Helpers para manageHook
import Data.Monoid                      -- Para mempty en manageHook
import Data.List (elemIndex, sort)      -- Para navegación de workspaces
import qualified Data.Map as M          -- Para keybindings personalizados
import XMonad.Layout.Spacing            -- Gaps entre ventanas
import XMonad.Layout.NoBorders          -- Quitar bordes (fullscreen)
import XMonad.Layout.ToggleLayouts (toggleLayouts, ToggleLayout(..))  -- Toggle fullscreen
import XMonad.Layout.Grid               -- Layout grid
import XMonad.Layout.Column             -- Layout una columna
import XMonad.Actions.CopyWindow (copyToAll, killAllOtherCopies)  -- Ventanas sticky
import Graphics.X11.ExtraTypes.XF86     -- Teclas multimedia (volumen, brillo)

-- -----------------------------------------------------------------------------
-- CONFIGURACIÓN BÁSICA
-- -----------------------------------------------------------------------------

-- Comando para dmenu (lanzador de aplicaciones)
-- El flag -i hace que sea case-insensitive
myDmenuCommand :: String
myDmenuCommand = "dmenu_run -i"

-- -----------------------------------------------------------------------------
-- SCRATCHPADS
-- -----------------------------------------------------------------------------
-- Los scratchpads son ventanas flotantes que aparecen/desaparecen con un keybinding.
-- Útil para terminal rápida, notas, etc. sin ocupar un workspace.
--
-- Sintaxis: NS "nombre" "comando" (condición) (posición)
--   - nombre: identificador para el keybinding
--   - comando: qué ejecutar (con --class para identificar la ventana)
--   - condición: cómo identificar la ventana (className, title, etc.)
--   - posición: RationalRect x y width height (valores de 0.0 a 1.0)
--               x=0.1 significa 10% desde la izquierda
--               width=0.8 significa 80% del ancho de pantalla

myScratchPads :: [NamedScratchpad]
myScratchPads = [
    -- Terminal flotante (Mod+a)
    NS "terminal" "alacritty --class=scratchpad" (className =? "scratchpad")
        (customFloating $ W.RationalRect 0.1 0.1 0.8 0.8),

    -- Emacs para notas rápidas (Mod+e)
    -- Emacs usa --name (no --class), y XMonad lo detecta con "resource"
    NS "doom" "emacs --name=scratchpad-emacs" (resource =? "scratchpad-emacs")
        (customFloating $ W.RationalRect 0.15 0.1 0.7 0.75),

    -- JetBrains Toolbox (Mod+j)
    NS "toolbox" "~/.local/share/JetBrains/Toolbox/bin/jetbrains-toolbox --class=scratchpad-jetbrains" (className =? "scratchpad-jetbrains")
        (customFloating $ W.RationalRect 0.1 0.1 0.8 0.8),

    -- VPN Pulse Secure (Mod+v)
    NS "vpn-vocento" "/opt/pulsesecure/bin/pulseUI" (title =? "Pulse Secure")
        (customFloating $ W.RationalRect 0.1 0.1 0.8 0.8),

    -- Emacs client (alternativo) - usa className porque emacsclient SÍ respeta --class
    NS "emacs" "emacsclient -c -a 'emacs'" (className =? "Emacs")
        (customFloating $ W.RationalRect 0.02 0.02 0.96 0.96)
    ]

-- -----------------------------------------------------------------------------
-- MANAGE HOOK
-- -----------------------------------------------------------------------------
-- Define reglas para ventanas específicas: flotar, enviar a workspace, etc.
--
-- Operadores:
--   className =? "Nombre"  -> coincide con la clase de la ventana
--   title =? "Título"      -> coincide con el título
--   --> doFloat            -> hacer flotante
--   --> doShift "2"        -> enviar al workspace 2

myManageHook :: ManageHook
myManageHook = composeAll
    [ className =? "Vlc" --> doFloat              -- VLC siempre flotante
    , className =? "btop-monitor" --> doRectFloat (W.RationalRect 0 0 1 1)
    , isDialog --> doFloat                         -- Diálogos siempre flotantes
    ]

-- -----------------------------------------------------------------------------
-- LAYOUTS
-- -----------------------------------------------------------------------------
-- Los layouts definen cómo se organizan las ventanas en pantalla.
--
-- Layouts disponibles (cambiar con Mod+Space):
--   - ThreeColMid: 3 columnas, master en el medio (ideal para ultrawide)
--   - ResizableTall: 2 columnas, master a la izquierda (clásico)
--   - MultiCol: Múltiples columnas dinámicas
--   - Column: Una sola columna vertical
--   - Grid: Cuadrícula automática
--   - Tall: Tiling clásico
--   - Mirror Tall: Tall rotado 90°
--   - Full: Pantalla completa (toggle con Mod+f)
--
-- Modificadores aplicados:
--   - spacingWithEdge 5: Gap de 5px entre ventanas y bordes
--   - avoidStruts: Respetar espacio de xmobar
--   - smartBorders: Quitar bordes cuando solo hay 1 ventana
--   - toggleLayouts: Permite toggle rápido a fullscreen con Mod+f

myLayoutHook = toggleLayouts                    -- Permite Mod+f para toggle fullscreen
               (noBorders Full)                 -- Layout fullscreen (sin bordes, sin gaps)
               (avoidStruts tiledLayouts)       -- Layouts normales (respetan xmobar)
  where
    -- Layouts con tiling (gaps + bordes inteligentes)
    tiledLayouts = spacingWithEdge 5 $ smartBorders $
        ThreeColMid 1 (3/100) (2/3)             -- 3 columnas, master centro, 2/3 ancho
        ||| ResizableTall 1 (3/100) (1/2) []    -- 2 columnas redimensionables
        ||| multiCol [1] 1 0.01 (-0.5)          -- Múltiples columnas
        ||| Column 1.0                           -- Una columna
        ||| Grid                                 -- Cuadrícula
        ||| tiled                                -- Tall clásico
        ||| Mirror tiled                         -- Tall horizontal

    -- Configuración del layout Tall básico
    tiled   = Tall nmaster delta ratio
    nmaster = 1      -- Número de ventanas en master
    ratio   = 1/2    -- Master ocupa 50% de pantalla
    delta   = 3/100  -- Incremento al redimensionar (3%)

-- -----------------------------------------------------------------------------
-- STARTUP HOOK
-- -----------------------------------------------------------------------------
-- Comandos que se ejecutan UNA VEZ al iniciar XMonad.
-- spawnOnce garantiza que no se dupliquen al recargar config (Mod+q).

myStartupHook :: X ()
myStartupHook = do
    -- Display: configurar resolución y DPI
    spawnOnce "xrandr --output DP-4 --mode 5120x1440 --rate 120 --primary --dpi 96"

    -- Wallpaper aleatorio
    spawnOnce "nitrogen --random --set-zoom-fill ~/wallpapers"

    -- Compositor (transparencias, sombras, animaciones)
    spawnOnce "/home/passh/.nix-profile/bin/picom -b"

    -- Aplicaciones de inicio
    spawnOnce "/home/passh/.nix-profile/bin/jetbrains-toolbox"
    spawnOnce "emacs --daemon || emacsclient -e '(kill-emacs)' && emacs --daemon"
    spawnOnce "xfce4-clipman"  -- Gestor de portapapeles

    -- Barra de estado: Taffybar (GTK3 con systray nativo)
    -- NOTA: Si quieres volver a xmobar, comenta estas líneas y descomenta trayer
    spawnOnce "systemctl --user start status-notifier-watcher"  -- Necesario para systray
    spawnOnce "taffybar"
    -- spawnOnce "trayer --edge top --align right --widthtype request --padding 6 --SetDockType true --SetPartialStrut true --expand true --monitor 0 --transparent true --alpha 0 --tint 0x282c34 --height 28"

    -- Applets para systray (taffybar los muestra automáticamente)
    spawnOnce "nm-applet"
    spawnOnce "blueman-applet"

    -- SSH agent
    spawnOnce "eval $(ssh-agent) && ssh-add ~/.ssh/id_rsa"

    -- Audio (reiniciar pipewire por si hay problemas)
    spawnOnce "systemctl --user restart pipewire pipewire-pulse"

    -- Notificación de inicio
    spawnOnce "notify-send 'XMonad configuración recargada 8==D~mente'"

-- -----------------------------------------------------------------------------
-- NAVEGACIÓN DE WORKSPACES (sin wrap)
-- -----------------------------------------------------------------------------
-- Funciones personalizadas para Mod+Left / Mod+Right
-- A diferencia de nextWS/prevWS estándar, estas NO hacen wrap:
--   - En workspace 1, Mod+Left no hace nada (no salta al 9)
--   - En workspace 9, Mod+Right no hace nada (no salta al 1)

-- Ir al workspace anterior (sin wrap)
prevWS' :: X ()
prevWS' = do
    ws <- gets windowset                          -- Obtener estado actual
    let wss = map W.tag $ W.workspaces ws         -- Lista de tags de workspaces
    let cur = W.currentTag ws                     -- Workspace actual
    let sorted = sort wss                         -- Ordenar workspaces
    case elemIndex cur sorted of                  -- Buscar índice actual
        Just i | i > 0 -> windows $ W.greedyView (sorted !! (i - 1))  -- Si no es el primero, ir al anterior
        _ -> return ()                            -- Si es el primero, no hacer nada

-- Ir al workspace siguiente (sin wrap)
nextWS' :: X ()
nextWS' = do
    ws <- gets windowset
    let wss = map W.tag $ W.workspaces ws
    let cur = W.currentTag ws
    let sorted = sort wss
    case elemIndex cur sorted of
        Just i | i < length sorted - 1 -> windows $ W.greedyView (sorted !! (i + 1))  -- Si no es el último, ir al siguiente
        _ -> return ()                            -- Si es el último, no hacer nada

-- =============================================================================
-- MAIN
-- =============================================================================
-- Función principal que configura XMonad.
--
-- Wrappers aplicados (de dentro hacia fuera):
--   def         -> configuración por defecto de XMonad
--   docks       -> soporte para barras (xmobar)
--   ewmhFullscreen -> apps pueden pedir fullscreen (ej: YouTube)
--   ewmh        -> compatibilidad con otros programas (rofi, etc.)

main :: IO ()
main = do
    -- NOTA: Taffybar no necesita spawnPipe (usa EWMH/DBus)
    -- Si quieres volver a xmobar, descomenta la siguiente línea:
    -- xmproc <- spawnPipe "xmobar"

    -- Configuración de XMonad
    -- ewmh exporta info de workspaces que taffybar lee automáticamente
    xmonad $ ewmh $ ewmhFullscreen $ docks $ def
        -- =========================================
        -- CONFIGURACIÓN BÁSICA
        -- =========================================
        { modMask            = mod4Mask          -- Mod = Super/Windows key
        , terminal           = "alacritty"       -- Terminal por defecto (Mod+Shift+Enter)
        , borderWidth        = 1                 -- Ancho del borde de ventanas (px)
        , normalBorderColor  = "#002b36"         -- Color borde ventana inactiva (Solarized)
        , focusedBorderColor = "#268bd2"         -- Color borde ventana activa (azul)

        -- =========================================
        -- HOOKS
        -- =========================================
        , startupHook    = myStartupHook         -- Comandos al iniciar
        , manageHook     = namedScratchpadManageHook myScratchPads  -- Scratchpads
                           <+> myManageHook      -- Reglas de ventanas
                           <+> manageHook def    -- Reglas por defecto
        , layoutHook     = myLayoutHook          -- Layouts disponibles
        , handleEventHook = handleEventHook def  -- Eventos X11

        -- =========================================
        -- LOG HOOK
        -- =========================================
        -- Taffybar usa EWMH, no necesita logHook especial
        -- Si quieres volver a xmobar, restaura el logHook con xmobarPP
        , logHook = return ()  -- Taffybar lee de EWMH automáticamente
        {-
        , logHook = dynamicLogWithPP xmobarPP  -- Para xmobar
            { ppOutput          = hPutStrLn xmproc
            , ppCurrent         = xmobarColor "#98c379" "" . wrap "[" "]"
            , ppVisible         = xmobarColor "#61afef" ""
            , ppHidden          = xmobarColor "#c678dd" "" . wrap "*" ""
            , ppHiddenNoWindows = xmobarColor "#666666" ""
            , ppTitle           = xmobarColor "#abb2bf" "" . shorten 160
            , ppSep             = "<fc=#666666> | </fc>"
            , ppUrgent          = xmobarColor "#e06c75" "" . wrap "!" "!"
            }
        -}
        }

        -- =========================================
        -- KEYBINDINGS
        -- =========================================
        -- Sintaxis: ("M-x", acción)
        --   M = Mod (Super), S = Shift, C = Control, M1 = Alt
        --   Ejemplos: "M-S-q" = Mod+Shift+q, "M1-<Tab>" = Alt+Tab
        `additionalKeysP`

        -- -----------------------------------------
        -- Lanzadores
        -- -----------------------------------------
        [ ("M-p", spawn myDmenuCommand)          -- Lanzador de apps (dmenu)
        , ("M-S-l", spawn "xscreensaver-command -lock")  -- Bloquear pantalla

        -- -----------------------------------------
        -- Audio (teclas multimedia)
        -- -----------------------------------------
        , ("<XF86AudioLowerVolume>", spawn "pactl set-sink-volume @DEFAULT_SINK@ -2%")
        , ("<XF86AudioRaiseVolume>", spawn "pactl set-sink-volume @DEFAULT_SINK@ +2%")
        , ("<XF86AudioMute>", spawn "pactl set-sink-mute @DEFAULT_SINK@ toggle")
        , ("<XF86AudioMicMute>", spawn "pactl set-source-mute @DEFAULT_SOURCE@ toggle")

        -- -----------------------------------------
        -- Aplicaciones
        -- -----------------------------------------
        , ("M-t", spawn "xsel -o | python3 ~/.config/xmonad/my-scripts/tts.py")  -- TTS
        , ("M-i", spawn "$(which idea)")         -- IntelliJ IDEA

        -- -----------------------------------------
        -- Teclado
        -- -----------------------------------------
        , ("M-ñ", spawn "~/.config/xmonad/my-scripts/toggle-keyboard-layout.sh")  -- Toggle US/ES
        , ("M-;", spawn "~/.config/xmonad/my-scripts/toggle-keyboard-layout.sh")  -- Alias para US kbd

        -- -----------------------------------------
        -- Scratchpads (ventanas flotantes toggle)
        -- -----------------------------------------
        , ("M-a", namedScratchpadAction myScratchPads "terminal")   -- Terminal flotante
        , ("M-e", namedScratchpadAction myScratchPads "doom")       -- Emacs
        , ("M-j", namedScratchpadAction myScratchPads "toolbox")    -- JetBrains Toolbox
        , ("M-v", namedScratchpadAction myScratchPads "vpn-vocento") -- VPN

        -- -----------------------------------------
        -- Utilidades
        -- -----------------------------------------
        , ("<Print>", spawn "flameshot gui")     -- Captura de pantalla
        , ("M-c", spawn "xfce4-popup-clipman")   -- Historial clipboard
        , ("M-s", goToSelected def)              -- Selector visual de ventanas
        , ("M1-<Tab>", spawn "alttab -w 1 -d 0") -- Alt-Tab clásico
        , ("M-S-w", spawn "nitrogen --random --set-zoom-fill ~/wallpapers")  -- Wallpaper random
        , ("M-S-m", spawn "~/.config/xmonad/my-scripts/glmatrix-bg.sh")    -- Matrix de fondo
        , ("M-S-s", sinkAll)                     -- Unfloat todas las ventanas

        -- -----------------------------------------
        -- Spacing (gaps entre ventanas)
        -- -----------------------------------------
        , ("M-S-plus", incScreenWindowSpacing 2)   -- Aumentar gaps
        , ("M-S-minus", decScreenWindowSpacing 2)  -- Reducir gaps

        -- -----------------------------------------
        -- Navegación de workspaces
        -- -----------------------------------------
        , ("M-<Left>", prevWS')                  -- Workspace anterior (sin wrap)
        , ("M-<Right>", nextWS')                 -- Workspace siguiente (sin wrap)

        -- -----------------------------------------
        -- Fullscreen
        -- -----------------------------------------
        , ("M-f", sendMessage ToggleLayout)      -- Toggle fullscreen (Mod+f / Mod+f)
        ]
