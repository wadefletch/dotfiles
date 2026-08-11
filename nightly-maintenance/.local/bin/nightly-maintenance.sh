#!/bin/zsh
# Nightly macOS maintenance script

setopt pipe_fail

# launchd starts us with a bare PATH and `/` as its working directory. Give
# package managers a writable current directory and temporary directory.
export PNPM_HOME="$HOME/Library/pnpm"
export PATH="$HOME/.local/share/mise/shims:$PNPM_HOME/bin:$PNPM_HOME:/opt/homebrew/bin:$HOME/.cargo/bin:$PATH"
export TMPDIR="${TMPDIR:-/tmp}"

LOG="${NIGHTLY_MAINTENANCE_LOG:-/tmp/nightly-maintenance.log}"
CARGO_SWEEP="$HOME/.cargo/bin/cargo-sweep"
DEVELOPER="${NIGHTLY_MAINTENANCE_DEVELOPER:-$HOME/Developer}"
CODEX_WORKTREES="${NIGHTLY_MAINTENANCE_CODEX_WORKTREES:-$HOME/.codex/worktrees}"
CONSTELLATION="${NIGHTLY_MAINTENANCE_CONSTELLATION:-$DEVELOPER/Tractorbeam/constellation}"
DATA_VOLUME=/System/Volumes/Data
MIN_FREE_GIB="${NIGHTLY_MAINTENANCE_MIN_FREE_GIB:-150}"
DRY_RUN="${NIGHTLY_MAINTENANCE_DRY_RUN:-0}"

mkdir -p "$TMPDIR" || exit 1
cd "$HOME" || exit 1
exec >> "$LOG" 2>&1

integer failures=0

run_step() {
	local label="$1"
	shift

	echo "$label"
	if (( DRY_RUN )); then
		printf '  dry-run:'
		printf ' %q' "$@"
		printf '\n'
		return 0
	fi

	"$@"
	local step_status=$?
	if (( step_status != 0 )); then
		echo "  FAILED ($step_status): $label"
		(( failures += 1 ))
	fi
	return 0
}

available_kib() {
	df -k "$DATA_VOLUME" 2>/dev/null | awk 'NR == 2 { print $4 }'
}

format_gib() {
	awk -v kib="$1" 'BEGIN { printf "%.1f GiB", kib / 1024 / 1024 }'
}

worktree_is_active() {
	if ! command -v lsof >/dev/null 2>&1; then
		echo "  unable to inspect open files; treating $1 as active"
		return 0
	fi

	local output
	output="$(lsof -n -a +D "$1" 2>&1)"
	local result=$?
	if (( result == 1 )) && [[ -z "$output" ]]; then
		return 1
	fi
	if (( result != 0 )); then
		echo "  unable to inspect $1; treating it as active: $output"
		return 0
	fi

	[[ -n "$(printf '%s\n' "$output" | sed -n '2p')" ]]
}

update_fleetctl() {
	if ! command -v pnpm >/dev/null 2>&1; then
		echo "  pnpm not on PATH, skipping fleetctl update"
		return 0
	fi

	mkdir -p "$PNPM_HOME/bin" || return
	pnpm add --global fleetctl@latest || return
	"$PNPM_HOME/bin/fleetctl" --version
}

prune_pnpm_store() {
	if ! command -v pnpm >/dev/null 2>&1; then
		echo "  pnpm not on PATH, skipping store prune"
		return 0
	fi
	pnpm store prune
}

prune_uv_cache() {
	if ! command -v uv >/dev/null 2>&1; then
		echo "  uv not on PATH, skipping cache prune"
		return 0
	fi
	uv cache prune
}

prune_mise_tools() {
	if ! command -v mise >/dev/null 2>&1; then
		echo "  mise not on PATH, skipping tool prune"
		return 0
	fi
	mise prune --tools --yes
}

