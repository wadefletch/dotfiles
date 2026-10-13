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

- Wait with `gh watch pr <PR> --interval 15s --exit-on ci-passed,ci-failed,pr-merged,pr-closed`, run with the Monitor tool in Claude Code and in the background elsewhere; the Tractorbeam git skill's "Waiting on CI" section has the details.
- If gh answers `unknown command "watch" for "gh"`, run `gh extension install justincampbell/gh-watch` and retry.

## File search

- For any file search or grep in the current git-indexed directory, use fff tools.
