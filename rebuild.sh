#!/usr/bin/env bash
# Wrapper for nixos-rebuild that auto-sets GIT_BRANCH for generation labels
#
# Usage:
#   ./rebuild.sh switch
#   ./rebuild.sh test
#   ./rebuild.sh boot

set -euo pipefail

# Detect hostname
HOSTNAME=$(hostname)

# Auto-detect branch from git
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export GIT_BRANCH=$(git -C "$DOTFILES_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

# Determine if we need --impure (aurin and vespino need it for Vocento hosts)
IMPURE_FLAG=""
if [[ "$HOSTNAME" == "aurin" ]] || [[ "$HOSTNAME" == "vespino" ]]; then
	IMPURE_FLAG="--impure"
fi

# Get rebuild command (default: switch)
COMMAND="${1:-switch}"

echo "=========================================="
echo "  NixOS Rebuild Wrapper"
echo "=========================================="
echo "Hostname:    $HOSTNAME"
echo "Branch:      $GIT_BRANCH"
echo "Command:     $COMMAND"
echo "Impure flag: ${IMPURE_FLAG:-none}"
echo "=========================================="
echo ""

# Run nixos-rebuild (use -E to preserve GIT_BRANCH environment variable)
sudo -E nixos-rebuild "$COMMAND" --flake "$DOTFILES_DIR#$HOSTNAME" $IMPURE_FLAG

echo ""
echo "✅ Rebuild complete!"
echo ""
echo "Latest generation:"
nixos-rebuild list-generations | head -n2
