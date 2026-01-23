# =============================================================================
# Crush AI Agent (Charmbracelet)
# =============================================================================
# Clone-first: Config symlinked from ~/dotfiles/crush/
#
# CONFIG (managed):
#   - crush.json (providers, models)
#
# Crush can use any provider: Ollama, Anthropic, OpenAI, etc.
# Config is shared across machines, edit ~/dotfiles/crush/.config/crush/crush.json
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
in

{
  # ===========================================================================
  # Configuration symlink
  # ===========================================================================
  # Using activation script because xdg.configFile doesn't respect mkOutOfStoreSymlink

  home.activation.setupCrush = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    echo "📁 Configurando crush..."

    # Create config directory
    mkdir -p ~/.config/crush

    # Remove nix store symlink if exists
    if [[ -L ~/.config/crush/crush.json ]] && [[ "$(readlink ~/.config/crush/crush.json)" == *"/nix/store/"* ]]; then
      echo "🧹 Limpiando symlink de nix store..."
      rm ~/.config/crush/crush.json
    fi

    # Create symlink to dotfiles (editable, not in store)
    if [[ ! -e ~/.config/crush/crush.json ]]; then
      echo "🔗 Creando symlink: crush.json -> dotfiles"
      ln -sf "${dotfilesDir}/crush/.config/crush/crush.json" ~/.config/crush/crush.json
    fi
  '';
}
