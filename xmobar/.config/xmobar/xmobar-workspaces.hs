Config {
    font = "HeavyData Nerd Font 22"
    , additionalFonts = [ "HeavyData Nerd Font 26" ]
    , bgColor = "#282c34"
    , fgColor = "#abb2bf"
    , alpha = 255
    , position = TopH 39
    , lowerOnStart = True
    , allDesktops = True
    , overrideRedirect = True
    , persistent = True

    , commands = [
        Run Date "<action=`gsimplecal`><fn=1>\xf017</fn> %a %d %b %H:%M</action>" "date" 10
        , Run StdinReader
        -- Hardware (CPU/GPU)
        , Run Com "/home/passh/dotfiles/scripts/xmobar-gpu.sh" [] "gpu" 20
        , Run Com "/home/passh/dotfiles/scripts/xmobar-swap.sh" [] "swap" 30
        , Run Com "/home/passh/dotfiles/scripts/xmobar-memory.sh" [] "memory" 20
        , Run Com "/home/passh/dotfiles/scripts/xmobar-load.sh" [] "load" 20
        , Run Com "/home/passh/dotfiles/scripts/xmobar-cpu-freq.sh" [] "cpufreq" 20
        , Run Com "/home/passh/dotfiles/scripts/xmobar-cpu.sh" [] "cpu" 20
        , Run Com "/home/passh/dotfiles/scripts/xmobar-battery.sh" [] "battery" 50
    ]

    , sepChar = "%"
    , alignSep = "}{"
    , template = " %StdinReader% }{ %gpu% %swap% %memory% %load% %cpufreq% %cpu% %battery% %date% "
}
