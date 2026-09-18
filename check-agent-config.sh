#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POLICIES="$ROOT/agent-config/.config/agent-harnesses"

fail() {
  printf 'agent config check failed: %s\n' "$1" >&2
  exit 1
}

for file in "$POLICIES"/*.json; do
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

if rg -n 'Bash\([^\n]*:\*\)' \
  "$ROOT/.claude" "$ROOT/agent-config" "$ROOT/claude" \
  -g '*.json' >/dev/null; then
  fail 'deprecated Claude Bash permission syntax remains'
fi

if rg -n '/Users/[^/]+/' "$POLICIES" >/dev/null; then
  fail 'portable agent policy contains an absolute macOS home path'
fi

[[ ! -e "$ROOT/claude/.claude/settings.json" ]] ||
  fail 'Claude live settings must remain host-local'
[[ ! -e "$ROOT/cursor/.cursor/cli-config.json" ]] ||
  fail 'Cursor CLI live settings must remain host-local'

jq -e '
  [.plugins[] as $plugin
    | $plugin.harnesses[]
    | . as $harness
    | ($plugin.name + "@" + $plugin.marketplace + ":" + $harness)]
  | group_by(.)
  | all(length == 1)
' "$POLICIES/plugins.json" >/dev/null ||
  fail 'plugin manifest contains a duplicate harness entry'

printf '%s\n' 'agent config check passed'
