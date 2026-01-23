# =============================================================================
# AI Agents Suite - Modular Configuration
# =============================================================================
# Clone-first: All agents enabled by default on all machines.
# Each agent manages its own config symlinks from ~/dotfiles/
#
# CURRENT AGENTS:
#   - claude-code: Anthropic's Claude AI agent
#   - crush: Charmbracelet AI agent (multi-provider)
#   - opencode: Experimental AI agent
#
# ADDING NEW AGENTS:
#   1. Create new-agent.nix in this directory
#   2. Add import below
#   3. Agent config goes to ~/dotfiles/new-agent/
#   4. Done - will deploy to all machines
#
# PHILOSOPHY:
#   - No parametrization: config is in dotfiles/, not Nix options
#   - Simple symlinks: mkOutOfStoreSymlink for editable configs
#   - State vs Config: Nix manages config, runtime manages state
#   - Scalable: adding agents is trivial (create file + import)
# =============================================================================

{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./claude-code.nix
    ./crush.nix
    ./opencode.nix
  ];

  # No options needed - each agent is self-contained
  # If you need to disable an agent per-machine, comment the import above
}
