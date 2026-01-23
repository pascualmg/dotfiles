# =============================================================================
# Claude Code AI Agent
# =============================================================================
# Clone-first: Config symlinked from ~/dotfiles/claude-code/
#
# CONFIG (managed):
#   - settings.json, CLAUDE.md, agents/, skills/
#
# STATE (runtime, not managed):
#   - .claude.json, history.jsonl, debug/, cache/, etc.
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
  # Configuration symlinks
  # ===========================================================================
  # Using activation script because home.file doesn't respect mkOutOfStoreSymlink properly

  home.activation.setupClaudeCode = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    echo "📁 Configurando claude-code..."

    # Remove nix store symlinks if they exist
    for file in settings.json CLAUDE.md agents skills; do
      if [[ -L ~/.claude/$file ]] && [[ "$(readlink ~/.claude/$file)" == *"/nix/store/"* ]]; then
        echo "🧹 Limpiando symlink de nix store: $file"
        rm ~/.claude/$file
      fi
    done

    # Create symlinks to dotfiles (editable, not in store)
    if [[ ! -e ~/.claude/settings.json ]]; then
      ln -sf "${dotfilesDir}/claude-code/.claude/settings.json" ~/.claude/settings.json
    fi

    if [[ ! -e ~/.claude/CLAUDE.md ]]; then
      ln -sf "${dotfilesDir}/claude-code/.claude/CLAUDE.md" ~/.claude/CLAUDE.md
    fi

    if [[ ! -e ~/.claude/agents ]]; then
      ln -sf "${dotfilesDir}/claude-code/.claude/agents" ~/.claude/agents
    fi

    if [[ ! -e ~/.claude/skills ]]; then
      ln -sf "${dotfilesDir}/claude-code/.claude/skills" ~/.claude/skills
    fi
  '';

  # ===========================================================================
  # State directories (runtime, not managed by Nix)
  # ===========================================================================
  # These directories contain runtime state (history, cache, etc.)
  # We only ensure they exist, but don't manage their content.

  home.activation.createClaudeState = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    echo "📁 Creando directorios de estado para claude-code..."
    mkdir -p ~/.claude/{debug,file-history,session-env,todos,cache,projects,chrome,paste-cache,statsig,telemetry,plans,shell-snapshots}
  '';

  # ===========================================================================
  # Transition helper: Clean old stow symlinks
  # ===========================================================================
  # This removes symlinks created by stow to avoid conflicts.
  # Only runs once during the transition from stow to home-manager.

  home.activation.cleanOldClaudeStow = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    for link in ~/.claude/{settings.json,CLAUDE.md,agents,skills}; do
      if [[ -L "$link" ]] && [[ "$(readlink "$link")" == *"/dotfiles/claude-code/"* ]]; then
        echo "🧹 Limpiando symlink stow antiguo: $link"
        rm -f "$link"
      fi
    done
  '';
}
