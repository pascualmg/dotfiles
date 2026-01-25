Config {
    -- Apariencia basica (Pango para soporte HiDPI correcto)
    font = "HeavyData Nerd Font 22"
    , additionalFonts = [ "HeavyData Nerd Font 26" ]
    , borderColor = "#282c34"
    , border = TopB
    , bgColor = "#282c34"
    , fgColor = "#abb2bf"
    , alpha = 255

    -- Posicionamiento (TopH = altura en pixels, calculada segun fontSize)
    , position = TopH 39
    , textOffset = 4
    , iconOffset = 4

    -- Comportamiento
    , lowerOnStart = True
    , allDesktops = True
    , overrideRedirect = True
    , persistent = True
    , hideOnStart = False

    -- Comandos y monitores
    , commands = [
        Run Com "/home/passh/dotfiles/scripts/xmobar-gpu.sh" [] "gpu" 20


        -- CPU frecuencia y governor (click abre cpupower-gui)
        ,Run Com "/home/passh/dotfiles/scripts/xmobar-cpu-freq.sh" [] "cpufreq" 20

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

        -- Volumen con color gradiente (script externo)
, Run Com "/home/passh/dotfiles/scripts/xmobar-volume.sh" [] "volume" 10


        -- Monitor de discos genérico (NVMe + SATA + USB)
, Run Com "/home/passh/dotfiles/scripts/xmobar-disks.sh" [] "disks" 60


        -- Bateria con color dinámico (script externo)
        , Run Com "/home/passh/dotfiles/scripts/xmobar-battery.sh" [] "battery" 50


        -- Raton wireless (Logitech hidpp)
        , Run Com "/home/passh/dotfiles/scripts/wireless-mouse.sh" [] "mouse" 100


        -- XMonad Workspaces y Layout
        , Run StdinReader

        
    ]

    -- Template
    -- LAYOUT: Izda (workspaces + fecha) | Dcha (menos importante → más importante)
    , sepChar = "%"
    , alignSep = "}{"
    , template = "%date% %StdinReader% }{ <fc=#555555><fn=1>󱄅</fn></fc> %docker% %volume% %mouse% %battery% %network% %disks% <fc=#555555><fn=1>󱄅</fn></fc> %gpu% <fc=#555555><fn=1>󱄅</fn></fc> %memory% %cpufreq% %cpu% "

}
