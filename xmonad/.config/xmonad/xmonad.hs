-- Importaciones necesarias
import XMonad
import XMonad.Util.EZConfig (additionalKeysP)
import XMonad.Util.SpawnOnce
import XMonad.Hooks.ManageDocks
import XMonad.Util.SpawnOnce
import XMonad.Actions.WithAll(sinkAll)
import XMonad.Util.NamedScratchpad
import qualified XMonad.StackSet as W
import XMonad.Hooks.DynamicLog
import XMonad.Util.Run (spawnPipe)
import System.IO (hPutStrLn)
import XMonad.Hooks.EwmhDesktops (ewmh, ewmhFullscreen)
import XMonad.Actions.GridSelect
import XMonad.Layout.ThreeColumns
import XMonad.Hooks.ManageHelpers (isDialog, doRectFloat)
import Data.Monoid (All)
import qualified Data.Map as M
import XMonad.Operations
import XMonad.Core
import XMonad.Layout.Spacing
import XMonad.Layout.NoBorders

myStartupHook :: X ()
myStartupHook = do
    spawnOnce "xrandr --output DP-0 --mode 5120x1440" -- Ajusta según tu configuración
    spawnOnce "nitrogen --random --set-zoom-fill ~/.config/xmonad/wallpapers"
    spawnOnce "picom -b"
    spawnOnce "~/.local/share/JetBrains/Toolbox/bin/jetbrains-toolbox"
    spawnOnce "emacs --daemon || emacsclient -e '(kill-emacs)' && emacs --daemon"
    spawnOnce "xfce4-clipman"  -- Iniciar Clipman
    spawnOnce "xscreensaver -no-splash"  -- Iniciar xscreensaver
    spawnOnce "xfce4-clipman"  -- Iniciar Clipman
    spawnOnce "trayer --edge top --align right --widthtype request --padding 6 --SetDockType true --SetPartialStrut true --expand true --monitor 0 --transparent true --alpha 0 --tint 0x282c34 --height 28"
    spawnOnce "eval $(ssh-agent) && ssh-add ~/.ssh/id_rsa"


-- Para añadir las aplicaciones de flatpak a dmenu
myDmenuCommand :: String
myDmenuCommand = "(flatpak list --app --columns=application | sed 's/^/flatpak run /' && dmenu_path) | sort -u | dmenu -i | ${SHELL:-\"/bin/sh\"} &"

myScratchPads = [
    NS "terminal" "alacritty --class=scratchpad" (className =? "scratchpad")
        (customFloating $ W.RationalRect 0.1 0.1 0.8 0.8),
    NS "doom" "doom run --class=scratchpad-notes" (className =? "scratchpad-notes")
        (customFloating $ W.RationalRect 0.15 0.1 0.7 0.75),
    NS "toolbox" "~/.local/share/JetBrains/Toolbox/bin/jetbrains-toolbox --class=scratchpad-jetbrains" (className =? "scratchpad-jetbrains")
        (customFloating $ W.RationalRect 0.1 0.1 0.8 0.8),
    NS "vpn-vocento" "/opt/pulsesecure/bin/pulseUI" (className =? "PulseUI" <&&> title =? "Pulse Secure")
        (customFloating $ W.RationalRect 0.1 0.1 0.8 0.8),
    NS "doom" "emacsclient -c -a 'emacs' --class=Emacs" (className =? "Emacs")
        (customFloating $ W.RationalRect 0.02 0.02 0.96 0.96)
    ]

myManageHook = composeAll
    [ className =? "Vlc" --> doFloat
    , className =? "btop-monitor" --> doRectFloat (W.RationalRect 0 0 1 1)  -- Pantalla completa
    ]

myLayoutHook = spacingWithEdge 5 $ avoidStruts $ smartBorders $
    ThreeColMid 1 (3/100) (1/3)
    ||| tiled
    ||| Mirror tiled
    ||| noBorders Full
  where
    tiled = Tall nmaster delta ratio
    nmaster = 1      -- Número predeterminado de ventanas en el área maestra
    ratio = 1/2      -- Proporción predeterminada del área ocupada por el área maestra
    delta = 3/100    -- Porcentaje del área de la pantalla para incrementar/reducir

