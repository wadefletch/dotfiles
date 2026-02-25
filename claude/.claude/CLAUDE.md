## Git Preferences

Repos in `tractorbeamai/` and `wadefletch/` maintain a linear history on main. Strongly prefer squash merge (most cases) or rebase merge (when the PR has meticulous, meaningful commits) over merge commits.

## AWS

`AWS_PROFILE` must be set before running any AWS CLI or Terraform commands. Never assume a default profile.

| Profile | Account ID | Description |
|---------|------------|-------------|
| `root` | `891377101660` | Organization management account |
| `production` | `575108936009` | Production workloads |
| `shared-services` | `707264479446` | Shared services (Fleet, Tailscale, etc.) |
| `audit` | `216989103601` | Security audit and compliance |
| `log-archive` | `565393051614` | Centralized logging |
| `carlyle` | `813538162118` | Carlyle client account |
| `mailman` | `343508908860` | Mailman project account |
| `sandbox` | `545009842244` | Wade's sandbox account |

## Shell Functions

### `stopall`

Stops all Docker containers and kills processes on common dev ports (3000-3005).

```bash
stopall
```
