# =============================================================================
# HOME-MANAGER: Emacs Smart Wrapper (X11/Wayland)
# =============================================================================
# Solucion al problema del warning de emacs-pgtk en X11.
#
# PROBLEMA:
#   emacs-pgtk muestra un warning molesto cuando se ejecuta en X11:
#   "You are trying to run Emacs configured with the 'pure-GTK' interface
#    under the X Window System..."
#   Los desarrolladores de Emacs NO permiten deshabilitar este warning.
#
# SOLUCION:
#   Instalar AMBOS emacs (X11) y emacs-pgtk (Wayland), y crear un wrapper
#   inteligente que detecta el entorno y ejecuta el binario apropiado.
#
# COMO FUNCIONA:
#   1. Detecta XDG_SESSION_TYPE (wayland, x11, o tty)
#   2. Ejecuta emacs-pgtk en Wayland, emacs normal en X11
#   3. El wrapper se llama 'emacs' y va primero en el PATH
#   4. emacsclient sigue funcionando igual (conecta al daemon activo)
#
# USO:
#   # En XMonad (X11):
#   emacs --daemon    # Ejecuta emacs (X11), sin warning
#   emacsclient -c    # Conecta al daemon
#
#   # En GNOME/Hyprland (Wayland):
#   emacs --daemon    # Ejecuta emacs-pgtk, soporte nativo Wayland
#   emacsclient -c    # Conecta al daemon
#
# CONFIGURACION en machines/{aurin,macbook}.nix:
#   dotfiles.emacs.enable = true;  # Activar wrapper (default: true)
#
# NOTA: Este modulo reemplaza la instalacion directa de emacs-pgtk en passh.nix
# =============================================================================

{ config, lib, pkgs, ... }:

let
  cfg = config.dotfiles.emacs;

  # Wrapper script que detecta el entorno y ejecuta el Emacs apropiado
  emacs-smart = pkgs.writeShellScriptBin "emacs" ''
    # emacs-smart: wrapper inteligente para X11/Wayland
    # Detecta el entorno grafico y ejecuta el binario apropiado

    case "''${XDG_SESSION_TYPE:-tty}" in
      wayland)
        # Wayland: usar emacs-pgtk para soporte nativo
        exec ${pkgs.emacs-pgtk}/bin/emacs "$@"
        ;;
      x11|tty|*)
        # X11 o TTY: usar emacs normal (evita warning de pgtk)
        exec ${pkgs.emacs}/bin/emacs "$@"
        ;;
    esac
  '';

in
{
  # ---------------------------------------------------------------------------
  # OPTIONS
  # ---------------------------------------------------------------------------
  options.dotfiles.emacs = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Enable smart Emacs wrapper that auto-detects X11/Wayland.
        When enabled, 'emacs' command will use emacs-pgtk on Wayland
        and regular emacs on X11 (avoiding the pgtk warning).
      '';
    };
  };

  # ---------------------------------------------------------------------------
  # CONFIG
  # ---------------------------------------------------------------------------
  config = lib.mkIf cfg.enable {
    home.packages = [
      # Solo el wrapper - referencia los binarios directamente por su path en nix store
      # Esto evita conflictos de PATH (ambos emacs tienen /bin/emacs)
      emacs-smart

      # emacsclient lo necesitamos en el PATH (solo uno, son identicos)
      # Usamos un wrapper que referencia el de pkgs.emacs
      (pkgs.writeShellScriptBin "emacsclient" ''
        exec ${pkgs.emacs}/bin/emacsclient "$@"
      '')
    ];

    # Variables de entorno para Emacs
    home.sessionVariables = {
      EDITOR = "emacsclient -c -a emacs";
      VISUAL = "emacsclient -c -a emacs";
      # Asegurar que el wrapper esta primero en PATH
      # (home.packages ya lo hace, pero esto es explicito)
    };
  };
}
