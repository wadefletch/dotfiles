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

## Documentation Lookup (Context7)

Use the `ctx7` CLI to fetch current documentation whenever the user asks about a library, framework, SDK, API, CLI tool, or cloud service -- even well-known ones like React, Next.js, Prisma, Express, Tailwind, Django, or Spring Boot. This includes API syntax, configuration, version migration, library-specific debugging, setup instructions, and CLI tool usage. Use even when you think you know the answer -- your training data may not reflect recent changes. Prefer this over web search for library docs.

### Steps

1. Resolve library: `npx ctx7@latest library <name> "<user's question>"` — use the official library name with proper punctuation (e.g., "Next.js" not "nextjs", "Customer.io" not "customerio", "Three.js" not "threejs")
2. Pick the best match (ID format: `/org/project`) by: exact name match, description relevance, code snippet count, source reputation (High/Medium preferred), and benchmark score (higher is better). If results don't look right, try alternate names or queries (e.g., "next.js" not "nextjs", or rephrase the question)
3. Fetch docs: `npx ctx7@latest docs <libraryId> "<user's question>"`
4. Answer using the fetched documentation

You MUST call `library` first to get a valid ID unless the user provides one directly in `/org/project` format. Use the user's full question as the query -- specific and detailed queries return better results than vague single words. Do not run more than 3 commands per question. Do not include sensitive information (API keys, passwords, credentials) in queries.

For version-specific docs, use `/org/project/version` from the `library` output (e.g., `/vercel/next.js/v14.3.0`).

If a command fails with a quota error, inform the user and suggest `npx ctx7@latest login` or setting `CONTEXT7_API_KEY` env var for higher limits. Do not silently fall back to training data.

When running under Codex, run Context7 CLI requests outside Codex's default sandbox. If a command fails with DNS or network errors such as ENOTFOUND, host resolution failures, or `fetch failed`, rerun it outside the sandbox instead of retrying inside.
