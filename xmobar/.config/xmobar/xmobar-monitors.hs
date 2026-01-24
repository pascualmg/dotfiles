Config {
    font = "HeavyData Nerd Font 22"
    , additionalFonts = [ "HeavyData Nerd Font 26" ]
    , bgColor = "#1e2127"
    , fgColor = "#abb2bf"
    , alpha = 255
    , position = BottomH 39
    , lowerOnStart = True
    , allDesktops = True
    , overrideRedirect = True
    , persistent = True

    , commands = [
        Run Com "/home/passh/dotfiles/scripts/xmobar-gpu-intel.sh" [] "gpu" 20
        , Run Com "/home/passh/dotfiles/scripts/xmobar-cpu-freq.sh" [] "cpufreq" 20
        , Run Com "/home/passh/dotfiles/scripts/xmobar-cpu.sh" [] "cpu" 20
        , Run Com "/home/passh/dotfiles/scripts/xmobar-memory.sh" [] "memory" 20
        , Run Com "/home/passh/dotfiles/scripts/xmobar-network.sh" [] "network" 10
        , Run Com "/home/passh/dotfiles/scripts/xmobar-docker.sh" [] "docker" 50
        , Run Com "/home/passh/dotfiles/scripts/xmobar-volume.sh" [] "volume" 10
        , Run Com "/home/passh/dotfiles/scripts/xmobar-disks.sh" [] "disks" 60
        , Run Com "/home/passh/dotfiles/scripts/xmobar-battery.sh" [] "battery" 50
        , Run Com "/home/passh/dotfiles/scripts/xmobar-hhkb-battery.sh" [] "hhkb" 60
    ]

    , sepChar = "%"
    , alignSep = "}{"
    , template = "}{ %docker% %volume% %battery% %hhkb% %network% %disks% %gpu% %memory% %cpufreq% %cpu% "
}
