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
        -- Estado/Servicios
        Run Com "/home/passh/dotfiles/scripts/xmobar-vpn.sh" [] "vpn" 30
        , Run Com "/home/passh/dotfiles/scripts/xmobar-docker.sh" [] "docker" 50
        , Run Com "/home/passh/dotfiles/scripts/xmobar-updates.sh" [] "updates" 3600
        , Run Com "/home/passh/dotfiles/scripts/xmobar-machines.sh" [] "machines" 60
        , Run Com "/home/passh/dotfiles/scripts/xmobar-ssh.sh" [] "ssh" 30
        -- Dispositivos
        , Run Com "/home/passh/dotfiles/scripts/xmobar-bluetooth.sh" [] "bt" 30
        , Run Com "/home/passh/dotfiles/scripts/xmobar-volume.sh" [] "volume" 10
        , Run Com "/home/passh/dotfiles/scripts/xmobar-brightness.sh" [] "bright" 30
        , Run Com "/home/passh/dotfiles/scripts/xmobar-hhkb-battery.sh" [] "hhkb" 60
        , Run Com "/home/passh/dotfiles/scripts/xmobar-hhkb-hasu.sh" [] "hhkbpro" 30
        , Run Com "/home/passh/dotfiles/scripts/xmobar-mouse-battery.sh" [] "mouse" 60
        -- Red
        , Run Com "/home/passh/dotfiles/scripts/xmobar-wifi.sh" [] "wifi" 30
        , Run Com "/home/passh/dotfiles/scripts/xmobar-network.sh" [] "network" 10
        -- Hardware (discos y uptime, el resto está arriba)
        , Run Com "/home/passh/dotfiles/scripts/xmobar-disks.sh" [] "disks" 60
        , Run Com "/home/passh/dotfiles/scripts/xmobar-uptime.sh" [] "uptime" 60
    ]

    , sepChar = "%"
    , alignSep = "}{"
    , template = "}{ <fc=#666666><fn=1>󱄅</fn></fc> %vpn% %docker% %updates% %machines% %ssh% %bt% %volume% %bright% %hhkb% %hhkbpro% %mouse% %wifi% %network% %disks% %uptime% <fc=#666666><fn=1>󱄅</fn></fc> "
}
