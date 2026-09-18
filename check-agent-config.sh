#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

fail() {
  printf 'agent config check failed: %s\n' "$1" >&2
  exit 1
}

for file in \
  "$ROOT/agent-config/.config/agent-harnesses/plugins.json" \
  "$ROOT/claude/.claude/settings.json"; do
  jq -e . "$file" >/dev/null || fail "invalid JSON: ${file#"$ROOT/"}"
done

legacy_instructions="$(
  rg --files --hidden "$ROOT" \
    -g 'CLAUDE.md' \
    -g '!.git/**' \
    -g '!.claude/worktrees/**' || true
)"
[[ -z "$legacy_instructions" ]] ||
  fail "use AGENTS.md instead of CLAUDE.md: $legacy_instructions"

if rg -n '/Users/[^/]+/' "$ROOT/agent-config" "$ROOT/claude" >/dev/null; then
  fail 'agent configuration contains a machine-specific home path'
fi

printf '%s\n' 'agent config check passed'
