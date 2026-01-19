# =============================================================================
# Nix-on-Droid Base Configuration (equivalente a modules/base para NixOS)
# =============================================================================
# Configuracion comun a TODOS los dispositivos Android.
# Para config especifica de dispositivo, ver droid/<hostname>/default.nix
# =============================================================================

{ pkgs, ... }:

{
  # Paquetes a nivel de sistema (disponibles globalmente)
  environment.packages = with pkgs; [
    # Esenciales
    openssh
    git
    vim

    # Utils
    coreutils
    gnugrep
    gnused
    gawk
    findutils
    which
    man
  ];

  # Configuracion de Nix
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  # Shell por defecto
  user.shell = "${pkgs.fish}/bin/fish";

  # Terminal styling (Solarized Dark)
  terminal = {
    font = "${pkgs.nerd-fonts.jetbrains-mono}/share/fonts/truetype/NerdFonts/JetBrainsMonoNerdFont-Regular.ttf";
    colors = {
      background = "#002b36";
      foreground = "#839496";
      cursor = "#93a1a1";
      color0 = "#073642";
      color1 = "#dc322f";
      color2 = "#859900";
      color3 = "#b58900";
      color4 = "#268bd2";
      color5 = "#d33682";
      color6 = "#2aa198";
      color7 = "#eee8d5";
      color8 = "#002b36";
      color9 = "#cb4b16";
      color10 = "#586e75";
      color11 = "#657b83";
      color12 = "#839496";
      color13 = "#6c71c4";
      color14 = "#93a1a1";
      color15 = "#fdf6e3";
    };
  };

  system.stateVersion = "24.05";
}
