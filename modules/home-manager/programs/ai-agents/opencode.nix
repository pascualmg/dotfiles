# =============================================================================
# OpenCode AI Agent (EXPERIMENTAL)
# =============================================================================
# Clone-first: Config symlinked from ~/dotfiles/opencode/
#
# CONFIG (managed):
#   - package.json (TypeScript plugins)
#
# STATE (runtime, not managed):
#   - ~/.local/share/opencode/auth.json (OAuth credentials)
#   - ~/.local/share/opencode/storage/ (sessions, messages, diffs, todos)
#
# SETUP:
#   After enabling, run: opencode auth login
# =============================================================================

{
  config,
  lib,
  pkgs,
  ...
}:

let
  homeDir = config.home.homeDirectory;
  dotfilesDir = "${homeDir}/dotfiles";
  cfg = config.programs.aiAgents.opencode;
in

{
  # ===========================================================================
  # Module Options
  # ===========================================================================
  options.programs.aiAgents.opencode = {
    enable = lib.mkEnableOption "OpenCode AI agent" // {
      default = true; # Clone-first: enabled by default
    };
  };

  # ===========================================================================
  # Configuration
  # ===========================================================================
  config = lib.mkIf cfg.enable {

    # Install OpenCode package
    home.packages = with pkgs; [
      opencode
    ];

    # ===========================================================================
    # Plugin Configuration & State directories
    # ===========================================================================
    # OpenCode uses TypeScript plugins, configured via package.json.
    # State (auth, sessions) is kept in ~/.local/share/opencode/ (not managed).
    # Using activation script due to home.file.source not respecting mkOutOfStoreSymlink

    home.activation.setupOpencode = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      echo "📁 Configurando opencode..."

      # Create config directory
      mkdir -p ~/.config/opencode

      # Create symlink to dotfiles (editable, not in store)
      if [[ -L ~/.config/opencode/package.json ]] && [[ "$(readlink ~/.config/opencode/package.json)" == *"/nix/store/"* ]]; then
        echo "🧹 Limpiando symlink incorrecto de nix store..."
        rm ~/.config/opencode/package.json
      fi

      if [[ ! -e ~/.config/opencode/package.json ]]; then
        echo "🔗 Creando symlink: package.json -> dotfiles"
        ln -sf "${dotfilesDir}/opencode/.config/opencode/package.json" ~/.config/opencode/package.json
      fi

      # Create state directories
      mkdir -p ~/.local/share/opencode/storage/{session,message,session_diff,todo,project,part}

      # Note: auth.json will be created by 'opencode auth login' (manual setup)
      if [[ ! -f ~/.local/share/opencode/auth.json ]]; then
        echo "⚠️  OpenCode: Run 'opencode auth login' to authenticate"
      fi
    '';
  };
}
