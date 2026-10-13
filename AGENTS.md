GNU Stow-based dotfiles for macOS. Each top-level directory is a stow package mirroring the target home directory structure. Run `stow <package>` from the repo root (or `bootstrap.sh` for everything).

## Structure

```
<package>/          # stow package — contents symlinked into ~
  .config/<app>/    # XDG config (ghostty, git, nvim, starship, alacritty)
  .config/zsh/      # zshenv, zprofile, zshrc, sourced by machine-local ~/.zshenv, ~/.zprofile, ~/.zshrc (zsh/)
  .ssh/config       # ssh config (ssh/)
  Library/...       # macOS paths (cursor/, vscode/, nightly-maintenance/, office-tv-relay/)
  .cursor/          # Cursor CLI config (cursor/; --no-folding so ~/.cursor stays host-local)
  .claude/          # Claude Code runtime files (claude/)
  .pi/agent/        # Pi settings and MCP servers (pi/; --no-folding so ~/.pi stays host-local)
  .docker/          # tool config (docker/)
  .aws/config       # aws cli profiles (aws/) — live ~/.aws/config is assembled; credentials, SSO cache, config.local untracked
.githooks/          # git hooks (core.hooksPath); post-merge updates submodules, pre-commit rejects installer blocks
.retired/           # reference-only packages (yabai, skhd-zig); dot-dirs aren't stowed
bootstrap.sh        # installs deps, stows packages, git hooks, WARP SSH host keys, macOS defaults (macOS + Linux)
```

## Key files

- `zsh/.config/zsh/zshrc` — shell config, aliases (`ga`, `gc`, `gs`, `gp`, `gl`, `gq`), `stopall`, `automerge`
- `zsh/.config/zsh/zshenv` — environment for every zsh: PATH exports (brew, local bin), then `~/.zshenv.local` for per-machine variables
- `claude/AGENTS.md` — instructions for the Claude stow package itself
- `agent-config/.agents/AGENTS.md` — user-scoped agent instructions. `claude/.claude/CLAUDE.md`, `codex/.codex/AGENTS.md`, and `pi/.pi/agent/AGENTS.md` are symlinks to it, so edit this file, not the links.

## Conventions

- XDG paths (`.config/`) where the app supports it, macOS `Library/` paths otherwise.
- Every top-level directory is a stow package.
- `~/.zshenv`, `~/.zprofile`, `~/.zshrc`, and `~/.gitconfig` are machine-local files bootstrap creates, because installers append to them (Aikido's endpoint agent, the tractorbeam mise plugin, Vite+). Each zsh one sources `zsh/.config/zsh/<name>` first, and git reads `~/.gitconfig` after the tracked `git/.config/git/config`. Put shared settings in the tracked files and installer output in the machine-local ones; the pre-commit hook rejects staged installer blocks (`# >>>` markers, `# Added by`, Aikido lines) in tracked shell and git config.
- The `claude/` package has a `.stow-local-ignore` — check it before adding files.
- Packages listed in `bootstrap.sh`'s `NO_FOLDING` target directories that also hold host-local state; stow links their files individually so the directory itself is never replaced.
- Host-scoped packages (`ARRAKIS_ONLY` in `bootstrap.sh`, matched on the lowercased `LocalHostName`) are stowed only on that host, and bootstrap loads their LaunchAgents there. `office-tv-relay/` is the only one.
- Other background workers stay opt-in. `git-auto-ff/` ships a systemd user timer (Linux) and a LaunchAgent (macOS); it is in `NO_FOLDING` so `systemctl --user enable` writes into `~/.config`, not the repo. Bootstrap stows it everywhere but never enables it; `./enable-git-auto-ff.sh` does, per host.

## Deploying

- Deploy merged `main` only, and never leave a machine on another branch: the checkout is the live config.
- Machines are arrakis and corrino (macOS). Work locally on the one `hostname` names; reach the other with `ssh -o BatchMode=yes <host> '…'`.
- On each: `cd ~/.dotfiles && git pull --ff-only && ./bootstrap.sh deploy`. Stop and report a dirty tree or a pull that won't fast-forward.
- `deploy` restows every package, refreshes the machine-local entry points, `~/.aws/config`, and pinned SSH host keys, removes dangling links into the checkout, reloads this host's LaunchAgents (and git-auto-ff where it is enabled), and reapplies `duti`. It installs nothing and never needs sudo.
- Run the full `./bootstrap.sh` instead when its install steps or `agent-config/` change, or a package is added. It asks for sudo only on a machine's first run.
- Open Ghostty windows need cmd+shift+, to reload.
