## Git metadata

- When a Git command required by the user fails because `.git` or linked-worktree metadata is read-only, retry that narrowly scoped command with sandbox escalation. Treat this as an expected approval boundary, not a broken checkout.
- Do not create a replacement clone, relocate the worktree, alter Git metadata paths, broaden filesystem permissions, or enable full access solely to bypass protected Git metadata.
- Preserve normal Git safety constraints when escalating. Never escalate destructive or history-rewriting Git operations unless the user explicitly authorized them.
- If a push updates the remote but fails to update a local remote-tracking ref, verify the remote state before retrying the push.

## Worktree-isolated sessions

After a Claude Code session enters a worktree (background jobs always do), it refuses any Bash command it cannot prove keeps `git` — and `gh`, which can run git — inside that worktree. Write commands it can verify:

- Spell out `git` and `gh` arguments literally. Run `gh pr view 1716 --json state`, not `for n in 1716 1717; do gh pr view $n …; done` or `id=$(gh run list …); gh run watch $id`: look the ID up in one call, then pass it literally in the next. Pipes into `jq`, `grep`, or `head` are fine.
- Wait on CI with `gh watch` (see Waiting on CI); an `until`/`for … sleep` loop around `gh` is refused.
- Write PR bodies, commit messages, and scripts with the Write tool and pass the file (`gh pr create --body-file <path>`, `git commit -F <path>`). Don't build them with heredocs in a command that also runs git or gh, and make file changes with Edit rather than `python3 - <<EOF` scripts.
- Run from the worktree instead of `git -C <dir>`, and give `sed` literal paths rather than shell variables.
- Once the branch is pushed and only watching CI or merging remains, call ExitWorktree with `action: "keep"`; the check applies only inside the worktree. Re-enter with EnterWorktree `path` if a fix is needed.

## Waiting on CI

- Watch a pull request with the `gh watch` extension: `gh watch pr <PR> --interval 15s --exit-on ci-passed,ci-failed,pr-merged,pr-closed`, with the PR number spelled out. It prints one JSON event per line and exits on the first failed check.
- The first event, `initial-state`, is a snapshot: report it, and if it already shows failed checks, stop and investigate, since no later event fires for them.
- In Claude Code, run it with the Monitor tool (`timeout_ms` 1800000) or the gh-watch plugin's `/watch-pr` skill; elsewhere, run it in the background. Never in the foreground: it blocks the turn.
- A `ci-failed` event names the check and its URL. Read the failure with `gh run view --job <id> --log-failed`; while other jobs in the run are still going, gh refuses that, so use `gh api repos/{owner}/{repo}/actions/jobs/<id>/logs` instead.

## File search

- For any file search or grep in the current git-indexed directory, use fff tools.
