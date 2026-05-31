# codex

Stow package for OpenAI Codex config under `~/.codex`.

Stow mirrors the home layout, so `codex/.codex/AGENTS.md` symlinks to
`~/.codex/AGENTS.md` — the Codex equivalent of `~/.claude/CLAUDE.md`.

## Scope: only `AGENTS.md` is managed

Codex owns `~/.codex` and rewrites most of it at runtime, so only the durable,
hand-authored, secret-free file is tracked here. The rest is intentionally left
local on each machine:

| Path | Why it's NOT stowed |
| --- | --- |
| `config.toml` | App-rewritten every run (marketplace timestamps, absolute `/Applications` + `.cache` paths, a growing `[projects.*]` trust list) **and** holds secrets (MCP API keys). Symlinking it would commit the keys and churn constantly. |
| `rules/` | Auto-accumulated per-session allow-grants for specific files/paths — volatile, not config. |
| `skills/` | OpenAI-bundled, app-managed (reinstalled by the desktop app). Stowing fights the skill manager. |
| `auth.json`, `*.sqlite*`, `sessions/`, `cache/`, `logs_*`, `archived_sessions/` | Auth + runtime state. |

If durable `config.toml` preferences (model, personality, `[features]`,
`[shell_environment_policy]`, `[desktop]`) need to be reproducible, capture them
as a sanitized `config.toml.reference` here — do **not** symlink the live file.