clean_merged_constellation_targets() {
	[[ -d "$CONSTELLATION" ]] || return 0

	git -C "$CONSTELLATION" fetch --quiet origin main 2>/dev/null || return

	local -a worktrees
	worktrees=("${(@f)$(git -C "$CONSTELLATION" worktree list --porcelain | awk '/^worktree / { print substr($0, 10) }')}")

	local worktree branch target
	integer cleanup_failed=0
	for worktree in "${worktrees[@]}"; do
		target="$worktree/target"
		[[ -d "$target" ]] || continue

		branch="$(git -C "$worktree" symbolic-ref --quiet --short HEAD 2>/dev/null)"
		[[ -n "$branch" && "$branch" != main ]] || continue

		if worktree_is_active "$worktree"; then
			echo "  active: skipping $target"
			continue
		fi

		if [[ "$(git -C "$CONSTELLATION" rev-list --count "origin/main..$branch" 2>/dev/null)" == 0 ]]; then
			echo "  merged: removing $target"
			if (( ! DRY_RUN )); then
				rm -rf -- "$target" || cleanup_failed=1
			fi
		fi
	done

	return cleanup_failed
}

sweep_inactive_rust_targets() {
	if [[ ! -x "$CARGO_SWEEP" ]]; then
		echo "  cargo-sweep not installed at $CARGO_SWEEP"
		return 127
	fi

	local -a search_roots targets
	[[ -d "$DEVELOPER" ]] && search_roots+=("$DEVELOPER")
	[[ -d "$CODEX_WORKTREES" ]] && search_roots+=("$CODEX_WORKTREES")
	(( ${#search_roots} > 0 )) || return 0

	# Find target directories directly instead of sweeping an entire tree. This
	# lets us conservatively skip every repository with any open file or cwd.
	targets=("${(@f)$(find "${search_roots[@]}" -type d \( -name .git -o -name node_modules -o -name .pnpm-store -o -name .venv -o -name vendor \) -prune -o -type d -name target -print -prune 2>/dev/null)}")

	typeset -A seen_projects
	local target project scope
	integer sweep_failed=0
	for target in "${targets[@]}"; do
		[[ -n "$target" ]] || continue
		project="${target:h}"
		[[ -f "$project/Cargo.toml" ]] || continue
		[[ -z "${seen_projects[$project]}" ]] || continue
		seen_projects[$project]=1

		scope="$(git -C "$project" rev-parse --show-toplevel 2>/dev/null)"
		[[ -n "$scope" ]] || scope="$project"
		if worktree_is_active "$scope"; then
			echo "  active: skipping $target"
			continue
		fi

		echo "  sweeping artifacts unused for 14 days: $target"
		if (( ! DRY_RUN )); then
			"$CARGO_SWEEP" sweep --time 14 "$project" || sweep_failed=1
		fi
	done

	return sweep_failed
}

echo "=== Nightly Maintenance: $(date) ==="
echo "Starting disk space: $(df -h "$DATA_VOLUME" | awk 'NR == 2 { print $4 " available (" $5 " used)" }')"

if [[ "$MIN_FREE_GIB" != <-> ]]; then
	echo "Invalid NIGHTLY_MAINTENANCE_MIN_FREE_GIB: $MIN_FREE_GIB"
	MIN_FREE_GIB=150
	(( failures += 1 ))
fi

integer before_kib="$(available_kib)"
integer threshold_kib=$(( MIN_FREE_GIB * 1024 * 1024 ))

run_step "Updating Homebrew..." brew update
run_step "Upgrading Homebrew packages..." brew upgrade
run_step "Cleaning Homebrew caches..." brew cleanup --prune=all
run_step "Pruning unused mise tool versions..." prune_mise_tools
run_step "Updating fleetctl..." update_fleetctl

if (( before_kib < threshold_kib )); then
	echo "Disk cleanup enabled: $(format_gib "$before_kib") is below ${MIN_FREE_GIB} GiB"
	run_step "Pruning pnpm store..." prune_pnpm_store
	run_step "Pruning uv cache..." prune_uv_cache
	run_step "Reclaiming merged constellation worktree targets..." clean_merged_constellation_targets
	run_step "Sweeping inactive Rust targets..." sweep_inactive_rust_targets
else
	echo "Disk cleanup skipped: $(format_gib "$before_kib") meets the ${MIN_FREE_GIB} GiB threshold"
fi

integer after_kib="$(available_kib)"
integer reclaimed_kib=$(( after_kib - before_kib ))
echo "Final disk space: $(df -h "$DATA_VOLUME" | awk 'NR == 2 { print $4 " available (" $5 " used)" }')"
echo "Net disk change: $(format_gib "$reclaimed_kib")"

if (( failures > 0 )); then
	echo "=== Maintenance completed with $failures failed step(s) ==="
	exit 1
fi

echo "=== Maintenance complete ==="
