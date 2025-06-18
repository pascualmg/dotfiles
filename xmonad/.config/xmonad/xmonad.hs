-- Importaciones necesarias
import XMonad
import XMonad.Util.EZConfig (additionalKeysP)
import XMonad.Util.SpawnOnce
import XMonad.Hooks.ManageDocks
import XMonad.Actions.WithAll (sinkAll)
import XMonad.Util.NamedScratchpad
import qualified XMonad.StackSet as W
import XMonad.Hooks.DynamicLog
import XMonad.Util.Run (spawnPipe)
import System.IO (hPutStrLn)
import XMonad.Hooks.EwmhDesktops (ewmh, ewmhFullscreen)
import XMonad.Actions.GridSelect
import XMonad.Layout.ThreeColumns
import XMonad.Layout.ResizableTile
import XMonad.Layout.MultiColumns
import XMonad.Hooks.ManageHelpers
import Data.Monoid
import qualified Data.Map as M
import XMonad.Layout.Spacing
import XMonad.Layout.NoBorders
import XMonad.Layout.Grid
import XMonad.Layout.Column
import XMonad.Actions.CopyWindow (copyToAll, killAllOtherCopies)
import Graphics.X11.ExtraTypes.XF86
import XMonad.Util.Types (Direction2D(..))

-- Configuración del comando dmenu
myDmenuCommand :: String
myDmenuCommand = "(flatpak list --app --columns=application | sed 's/^/flatpak run /' && find ~/.nix-profile/bin -type f -executable -printf \"%f\\n\" && dmenu_path) | sort -u | grep -v '^$' | dmenu -i | ${SHELL:-\"/bin/sh\"} &"

-- Definición de scratchpads
myScratchPads :: [NamedScratchpad]
myScratchPads = [
    NS "terminal" "alacritty --class=scratchpad" (className =? "scratchpad")
        (customFloating $ W.RationalRect 0.1 0.1 0.8 0.8),
    NS "doom" "doom run --class=scratchpad-notes" (className =? "scratchpad-notes")
        (customFloating $ W.RationalRect 0.15 0.1 0.7 0.75),
    NS "toolbox" "~/.local/share/JetBrains/Toolbox/bin/jetbrains-toolbox --class=scratchpad-jetbrains" (className =? "scratchpad-jetbrains")
        (customFloating $ W.RationalRect 0.1 0.1 0.8 0.8),
    NS "vpn-vocento" "/opt/pulsesecure/bin/pulseUI" (title =? "Pulse Secure")
        (customFloating $ W.RationalRect 0.1 0.1 0.8 0.8),
    NS "doom" "emacsclient -c -a 'emacs' --class=Emacs" (className =? "Emacs")
        (customFloating $ W.RationalRect 0.02 0.02 0.96 0.96)
    ]

-- Hook de gestión de ventanas
myManageHook :: ManageHook
myManageHook = composeAll
    [ className =? "Vlc" --> doFloat
    , className =? "btop-monitor" --> doRectFloat (W.RationalRect 0 0 1 1)
    , isDialog --> doFloat
    ]

-- Configuración del layout
myLayoutHook = spacingWithEdge 5 $ avoidStruts $ smartBorders $
    ThreeColMid 1 (3/100) (2/3)
    ||| ResizableTall 1 (3/100) (1/2) []  -- Para divisiones flexibles
    ||| multiCol [1] 1 0.01 (-0.5)  -- Ajusta el último número para el ancho relativo
    ||| Column 1.0
    ||| Grid
    ||| tiled
    ||| Mirror tiled
    ||| noBorders Full
  where
    tiled = Tall nmaster delta ratio
    nmaster = 1
    ratio = 1/2
    delta = 3/100

