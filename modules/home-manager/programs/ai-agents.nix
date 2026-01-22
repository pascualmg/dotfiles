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
#   - opencode: EXPERIMENTAL (commented out, enable after investigation)
#
# STATE vs CONFIG:
#   - Config (managed): settings.json, CLAUDE.md, agents/, skills/
#   - State (not managed): .claude.json, history.jsonl, debug/, etc.
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
  # OpenCode - EXPERIMENTAL (disabled by default)
  # ===========================================================================
  # Uncomment after FASE 0 investigation to enable opencode integration.
  #
  # home.file.".config/opencode/config.json".source =
  #   config.lib.file.mkOutOfStoreSymlink
  #   "${dotfilesDir}/opencode/.opencode/config.json";
  #
  # home.activation.setupOpencode = lib.hm.dag.entryAfter ["writeBoundary"] ''
  #   # TODO: Configure opencode based on investigation findings
  #   SHARED_DIR="${config.xdg.configHome}/ai-agents"
  #   echo "⚠️  OpenCode config: Pending FASE 0 investigation"
  # '';
}