main :: IO ()
main = do
    xmproc <- spawnPipe "xmobar"  -- Inicia xmobar
    xmonad $ ewmh $ ewmhFullscreen $ docks $ def
        { modMask = mod4Mask  -- Usa la tecla Windows como modificador
        , terminal = "alacritty"
        , borderWidth = 1
        , normalBorderColor = "#002b36"  -- Fondo
        , focusedBorderColor = "#268bd2"  -- Borde de la ventana activa
        , startupHook = myStartupHook
        , manageHook = namedScratchpadManageHook myScratchPads <+> myManageHook <+> manageHook def
        , layoutHook = myLayoutHook
        , handleEventHook = handleEventHook def
        , logHook = dynamicLogWithPP xmobarPP
            { ppOutput = hPutStrLn xmproc
            , ppCurrent = xmobarColor "#98c379" "" . wrap "[" "]"  -- Workspace actual
            , ppVisible = xmobarColor "#61afef" ""                 -- Visible en otro monitor
            , ppHidden = xmobarColor "#c678dd" "" . wrap "*" ""   -- Hidden con ventanas
            , ppHiddenNoWindows = xmobarColor "#666666" ""        -- Hidden sin ventanas
            , ppTitle = xmobarColor "#abb2bf" "" . shorten 160     -- Título de ventana
            , ppSep = "<fc=#666666> | </fc>"                      -- Separador
            , ppUrgent = xmobarColor "#e06c75" "" . wrap "!" "!"  -- Workspace urgente
            }
        }
        `additionalKeysP`
        [ ("M-p", spawn myDmenuCommand)
        , ("M-S-l", spawn "xscreensaver-command -lock")  -- glmatrix is cool
        , ("<XF86AudioLowerVolume>", spawn "amixer set Master 2%-")  -- Bajar volumen
        , ("<XF86AudioRaiseVolume>", spawn "amixer set Master 2%+")  -- Subir volumen
        , ("<XF86AudioMute>", spawn "amixer set Master toggle")  -- Silenciar/Activar sonido
        -- tts
        , ("M-t", spawn "xsel -o | python3 ~/.config/xmonad/my-scripts/tts.py")
        -- Hunde todas las ventanas flotantes
        , ("M-S-s", sinkAll)
        -- ides
        , ("M-S-e", spawn "/home/passh/.config/emacs/bin/doom run")
        , ("M-i", spawn "$(which idea)")
        -- keyboard es-us layout toggling izi
        , ("M-ñ", spawn "~/.config/xmonad/my-scripts/toggle-keyboard-layout.sh")
        , ("M-;", spawn "~/.config/xmonad/my-scripts/toggle-keyboard-layout.sh")
        -- scratchpads
        , ("M-a", namedScratchpadAction myScratchPads "terminal")
        , ("M-e", namedScratchpadAction myScratchPads "doom")
        , ("M-j", namedScratchpadAction myScratchPads "toolbox")
        , ("M-v", namedScratchpadAction myScratchPads "vpn-vocento")
        -- Flameshot GUI
        , ("<Print>", spawn "flameshot gui")
        -- Clipman
        , ("M-c", spawn "xfce4-popup-clipman")  -- Atajo para abrir el historial de Clipman
        , ("M-s", goToSelected def)
        -- Alt-Tab
        , ("M1-<Tab>", spawn "alttab -w 1 -d 0")
        -- Cambiar wallpaper
        , ("M-S-w", spawn "nitrogen --random --set-zoom-fill ~/.config/xmonad/wallpapers")
        -- Controles de espaciado
        , ("M-S-plus", incScreenWindowSpacing 2)   -- Incrementa el espacio
        , ("M-S-minus", decScreenWindowSpacing 2)  -- Reduce el espacio
        ]
