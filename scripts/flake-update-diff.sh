#!/usr/bin/env bash
# flake-update-diff.sh - Complete flake update diff report
# Output designed for LLM processing (Ollama)
# Brutalist approach: verbose, complete, unfiltered

set -euo pipefail

# Config
DOTFILES_DIR="$HOME/dotfiles"
PROFILES_DIR="/nix/var/nix/profiles"

# Colors (only for headers, keep data raw)
RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'

# Print separator line
print_separator() {
	echo "================================================================================"
}

# Print section header
print_section() {
	local title="$1"
	echo ""
	echo "--------------------------------------------------------------------------------"
	echo "$title"
	echo "--------------------------------------------------------------------------------"
}

# Get system profile information
get_profile_info() {
	local profiles=()

	# Get last 2 system profiles
	while IFS= read -r profile; do
		profiles+=("$profile")
	done < <(ls -td "$PROFILES_DIR"/system-*-link 2>/dev/null | head -2)

	if [ ${#profiles[@]} -lt 2 ]; then
		echo "Error: No se encontraron suficientes perfiles del sistema" >&2
		exit 1
	fi

	PROFILE_NEW="${profiles[0]}"
	PROFILE_OLD="${profiles[1]}"

	# Extract profile numbers
	PROFILE_NUM_NEW=$(basename "$PROFILE_NEW" | sed 's/system-\([0-9]*\)-link/\1/')
	PROFILE_NUM_OLD=$(basename "$PROFILE_OLD" | sed 's/system-\([0-9]*\)-link/\1/')
}

# Convert timestamp to human readable date
ts_to_date() {
	date -d "@$1" '+%Y-%m-%d %H:%M' 2>/dev/null || echo "unknown"
}

# Calculate days difference between two timestamps
days_diff() {
	local ts1=$1
	local ts2=$2
	local diff_seconds=$((ts2 - ts1))
	local diff_days=$((diff_seconds / 86400))
	local diff_hours=$(((diff_seconds % 86400) / 3600))

	if [ $diff_days -gt 0 ]; then
		echo "+${diff_days} days"
	elif [ $diff_hours -gt 0 ]; then
		echo "+${diff_hours} hours"
	else
		echo "+${diff_seconds} seconds"
	fi
}

# Diff flake inputs
diff_flake_inputs() {
	print_section "FLAKE INPUTS CHANGES"

	cd "$DOTFILES_DIR" || exit 1

	# Check if flake.lock changed
	if ! git diff HEAD~1 flake.lock &>/dev/null; then
		echo "Warning: No git history for flake.lock comparison"
		return
	fi

	# Get old and new flake.lock
	local old_lock=$(git show HEAD~1:flake.lock 2>/dev/null)
	local new_lock=$(cat flake.lock)

	# Main inputs to track
	local inputs=("home-manager" "nixpkgs_2" "nixpkgs-master" "nixos-hardware" "nixpkgs")
	local input_names=("home-manager" "nixpkgs (nixos-unstable)" "nixpkgs-master" "nixos-hardware" "nixpkgs (charm-nur)")

	for i in "${!inputs[@]}"; do
		local input="${inputs[$i]}"
		local display_name="${input_names[$i]}"

		# Extract old values
		local old_rev=$(echo "$old_lock" | jq -r ".nodes.\"$input\".locked.rev // empty" 2>/dev/null)
		local old_ts=$(echo "$old_lock" | jq -r ".nodes.\"$input\".locked.lastModified // empty" 2>/dev/null)

		# Extract new values
		local new_rev=$(echo "$new_lock" | jq -r ".nodes.\"$input\".locked.rev // empty" 2>/dev/null)
		local new_ts=$(echo "$new_lock" | jq -r ".nodes.\"$input\".locked.lastModified // empty" 2>/dev/null)

		# Skip if input doesn't exist or hasn't changed
		if [ -z "$old_rev" ] || [ -z "$new_rev" ]; then
			continue
		fi

		if [ "$old_rev" != "$new_rev" ]; then
			echo ""
			echo "Input: $display_name"
			echo "  Old: ${old_rev:0:8} ($(ts_to_date "$old_ts"))"
			echo "  New: ${new_rev:0:8} ($(ts_to_date "$new_ts"))"
			echo "  Diff: $(days_diff "$old_ts" "$new_ts")"
		fi
	done
}

# Get full system closure diff
diff_closures_full() {
	print_section "SYSTEM CLOSURE DIFF (FULL)"

	echo "Comparing:"
	echo "  Old: $PROFILE_OLD (system-$PROFILE_NUM_OLD-link)"
	echo "  New: $PROFILE_NEW (system-$PROFILE_NUM_NEW-link)"
	echo ""

	# Run full diff-closures
	nix store diff-closures "$PROFILE_OLD" "$PROFILE_NEW"
}

# Calculate summary stats from diff
calculate_summary() {
	print_section "SUMMARY"

	# Re-run diff and parse for stats
	local diff_output=$(nix store diff-closures "$PROFILE_OLD" "$PROFILE_NEW" 2>/dev/null)

	# Count changes
	local total_lines=$(echo "$diff_output" | wc -l)
	local added=$(echo "$diff_output" | grep -c "∅ →" || true)
	local removed=$(echo "$diff_output" | grep -c "→ ∅" || true)
	local updated=$((total_lines - added - removed))

	echo "Total entries: $total_lines"
	echo "Added: $added packages"
	echo "Removed: $removed packages"
	echo "Updated: $updated packages"

	# Try to calculate total size change (rough estimation)
	# Extract all size changes and sum them
	local size_kb=0
	while IFS= read -r line; do
		# Extract KiB values (both + and -)
		if [[ $line =~ ([+-])([0-9]+\.[0-9]+)\ KiB ]]; then
			local sign="${BASH_REMATCH[1]}"
			local value="${BASH_REMATCH[2]}"
			local kb=$(echo "$value" | cut -d. -f1)
			if [ "$sign" = "+" ]; then
				size_kb=$((size_kb + kb))
			else
				size_kb=$((size_kb - kb))
			fi
		fi
	done <<<"$diff_output"

	# Convert to MB
	local size_mb=$((size_kb / 1024))

	if [ $size_mb -gt 0 ]; then
		echo "Approximate size change: +${size_mb} MB"
	elif [ $size_mb -lt 0 ]; then
		echo "Approximate size change: ${size_mb} MB"
	else
		echo "Approximate size change: ~0 MB"
	fi
}

# Main function
main() {
	# Header
	print_separator
	echo "FLAKE UPDATE DIFF REPORT"
	print_separator
	echo "Hostname: $(hostname)"
	echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"

	# Git info
	cd "$DOTFILES_DIR" || exit 1
	local git_commit=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
	local git_dirty=""
	if ! git diff-index --quiet HEAD 2>/dev/null; then
		git_dirty=" (dirty)"
	fi
	echo "Dotfiles commit: ${git_commit}${git_dirty}"

	# Get profiles
	get_profile_info
	echo "System profiles: $PROFILE_NUM_OLD → $PROFILE_NUM_NEW"

	# Sections
	diff_flake_inputs
	diff_closures_full
	calculate_summary

	# Footer
	echo ""
	print_separator
	echo "END OF REPORT"
	print_separator
}

# Run
main "$@"
