# =============================================================================
# AI Agents Configuration (claude-code, opencode, etc.)
# =============================================================================
# Clone-first: Same config across ALL machines (aurin, macbook, vespino)
#
# This module manages AI agent configurations in a portable way.
# Config is symlinked from dotfiles/ to avoid duplication.
#
# CURRENTLY MANAGED:
#   - claude-code: ACTIVE (replaces stow)
#   - opencode: ACTIVE (branch opencode, WIP)
#
# STATE vs CONFIG:
#   Claude-code:
#     - Config (managed): settings.json, CLAUDE.md, agents/, skills/
#     - State (not managed): .claude.json, history.jsonl, debug/, etc.
#   OpenCode:
#     - Config (managed): package.json (plugins)
#     - State (not managed): ~/.local/share/opencode/ (auth, sessions, storage)
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
  # Claude Code - Configuration symlinks
  # ===========================================================================

  home.file = {
    ".claude/settings.json".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/claude-code/.claude/settings.json";

    ".claude/CLAUDE.md".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/claude-code/.claude/CLAUDE.md";

    ".claude/agents".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/claude-code/.claude/agents";

    ".claude/skills".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/claude-code/.claude/skills";
  };

  # ===========================================================================
  # Claude Code - State directories (runtime, not managed by Nix)
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

  # ===========================================================================
  # OpenCode - Plugin Configuration
  # ===========================================================================
  # OpenCode uses TypeScript plugins, configured via package.json.
  # State (auth, sessions) is kept in ~/.local/share/opencode/ (not managed).

  home.file.".config/opencode/package.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/opencode/.config/opencode/package.json";

  # ===========================================================================
  # OpenCode - State directories (runtime, not managed by Nix)
  # ===========================================================================
  # These directories contain:
  # - auth.json: OAuth credentials (Anthropic, etc.)
  # - storage/: Sessions, messages, diffs, todos, projects

  home.activation.createOpencodeState = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    echo "📁 Creando directorios de estado para opencode..."
    mkdir -p ~/.local/share/opencode/storage/{session,message,session_diff,todo,project,part}

    # Note: auth.json will be created by 'opencode auth login' (manual setup)
    if [[ ! -f ~/.local/share/opencode/auth.json ]]; then
      echo "⚠️  OpenCode: Run 'opencode auth login' to authenticate"
    fi
  '';

  # ===========================================================================
  # Install OpenCode package
  # ===========================================================================

  home.packages = with pkgs; [
    opencode # Available in nixpkgs 1.1.23
  ];
}
