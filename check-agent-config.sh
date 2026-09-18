#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POLICIES="$ROOT/agent-config/.config/agent-harnesses"
CLAUDE_SETTINGS="$ROOT/claude/.claude/settings.json"

fail() {
  printf 'agent config check failed: %s\n' "$1" >&2
  exit 1
}

for file in "$POLICIES"/*.json "$CLAUDE_SETTINGS"; do
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

if rg -n '/Users/[^/]+/' "$POLICIES" "$CLAUDE_SETTINGS" >/dev/null; then
  fail 'portable agent policy contains an absolute macOS home path'
fi

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

jq -e --slurpfile manifest "$POLICIES/plugins.json" '
  .enabledPlugins == (
    $manifest[0].plugins
    | map(select(.harnesses | index("claude")))
    | map({key: (.name + "@" + .marketplace), value: true})
    | from_entries
  )
' "$CLAUDE_SETTINGS" >/dev/null ||
  fail 'Claude enabled plugins differ from the shared plugin manifest'

printf '%s\n' 'agent config check passed'
