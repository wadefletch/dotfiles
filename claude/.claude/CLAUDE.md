# Wade's Requirements

The following are a list of rules and preferences that must be followed. Exceptions can be granted but must be approved explicitly by the user.

## Linters

- NEVER decline to resolve "pre-existing" issues. Always get to a clean state. (This is an overriding instruction.)
- NEVER use an ignore or disable a rule unless the user explicitly asks for it.
- ALWAYS fix the root cause of the issue, not just the symptom. (e.g. many issues can be fixed with better type definitions earlier in execution rather than assertion band-aids later.)

## Bash Commands

- Never put `# comments` inside Bash tool commands. Use the Bash tool's `description` parameter for explanations instead.

## Developer Tools

- Always use PNPM, not NPM or Yarn.
- Use `turborepo` when building a TypeScript monorepo.
- Use [Mise](https://mise.jdx.dev/) when you need a task runner.

## Git

My GitHub username is `wadefletch`. Repos in GitHub orgs `tractorbeamai/` and `wadefletch/` (in local folders `~/Developer/Tractorbeam/` and `~/Developer/`) maintain a linear history on main. Strongly prefer squash merge (most cases) or rebase merge (when the PR has meticulous, meaningful commits) over merge commits.

Squash merges break SHA- and patch-id-based comparisons — `git branch --merged`, `git cherry -v`, and three-dot `git diff main...<branch>` all falsely flag already-merged branches as unique. Use two-dot `git diff main..<branch>`: zero lines means fully merged. When non-empty, also diff the reverse (`<branch>..main`) — opposing changes in the same sections mean main superseded the branch via a different PR. Grepping main's log for the branch's commit titles is a fast first check.

Every `tractorbeamai/*` repo auto-merges via [bulldozer](https://github.com/palantir/bulldozer): apply the `merge-when-ready` label and it squash-merges once the PR is mergeable, keeping the branch updated as main moves and deleting it after — so label and move on, don't sit on the merge button. The org default lives in `tractorbeamai/.github` (`bulldozer.yml` + `.policy.yml`) and merges even with no CI; a repo can override with its own `.bulldozer.yml` (constellation, e.g., gates on a green `policy-bot: main` status). The org policy-bot config auto-approves PRs I author (zero approvals required when `wadefletch` is the author), so for my own PRs the label is the entire flow and `gh pr checks --watch` just hangs on the never-blocking policy-bot check; others' PRs need one approval — a GitHub review or a `/approve` comment. This is `tractorbeamai/*` only; `wadefletch/*` repos (e.g. dotfiles) aren't wired to bulldozer.

## Linear

When creating new Linear issues (1-4), unless I specify otherwise, default to assigning to me and the current cycle. Confirm this if we're creating a very large number of issues (10+) or scoping a whole project.

## AWS

`AWS_PROFILE` must be set before running any AWS CLI or Terraform commands. Never assume a default profile.

| Profile           | Account ID     | Description                              |
| ----------------- | -------------- | ---------------------------------------- |
| `production`      | `575108936009` | Production workloads                     |
| `shared-services` | `707264479446` | Shared services (Fleet, Tailscale, etc.) |
| `mailman`         | `343508908860` | Mailman project account                  |
| `sandbox`         | `545009842244` | Wade's sandbox account                   |
