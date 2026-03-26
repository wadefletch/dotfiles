## Bash Commands

Never put `# comments` inside Bash tool commands. Use the Bash tool's `description` parameter for explanations instead. Inline comments break permission prefix matching.

## Git Preferences

Repos in `tractorbeamai/` and `wadefletch/` maintain a linear history on main. Strongly prefer squash merge (most cases) or rebase merge (when the PR has meticulous, meaningful commits) over merge commits. Because we squash merge, commit hashes on feature branches won't match main — when checking if a branch is stale/merged, compare actual diffs (`git diff main...<branch>`) rather than relying on commit SHAs or `git branch --merged`.

## Linear Preferences

When creating new Linear issues (1-4), unless I specify otherwise, default to assigning to me and the current cycle. Confirm this if we're creating a very large number of issues (10+) or scoping a whole project.

## AWS

`AWS_PROFILE` must be set before running any AWS CLI or Terraform commands. Never assume a default profile.

| Profile           | Account ID     | Description                              |
| ----------------- | -------------- | ---------------------------------------- |
| `root`            | `891377101660` | Organization management account          |
| `production`      | `575108936009` | Production workloads                     |
| `shared-services` | `707264479446` | Shared services (Fleet, Tailscale, etc.) |
| `audit`           | `216989103601` | Security audit and compliance            |
| `log-archive`     | `565393051614` | Centralized logging                      |
| `mailman`         | `343508908860` | Mailman project account                  |
| `sandbox`         | `545009842244` | Wade's sandbox account                   |

## Shell Functions

### `stopall`

Stops all Docker containers and kills processes on common dev ports (3000-3005).

```bash
stopall
```
