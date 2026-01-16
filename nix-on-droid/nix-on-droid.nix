# =============================================================================
# Nix-on-Droid System Configuration
# =============================================================================
# Configuracion del sistema Nix-on-Droid (equivalente a configuration.nix).
# Home Manager se integra via el flake.
#
# Uso: nix-on-droid switch --flake ~/dotfiles
#
# NOTA: Este archivo configura el SISTEMA Nix-on-Droid.
#       La config de usuario esta en modules/home-manager/machines/android.nix
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
  nix = {
    # Habilitar flakes
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  # Shell por defecto
  user.shell = "${pkgs.fish}/bin/fish";

  # Terminal styling
  terminal = {
    font = "${pkgs.nerdfonts.override { fonts = [ "JetBrainsMono" ]; }}/share/fonts/truetype/NerdFonts/JetBrainsMonoNerdFont-Regular.ttf";
    colors = {
      # Solarized Dark theme
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

  # Stateversion - no cambiar una vez configurado
  system.stateVersion = "24.05";
}
