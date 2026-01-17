# =============================================================================
# HOME-MANAGER: Alacritty Terminal Emulator
# =============================================================================
# Configuración de Alacritty con soporte para cambio de temas en caliente
#
# Parámetros configurables:
#   - fontSize: Tamaño de fuente (14 para aurin, 18-20 para macbook HiDPI)
#   - defaultTheme: Tema por defecto (spacemacs-dark, catppuccin_mocha, etc.)
#
# Cambiar tema en caliente:
#   alacritty-theme dark
#   alacritty-theme light
#   alacritty-theme commodore
#   alacritty-theme list
# =============================================================================

{ config, lib, pkgs, alacritty-themes, ... }:

let
  cfg = config.dotfiles.alacritty;

  # Directorio de temas del flake input (comunidad)
  themesSource = "${alacritty-themes}/themes";

  # Temas custom del dotfiles (editables)
  customThemesSource = ../../../alacritty/themes/custom;

  # Config base de Alacritty (sin colores) - se genera como archivo
  alacrittyBaseConfig = ''
    # Alacritty Configuration
    # Theme loaded dynamically - use 'alacritty-theme' to change

    [env]
    COLORTERM = "truecolor"

    [window]
    padding = { x = 2, y = 2 }
    dynamic_padding = true
    decorations = "full"
    startup_mode = "Windowed"
    title = "Alacritty"
    dynamic_title = true

    [scrolling]
    history = 10000
    multiplier = 3

    [font]
    size = ${toString cfg.fontSize}

    [font.normal]
    family = "Hack Nerd Font"
    style = "Regular"

    [font.bold]
    family = "Hack Nerd Font"
    style = "Bold"

    [font.italic]
    family = "Hack Nerd Font"
    style = "Italic"

    [font.bold_italic]
    family = "Hack Nerd Font"
    style = "Bold Italic"

    [cursor]
    style = "Block"
    unfocused_hollow = false

    [[keyboard.bindings]]
    key = "Copy"
    mods = "Control"
    action = "Copy"

    [[keyboard.bindings]]
    key = "Paste"
    mods = "Control"
    action = "Paste"

    [mouse]
    hide_when_typing = true

    [selection]
    save_to_clipboard = true

    # === THEME COLORS (auto-generated) ===
  '';

  # Script para cambiar temas - reescribe alacritty.toml completo
  alacrittyThemeScript = pkgs.writeShellScriptBin "alacritty-theme" ''
    set -euo pipefail
    shopt -s nullglob

    THEMES_DIR="$HOME/.config/alacritty/themes"
    CONFIG="$HOME/.config/alacritty/alacritty.toml"
    BASE="$HOME/.config/alacritty/base.toml"
    STATE_FILE="$THEMES_DIR/.current_theme"
    LIGHT_THEME="spacemacs-light"
    DARK_THEME="spacemacs-dark"

    usage() {
      cat <<EOF
    Usage: alacritty-theme <command>

    Commands:
      dark     - Switch to dark theme
      light    - Switch to light theme
      next     - Cycle to next theme
      list     - List available themes
      current  - Show current theme
      <name>   - Switch to specific theme

    Examples:
      alacritty-theme dark
      alacritty-theme commodore
    EOF
    }

    get_all_themes() {
      for f in "$THEMES_DIR/custom"/*.toml; do
        basename "$f" .toml
      done
      for f in "$THEMES_DIR"/*.toml; do
        basename "$f" .toml
      done
    }

    list_themes() {
      echo "=== Custom themes ==="
      for f in "$THEMES_DIR/custom"/*.toml; do
        basename "$f" .toml
      done
      echo ""
      echo "=== Community themes (first 30) ==="
      for f in "$THEMES_DIR"/*.toml; do
        basename "$f" .toml
      done | head -30
      echo "..."
    }

    show_current() {
      [[ -f "$STATE_FILE" ]] && cat "$STATE_FILE" || echo "unknown"
    }

    set_theme() {
      local theme="$1"
      local theme_file=""

      if [[ -f "$THEMES_DIR/custom/$theme.toml" ]]; then
        theme_file="$THEMES_DIR/custom/$theme.toml"
      elif [[ -f "$THEMES_DIR/$theme.toml" ]]; then
        theme_file="$THEMES_DIR/$theme.toml"
      else
        echo "Error: Theme '$theme' not found"
        exit 1
      fi

      # Concatenar base + tema y escribir config completa
      cat "$BASE" "$theme_file" > "$CONFIG"
      echo "$theme" > "$STATE_FILE"
      echo "Switched to: $theme"
    }

    next_theme() {
      local -a themes
      mapfile -t themes < <(get_all_themes)
      local count=''${#themes[@]}

      [[ $count -eq 0 ]] && { echo "No themes"; exit 1; }

      local current=$(show_current)
      local idx=0
      for i in "''${!themes[@]}"; do
        [[ "''${themes[$i]}" == "$current" ]] && { idx=$i; break; }
      done
      idx=$(( (idx + 1) % count ))

      set_theme "''${themes[$idx]}"
    }

    case "''${1:-}" in
      ""|"-h"|"--help") usage ;;
      "dark")    set_theme "$DARK_THEME" ;;
      "light")   set_theme "$LIGHT_THEME" ;;
      "next")    next_theme ;;
      "list")    list_themes ;;
      "current") show_current ;;
      *)         set_theme "$1" ;;
    esac
  '';
in
{
  options.dotfiles.alacritty = {
    fontSize = lib.mkOption {
      type = lib.types.number;
      default = 14;
      description = "Font size for Alacritty terminal";
    };

    defaultTheme = lib.mkOption {
      type = lib.types.str;
      default = "spacemacs-dark";
      description = "Default theme name";
    };
  };

  config = {
    home.packages = [ alacrittyThemeScript ];

    # NO usar programs.alacritty - generamos el archivo manualmente
    # para permitir hot-reload real

    xdg.configFile = {
      # Config base (sin colores)
      "alacritty/base.toml" = {
        text = alacrittyBaseConfig;
      };

      # Temas de la comunidad
      "alacritty/themes" = {
        source = themesSource;
        recursive = true;
      };

      # Temas custom (desde archivos editables en el dotfiles)
      "alacritty/themes/custom" = {
        source = customThemesSource;
        recursive = true;
      };
    };

    # Inicializar alacritty.toml con tema por defecto
    # Debe correr DESPUÉS de linkGeneration para que base.toml exista
    home.activation.alacrittyInit = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      CONFIG="$HOME/.config/alacritty/alacritty.toml"
      BASE="$HOME/.config/alacritty/base.toml"
      THEMES_DIR="$HOME/.config/alacritty/themes"
      STATE_FILE="$THEMES_DIR/.current_theme"
      DEFAULT_THEME="${cfg.defaultTheme}"

      mkdir -p "$THEMES_DIR/custom"

      # Solo crear si no existe (preservar elección del usuario)
      if [ ! -f "$CONFIG" ] || [ ! -f "$STATE_FILE" ]; then
        if [ -f "$THEMES_DIR/custom/$DEFAULT_THEME.toml" ]; then
          cat "$BASE" "$THEMES_DIR/custom/$DEFAULT_THEME.toml" > "$CONFIG"
        elif [ -f "$THEMES_DIR/$DEFAULT_THEME.toml" ]; then
          cat "$BASE" "$THEMES_DIR/$DEFAULT_THEME.toml" > "$CONFIG"
        fi
        echo "$DEFAULT_THEME" > "$STATE_FILE"
      fi
    '';
  };
}