-- Hook de inicio
myStartupHook :: X ()
myStartupHook = do
    spawnOnce "xrandr --output DP-4 --mode 5120x1440 --rate 120 --primary --dpi 96"
    spawnOnce "nitrogen --random --set-zoom-fill ~/wallpapers"
    spawnOnce "/home/passh/.nix-profile/bin/picom -b"
    spawnOnce "/home/passh/.nix-profile/bin/jetbrains-toolbox"
    spawnOnce "emacs --daemon || emacsclient -e '(kill-emacs)' && emacs --daemon"
    spawnOnce "xfce4-clipman"
    --spawnOnce "xscreensaver -no-splash"
    spawnOnce "trayer --edge top --align right --widthtype request --padding 6 --SetDockType true --SetPartialStrut true --expand true --monitor 0 --transparent true --alpha 0 --tint 0x282c34 --height 28"
    spawnOnce "eval $(ssh-agent) && ssh-add ~/.ssh/id_rsa"
    spawnOnce "systemctl --user restart pipewire pipewire-pulse"
    spawnOnce "notify-send 'XMonad configuración recargada 8==D~mente'"

-- Función principal
main :: IO ()
main = do
    xmproc <- spawnPipe "xmobar"
    xmonad $ ewmh $ ewmhFullscreen $ docks $ def
        { modMask = mod4Mask
        , terminal = "alacritty"
        , borderWidth = 1
        , normalBorderColor = "#002b36"
        , focusedBorderColor = "#268bd2"
        , startupHook = myStartupHook
        , manageHook = namedScratchpadManageHook myScratchPads <+> myManageHook <+> manageHook def
        , layoutHook = myLayoutHook
        , handleEventHook = handleEventHook def
        , logHook = dynamicLogWithPP xmobarPP
            { ppOutput = hPutStrLn xmproc
            , ppCurrent = xmobarColor "#98c379" "" . wrap "[" "]"
            , ppVisible = xmobarColor "#61afef" ""
            , ppHidden = xmobarColor "#c678dd" "" . wrap "*" ""
            , ppHiddenNoWindows = xmobarColor "#666666" ""
            , ppTitle = xmobarColor "#abb2bf" "" . shorten 160
            , ppSep = "<fc=#666666> | </fc>"
            , ppUrgent = xmobarColor "#e06c75" "" . wrap "!" "!"
            }
        }
        `additionalKeysP`
        [ ("M-p", spawn myDmenuCommand)
        , ("M-S-l", spawn "xscreensaver-command -lock")
        -- Audio controls
        , ("<XF86AudioLowerVolume>", spawn "pactl set-sink-volume @DEFAULT_SINK@ -2%")
        , ("<XF86AudioRaiseVolume>", spawn "pactl set-sink-volume @DEFAULT_SINK@ +2%")
        , ("<XF86AudioMute>", spawn "pactl set-sink-mute @DEFAULT_SINK@ toggle")
        , ("<XF86AudioMicMute>", spawn "pactl set-source-mute @DEFAULT_SOURCE@ toggle")
        -- Custom shortcuts
        , ("M-t", spawn "xsel -o | python3 ~/.config/xmonad/my-scripts/tts.py")
        , ("M-S-s", sinkAll)
        , ("M-S-e", spawn "/home/passh/.config/emacs/bin/doom run")
        , ("M-i", spawn "$(which idea)")
        , ("M-ñ", spawn "~/.config/xmonad/my-scripts/toggle-keyboard-layout.sh")
        , ("M-;", spawn "~/.config/xmonad/my-scripts/toggle-keyboard-layout.sh")
        -- Scratchpads
        , ("M-a", namedScratchpadAction myScratchPads "terminal")
        , ("M-e", namedScratchpadAction myScratchPads "doom")
        , ("M-j", namedScratchpadAction myScratchPads "toolbox")
        , ("M-v", namedScratchpadAction myScratchPads "vpn-vocento")
        -- Utilities
        , ("<Print>", spawn "flameshot gui")
        , ("M-c", spawn "xfce4-popup-clipman")
        , ("M-s", goToSelected def)
        , ("M1-<Tab>", spawn "alttab -w 1 -d 0")
        , ("M-S-w", spawn "nitrogen --random --set-zoom-fill ~/wallpapers")
        , ("M-S-m", spawn " xwinwrap -ov -fs -- /nix/store/c2ln28b9rrjna70nrlj9b0ydrf92xhdc-xscreensaver-6.10.1/libexec/xscreensaver/glmatrix  -window-id WID --speed 1 --density 50 --mode matrix --fog --texture --delay 10000 &")
        -- Spacing controls
        , ("M-S-plus", incScreenWindowSpacing 2)
        , ("M-S-minus", decScreenWindowSpacing 2)
        ]
