# Sync Developer Repos

Synchronize all git repos in `~/Developer/` and `~/Developer/Tractorbeam/` across two machines (Corrino and Arrakis) and their GitHub origins. Preserve all local work — never discard uncommitted changes, force-push, or delete unmerged branches.

## Host Detection

Determine which machine you're running on:

```
hostname
```

- `Corrino` (any casing/suffix): local is Corrino, remote is `ssh arrakis`
- `Arrakis` (any casing/suffix): local is Arrakis, remote is `ssh corrino`

Refer to "local" and "remote" throughout. Run commands on both sides in parallel where possible.

## Phase 1: Inventory

List all git repos in `~/Developer/*/` and `~/Developer/Tractorbeam/*/` on both local and remote. For each repo, collect:

- Current branch
- Remote URL (`git remote get-url origin`)
- Dirty files (`git status --porcelain`)
- Ahead/behind counts vs upstream
- Local branch list
- `.env*` files (up to 3 levels deep, excluding `.git/`)

Present a summary table and flag:
- Repos that exist on only one side
- Remote URL mismatches (different repo names, not just SSH vs HTTPS)
- Protocol mismatches — all `tractorbeamai/` and `wadefletch/` repos must use SSH (`git@github.com:`)

**Pause and show the summary before continuing.** Ask about any remote URL mismatches that point to different repos.

## Phase 2: Fetch & Push Branches

1. `git fetch --all` on every repo, both sides.
2. For every local branch on both sides, check if it's been squash-merged into main: `git diff origin/main...<branch>` — if zero diff, it's merged. **List merged branches and get confirmation before deleting.** Confirm the branch has no post-merge modifications.
3. Push all unpushed branches to origin. If a push is rejected (non-fast-forward), do NOT force-push — flag it for resolution.
4. For diverged branches (different SHAs, similar commit messages — likely rebased): back up the local branch, reset to origin, cherry-pick unique local commits. Resolve conflicts conservatively; skip commits whose content is already in origin.

## Phase 3: Commit Dirty Repos

**Before making any commits, run the `/git` skill** to load Tractorbeam's git conventions (conventional commit format, PR workflow, safety rules). Follow those conventions for all commits in this phase.

For each repo with uncommitted changes:

1. **Never commit**: `.terraform/` provider dirs, `.claude/worktrees/`, credential files (`.json` keys, `.p12`, `.pem`), `node_modules/`, `dist/` build output. Instead, ensure these are in `.gitignore`.
2. **Check for formatters** before committing: look for `format`/`lint` scripts in `package.json` or `Makefile`. Run them on changed files if available.
3. **Stage specific files** — never `git add -A` or `git add .`.
4. Commit on the current branch. If on main and the changes are substantial/unrelated to main, create a `wade/<descriptive-name>` branch first.

## Phase 4: Sync Main Branches

For each repo, ensure main is current on both sides:

1. Push any new main commits to origin.
2. Pull (with `--rebase`) on any side that's behind.
3. If a commit creates a rebase conflict where the local change is superseded by upstream (e.g., file deleted/rewritten upstream), **skip the commit** with `git rebase --skip`.
4. After all pushes/pulls, verify both sides are `ahead:0 behind:0`.

Handle cascading conflicts: if side A pushes, side B may now be behind. Pull B, then verify.

## Phase 5: Env Files

For repos with `.env*` files:

1. Compare files across local and remote.
2. **Never commit env files** — these are synced via `scp` only.
3. If one side has an env file the other lacks, copy it over.
4. If both sides have the same file:
   - **No conflicts** (disjoint keys, or same values): write the union to both sides.
   - **Conflicting values for the same key**: show the conflict, which file was last modified (`stat -f "%m %Sm"`), and ask the user which value to use.
5. Flag env files containing secrets (API keys, private keys, database URLs with passwords) when displaying diffs.

## Phase 6: Verify

Run a final status check across all repos on both sides:

```
name | branch | dirty | ahead | behind
```

Everything should be `dirty:0 ahead:0 behind:0` on main. Flag any exceptions with an explanation.

## Escalation Rules

**Always ask the user before:**
- Deleting any branch (even if merged)
- Resolving a remote URL mismatch pointing to different repos
- Choosing between conflicting env values
- Any action on a repo with no remote configured
- Force-pushing (should almost never happen)

**Safe to do automatically:**
- `git fetch`, `git pull --rebase`, `git push`
- Fixing SSH/HTTPS protocol mismatches on known orgs
- Committing clearly safe changes (lock files, gitignore updates, formatting)
- Copying env files that exist on one side only
- Skipping rebase commits superseded by upstream
