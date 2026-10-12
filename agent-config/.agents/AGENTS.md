## Git metadata

- When a Git command required by the user fails because `.git` or linked-worktree metadata is read-only, retry that narrowly scoped command with sandbox escalation. Treat this as an expected approval boundary, not a broken checkout.
- Do not create a replacement clone, relocate the worktree, alter Git metadata paths, broaden filesystem permissions, or enable full access solely to bypass protected Git metadata.
- Preserve normal Git safety constraints when escalating. Never escalate destructive or history-rewriting Git operations unless the user explicitly authorized them.
- If a push updates the remote but fails to update a local remote-tracking ref, verify the remote state before retrying the push.

## Worktree-isolated sessions

After a Claude Code session enters a worktree (background jobs always do), it refuses any Bash command it cannot prove keeps `git` — and `gh`, which can run git — inside that worktree. Write commands it can verify:

- Spell out `git` and `gh` arguments literally. Run `gh pr view 1716 --json state`, not `for n in 1716 1717; do gh pr view $n …; done` or `id=$(gh run list …); gh run watch $id`: look the ID up in one call, then pass it literally in the next. Pipes into `jq`, `grep`, or `head` are fine.
- Wait on CI with `gh-ci-watch <PR>` (see Waiting on CI); an `until`/`for … sleep` loop around `gh` is refused.
- Write PR bodies, commit messages, and scripts with the Write tool and pass the file (`gh pr create --body-file <path>`, `git commit -F <path>`). Don't build them with heredocs in a command that also runs git or gh, and make file changes with Edit rather than `python3 - <<EOF` scripts.
- Run from the worktree instead of `git -C <dir>`, and give `sed` literal paths rather than shell variables.
- Once the branch is pushed and only watching CI or merging remains, call ExitWorktree with `action: "keep"`; the check applies only inside the worktree. Re-enter with EnterWorktree `path` if a fix is needed.

## Waiting on CI

- Watch a pull request's checks with `gh-ci-watch <PR>` (add `--required` to watch only merge-blocking checks). Pass the PR number literally and run it from the repository. It waits until checks are registered for the PR's current head commit, prints one timestamped line per check and per job step as they change, and stops at the first failure after printing that job's annotations and the log leading up to its error.
- In Claude Code, run it with the Monitor tool so each line arrives as it happens (`gh-ci-watch 62 --timeout 30` keeps it within Monitor's 30-minute cap; rerun it if checks are still pending), or with Bash `run_in_background` when only the result matters. Don't run it in the foreground; it blocks the turn.
- Act on the exit code: 0 passed, 1 a check failed (fix it from the printed error, then push and watch again), 2 no checks registered or timed out, 3 a newer commit was pushed (watch again).
- Without `gh-ci-watch`, use `gh pr checks <PR> --watch --fail-fast`. It fails with "no checks reported" if run right after a push, and `--json` turns its watching off. `gh run watch` follows only one workflow run and can't stop at the first failure.

## Shell

- The shell is zsh, which expands an unquoted word starting with `=` to a command's path, so `echo ===` fails with "== not found" and stops the rest of the command. Quote separators (`echo '=== next'`) or use `---`.

## File search

- For any file search or grep in the current git-indexed directory, use fff tools.
