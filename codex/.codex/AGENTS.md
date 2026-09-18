## Git metadata

- When a Git command required by the user fails because `.git` or linked-worktree metadata is read-only, retry that narrowly scoped command with sandbox escalation. Treat this as an expected approval boundary, not a broken checkout.
- Do not create a replacement clone, relocate the worktree, alter Git metadata paths, broaden filesystem permissions, or enable full access solely to bypass protected Git metadata.
- Preserve normal Git safety constraints when escalating. Never escalate destructive or history-rewriting Git operations unless the user explicitly authorized them.
- If a push updates the remote but fails to update a local remote-tracking ref, verify the remote state before retrying the push.
