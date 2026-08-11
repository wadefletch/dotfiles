#!/bin/zsh
# Nightly macOS maintenance script

setopt pipe_fail

# Schedulers provide a minimal PATH, so set tool and temporary paths explicitly.
export PNPM_HOME="$HOME/Library/pnpm"
export PATH="$HOME/.local/share/mise/shims:$PNPM_HOME/bin:$PNPM_HOME:/opt/homebrew/bin:$HOME/.cargo/bin:$PATH"
export TMPDIR="${TMPDIR:-/tmp}"

LOG=/tmp/nightly-maintenance.log
LOG_MAX_BYTES=10485760
CARGO_SWEEP="$HOME/.cargo/bin/cargo-sweep"
DEVELOPER="$HOME/Developer"
CODEX_WORKTREES="$HOME/.codex/worktrees"
CONSTELLATION="$DEVELOPER/Tractorbeam/constellation"
DATA_VOLUME=/System/Volumes/Data
MIN_FREE_GIB=150

mkdir -p "$TMPDIR" || exit 1
cd "$HOME" || exit 1
if [[ -f "$LOG" ]]; then
	log_size="$(stat -f %z "$LOG" 2>/dev/null)"
	if [[ "$log_size" == <-> ]] && (( log_size > LOG_MAX_BYTES )); then
		mv -f -- "$LOG" "$LOG.1" || exit 1
	fi
fi
exec >> "$LOG" 2>&1

integer failures=0
typeset -A active_worktrees

run_step() {
	local label="$1"
	shift

	echo "$label"
	"$@"
	local step_status=$?
	if (( step_status != 0 )); then
		echo "  FAILED ($step_status): $label"
		(( failures += 1 ))
	fi
	return 0
}

measure_available_kib() {
	local value
	value="$(df -k "$DATA_VOLUME" | awk 'NR == 2 { print $4 }')"
	local measure_status=$?
	if (( measure_status != 0 )) || [[ "$value" != <-> ]]; then
		echo "Unable to measure available space on $DATA_VOLUME" >&2
		return 1
	fi
	print -r -- "$value"
}

format_gib() {
	awk -v kib="$1" 'BEGIN { printf "%.1f GiB", kib / 1024 / 1024 }'
}

worktree_is_active() {
	local scope="${1:A}"
	if [[ "${active_worktrees[$scope]}" == 1 ]]; then
		return 0
	fi

	if ! command -v lsof >/dev/null 2>&1; then
		echo "  unable to inspect open files; treating $scope as active"
		active_worktrees[$scope]=1
		return 0
	fi

	local output
	output="$(lsof -n -t -a +D "$scope" 2>&1)"
	local result=$?
	if [[ -n "$output" ]]; then
		if [[ "$output" != <->* ]]; then
			echo "  unable to inspect $scope; treating it as active: $output"
		fi
		active_worktrees[$scope]=1
		return 0
	elif (( result != 1 )); then
		echo "  unable to inspect $scope; treating it as active (lsof exited $result)"
		active_worktrees[$scope]=1
		return 0
	fi

	return 1
}

run_if_available() {
	local tool="$1"
	shift
	if ! command -v "$tool" >/dev/null 2>&1; then
		echo "  $tool not on PATH, skipping"
		return 0
	fi
	"$@"
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

clean_merged_constellation_targets() {
	[[ -d "$CONSTELLATION" ]] || return 0

	git -C "$CONSTELLATION" fetch --quiet origin main || return

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
			rm -rf -- "$target" || cleanup_failed=1
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

	# Find target directories directly so each repository can be skipped when it
	# has an open file or cwd. Ignore trees that cannot contain Cargo projects.
	local target_output
	target_output="$(find "${search_roots[@]}" -type d \( \
		-name .git -o \
		-name .pnpm-store -o \
		-name .terraform -o \
		-name .terraform-plugin-cache -o \
		-name .venv -o \
		-name node_modules -o \
		-name vendor \
	\) -prune -o -type d -name target -print -prune)"
	local find_status=$?
	(( find_status == 0 )) || return "$find_status"
	targets=("${(@f)target_output}")

	local target project scope
	integer sweep_failed=0
	for target in "${targets[@]}"; do
		[[ -n "$target" ]] || continue
		project="${target:h}"
		[[ -f "$project/Cargo.toml" ]] || continue

		scope="$(git -C "$project" rev-parse --show-toplevel 2>/dev/null)"
		[[ -n "$scope" ]] || scope="$project"
		if worktree_is_active "$scope"; then
			echo "  active: skipping $target"
			continue
		fi

		echo "  sweeping artifacts unused for 14 days: $target"
		"$CARGO_SWEEP" sweep --time 14 "$project" || sweep_failed=1
	done

	return sweep_failed
}

echo "=== Nightly Maintenance: $(date) ==="

start_kib="$(measure_available_kib)" || exit 1
integer start_kib
integer threshold_kib=$(( MIN_FREE_GIB * 1024 * 1024 ))
echo "Starting disk space: $(format_gib "$start_kib") available"

run_step "Updating Homebrew..." brew update
run_step "Upgrading Homebrew packages..." brew upgrade
run_step "Cleaning Homebrew caches..." brew cleanup --prune=all
run_step "Pruning unused mise tool versions..." run_if_available mise mise prune --tools --yes
run_step "Updating fleetctl..." update_fleetctl

if cleanup_kib="$(measure_available_kib)"; then
	integer cleanup_kib
	if (( cleanup_kib < threshold_kib )); then
		echo "Disk cleanup enabled: $(format_gib "$cleanup_kib") is below ${MIN_FREE_GIB} GiB"
		run_step "Pruning pnpm store..." run_if_available pnpm pnpm store prune
		run_step "Pruning uv cache..." run_if_available uv uv cache prune
		run_step "Reclaiming merged constellation worktree targets..." clean_merged_constellation_targets
		run_step "Sweeping inactive Rust targets..." sweep_inactive_rust_targets
	else
		echo "Disk cleanup skipped: $(format_gib "$cleanup_kib") meets the ${MIN_FREE_GIB} GiB threshold"
	fi
else
	echo "Disk cleanup skipped because available space could not be measured"
	(( failures += 1 ))
fi

if after_kib="$(measure_available_kib)"; then
	integer after_kib
	integer reclaimed_kib=$(( after_kib - start_kib ))
	echo "Final disk space: $(format_gib "$after_kib") available"
	echo "Net disk change: $(format_gib "$reclaimed_kib")"
else
	(( failures += 1 ))
fi

if (( failures > 0 )); then
	echo "=== Maintenance completed with $failures failed step(s) ==="
	exit 1
fi

echo "=== Maintenance complete ==="
