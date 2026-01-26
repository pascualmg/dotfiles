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
    ]

    , sepChar = "%"
    , alignSep = "}{"
    , template = " %StdinReader% }{ %date% "
}
