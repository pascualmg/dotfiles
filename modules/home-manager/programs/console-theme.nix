# =============================================================================
# HOME-MANAGER: Console (TTY) Theme Switcher
# =============================================================================
# Permite cambiar el tema de colores de la consola TTY en caliente.
# Similar a alacritty-theme pero para el framebuffer.
#
# Uso:
#   console-theme dark      # Spacemacs Dark
#   console-theme light     # Spacemacs Light
#   console-theme commodore # CRT Phosphor Green
#   console-theme mix       # Spacemacs + Neon accents
#   console-theme list      # Listar temas
#
# NOTA: Solo funciona en TTY real (Ctrl+Alt+F1-F6), no en terminales gráficos.
# =============================================================================

{ config, lib, pkgs, ... }:

let
  # Temas de consola - 16 colores cada uno (formato: RRGGBB sin #)
  # Orden: black, red, green, yellow, blue, magenta, cyan, white,
  #        bright-black, bright-red, bright-green, bright-yellow,
  #        bright-blue, bright-magenta, bright-cyan, bright-white

  themes = {
    # Spacemacs Dark - El clásico oscuro con rosa característico
    spacemacs-dark = {
      colors = [
        "292b2e"  # 0: black (bg1)
        "f2241f"  # 1: red
        "67b11d"  # 2: green
        "b1951d"  # 3: yellow
        "4f97d7"  # 4: blue
        "a31db1"  # 5: magenta
        "2d9574"  # 6: cyan
        "b2b2b2"  # 7: white (base)
        "686868"  # 8: bright black
        "f2241f"  # 9: bright red
        "86dc2f"  # 10: bright green
        "e89e0f"  # 11: bright yellow (warning orange)
        "7590db"  # 12: bright blue
        "bc6ec5"  # 13: bright magenta (el rosa!)
        "28def0"  # 14: bright cyan
        "e3dedd"  # 15: bright white
      ];
      description = "Spacemacs Dark - Classic dark with purple accents";
    };

    # Spacemacs Light - Tema claro elegante
    spacemacs-light = {
      colors = [
        "fbf8ef"  # 0: black (bg1 - actually light!)
        "f2241f"  # 1: red
        "67b11d"  # 2: green
        "b1951d"  # 3: yellow
        "3a81c3"  # 4: blue
        "a31db1"  # 5: magenta
        "2d9574"  # 6: cyan
        "655370"  # 7: white (base - dark text)
        "a094a2"  # 8: bright black
        "f2241f"  # 9: bright red
        "42ae2c"  # 10: bright green
        "da8b55"  # 11: bright yellow
        "715ab1"  # 12: bright blue
        "6c3163"  # 13: bright magenta
        "21b8c7"  # 14: bright cyan
        "100a14"  # 15: bright white (dark!)
      ];
      description = "Spacemacs Light - Elegant light theme";
    };

    # Commodore CRT - Fósforo verde retro
    commodore = {
      colors = [
        "0a100a"  # 0: black
        "1f6b1f"  # 1: red -> dark green
        "33cc33"  # 2: green
        "5faf00"  # 3: yellow -> lime
        "2d8659"  # 4: blue -> teal
        "4a9c4a"  # 5: magenta -> sage
        "3cb371"  # 6: cyan -> sea green
        "33cc33"  # 7: white -> green
        "1a3318"  # 8: bright black
        "2e8b2e"  # 9: bright red -> forest
        "39ff14"  # 10: bright green (neon!)
        "7fff00"  # 11: bright yellow -> chartreuse
        "3cb371"  # 12: bright blue -> sea green
        "66cdaa"  # 13: bright magenta -> aquamarine
        "00fa9a"  # 14: bright cyan -> spring
        "39ff14"  # 15: bright white -> neon
      ];
      description = "Commodore CRT - P1 Phosphor Green Retro";
    };

    # Mix - Spacemacs base con acentos neón
    mix = {
      colors = [
        "1a1a2e"  # 0: black (más azulado que spacemacs)
        "ff2a6d"  # 1: red -> neon pink
        "05d9e8"  # 2: green -> cyan neon
        "f9c80e"  # 3: yellow -> golden
        "4f97d7"  # 4: blue (spacemacs)
        "bc6ec5"  # 5: magenta (spacemacs pink)
        "39ff14"  # 6: cyan -> neon green!
        "d1f7ff"  # 7: white -> ice
        "4a4a6a"  # 8: bright black
        "ff6b9d"  # 9: bright red -> soft pink
        "39ff14"  # 10: bright green -> NEON
        "ffe66d"  # 11: bright yellow
        "7590db"  # 12: bright blue (spacemacs)
        "ff2a6d"  # 13: bright magenta -> hot pink
        "05d9e8"  # 14: bright cyan -> electric
        "ffffff"  # 15: bright white
      ];
      description = "Synthwave Mix - Spacemacs meets Neon";
    };

    # Amber CRT - Para los nostálgicos del ámbar
    amber = {
      colors = [
        "0a0800"  # 0: black
        "ff6600"  # 1: red -> orange
        "ffb000"  # 2: green -> amber
        "ffd700"  # 3: yellow -> gold
        "cc8800"  # 4: blue -> dark amber
        "ff8c00"  # 5: magenta -> dark orange
        "ffcc00"  # 6: cyan -> yellow-amber
        "ffb000"  # 7: white -> amber
        "1a1200"  # 8: bright black
        "ff8c00"  # 9: bright red
        "ffc800"  # 10: bright green
        "ffe135"  # 11: bright yellow
        "ffaa00"  # 12: bright blue
        "ffcc66"  # 13: bright magenta
        "ffd966"  # 14: bright cyan
        "ffe4b5"  # 15: bright white
      ];
      description = "Amber CRT - Classic amber phosphor";
    };
  };

  # Generar el script
  consoleThemeScript = pkgs.writeShellScriptBin "console-theme" ''
    set -euo pipefail

    # Solo funciona en TTY real
    if [[ "$TERM" != "linux" ]]; then
      echo "Error: console-theme solo funciona en TTY (Ctrl+Alt+F1-F6)"
      echo "Para terminales gráficos usa: alacritty-theme"
      exit 1
    fi

    usage() {
      cat <<EOF
    Console Theme Switcher - Cambia colores de TTY en caliente

    Uso: console-theme <tema>

    Temas disponibles:
      dark       Spacemacs Dark - Classic dark with purple accents
      light      Spacemacs Light - Elegant light theme
      commodore  Commodore CRT - P1 Phosphor Green Retro
      mix        Synthwave Mix - Spacemacs meets Neon
      amber      Amber CRT - Classic amber phosphor

    Comandos:
      list       Listar temas disponibles
      current    Mostrar tema actual

    Ejemplos:
      console-theme dark
      console-theme commodore
    EOF
    }

    # Función para aplicar un tema (16 colores)
    apply_theme() {
      local -a colors=("$@")
      local i
      for i in {0..15}; do
        # Formato: \e]Pnrrggbb donde n es 0-F en hex
        printf '\e]P%X%s' "$i" "''${colors[$i]}"
      done
      # Limpiar pantalla para aplicar fondo
      clear
    }

    # Temas embebidos
    declare -A THEME_COLORS
    declare -A THEME_DESC

    THEME_COLORS[dark]="292b2e f2241f 67b11d b1951d 4f97d7 a31db1 2d9574 b2b2b2 686868 f2241f 86dc2f e89e0f 7590db bc6ec5 28def0 e3dedd"
    THEME_COLORS[light]="fbf8ef f2241f 67b11d b1951d 3a81c3 a31db1 2d9574 655370 a094a2 f2241f 42ae2c da8b55 715ab1 6c3163 21b8c7 100a14"
    THEME_COLORS[commodore]="0a100a 1f6b1f 33cc33 5faf00 2d8659 4a9c4a 3cb371 33cc33 1a3318 2e8b2e 39ff14 7fff00 3cb371 66cdaa 00fa9a 39ff14"
    THEME_COLORS[mix]="1a1a2e ff2a6d 05d9e8 f9c80e 4f97d7 bc6ec5 39ff14 d1f7ff 4a4a6a ff6b9d 39ff14 ffe66d 7590db ff2a6d 05d9e8 ffffff"
    THEME_COLORS[amber]="0a0800 ff6600 ffb000 ffd700 cc8800 ff8c00 ffcc00 ffb000 1a1200 ff8c00 ffc800 ffe135 ffaa00 ffcc66 ffd966 ffe4b5"

    THEME_DESC[dark]="Spacemacs Dark - Classic dark with purple accents"
    THEME_DESC[light]="Spacemacs Light - Elegant light theme"
    THEME_DESC[commodore]="Commodore CRT - P1 Phosphor Green Retro"
    THEME_DESC[mix]="Synthwave Mix - Spacemacs meets Neon"
    THEME_DESC[amber]="Amber CRT - Classic amber phosphor"

    STATE_FILE="/tmp/.console-theme-current"

    list_themes() {
      echo "Temas disponibles:"
      echo ""
      for theme in dark light commodore mix amber; do
        local current=""
        [[ -f "$STATE_FILE" ]] && [[ "$(cat "$STATE_FILE")" == "$theme" ]] && current=" (actual)"
        echo "  $theme - ''${THEME_DESC[$theme]}$current"
      done
    }

    show_current() {
      if [[ -f "$STATE_FILE" ]]; then
        cat "$STATE_FILE"
      else
        echo "unknown"
      fi
    }

    set_theme() {
      local theme="$1"

      if [[ -z "''${THEME_COLORS[$theme]:-}" ]]; then
        echo "Error: Tema '$theme' no encontrado"
        echo "Usa 'console-theme list' para ver temas disponibles"
        exit 1
      fi

      # Convertir string a array
      read -ra colors <<< "''${THEME_COLORS[$theme]}"

      apply_theme "''${colors[@]}"
      echo "$theme" > "$STATE_FILE"
      echo "Tema aplicado: $theme - ''${THEME_DESC[$theme]}"
    }

    case "''${1:-}" in
      ""|"-h"|"--help") usage ;;
      "list")    list_themes ;;
      "current") show_current ;;
      "dark"|"light"|"commodore"|"mix"|"amber") set_theme "$1" ;;
      *)
        echo "Error: Tema '$1' no reconocido"
        echo "Usa 'console-theme list' para ver temas disponibles"
        exit 1
        ;;
    esac
  '';

in
{
  config = {
    home.packages = [ consoleThemeScript ];
  };
}
