GNU Stow-based dotfiles for macOS. Each top-level directory is a stow package mirroring the target home directory structure. Run `stow <package>` from the repo root (or `bootstrap.sh` for everything).

## Structure

```
<package>/          # stow package — contents symlinked into ~
  .config/<app>/    # XDG config (ghostty, git, nvim, starship, alacritty)
  .zshenv           # shell environment (zsh/)
  .config/zsh/      # zshrc and zprofile, loaded by machine-local ~/.zshrc and ~/.zprofile (zsh/)
  .ssh/config       # ssh config (ssh/)
  Library/...       # macOS paths (cursor/, vscode/, nightly-maintenance/, office-tv-relay/)
  .cursor/          # Cursor CLI config (cursor/; --no-folding so ~/.cursor stays host-local)
  .claude/          # Claude Code runtime files (claude/)
  .pi/agent/        # Pi settings and MCP servers (pi/; --no-folding so ~/.pi stays host-local)
  .docker/          # tool config (docker/)
  .aws/config       # aws cli profiles (aws/) — live ~/.aws/config is assembled; credentials, SSO cache, config.local untracked
.githooks/          # git hooks (core.hooksPath); post-merge updates submodules
.retired/           # reference-only packages (yabai, skhd-zig); dot-dirs aren't stowed
bootstrap.sh        # installs deps, stows packages, git hooks, WARP SSH host keys, macOS defaults (macOS + Linux)
```

## Key files

- `zsh/.config/zsh/zshrc` — shell config, aliases (`ga`, `gc`, `gs`, `gp`, `gl`, `gq`), `stopall`, `automerge`
- `zsh/.zshenv` — lightweight PATH exports (brew, local bin)
- `claude/AGENTS.md` — instructions for the Claude stow package itself
- `agent-config/.agents/AGENTS.md` — user-scoped agent instructions. `claude/.claude/CLAUDE.md`, `codex/.codex/AGENTS.md`, and `pi/.pi/agent/AGENTS.md` are symlinks to it, so edit this file, not the links.

## Conventions

- XDG paths (`.config/`) where the app supports it, macOS `Library/` paths otherwise.
- Every top-level directory is a stow package.
- `~/.zshrc`, `~/.zprofile`, and `~/.gitconfig` are machine-local files bootstrap creates; installers such as Aikido's endpoint agent append there. The zsh ones load `zsh/.config/zsh/{zshrc,zprofile}`, and git reads `~/.gitconfig` after the tracked `git/.config/git/config`. Put shared settings in the tracked files.
- The `claude/` package has a `.stow-local-ignore` — check it before adding files.
- Packages listed in `bootstrap.sh`'s `NO_FOLDING` target directories that also hold host-local state; stow links their files individually so the directory itself is never replaced.
- Host-scoped packages (`ARRAKIS_ONLY` in `bootstrap.sh`, matched on the lowercased `LocalHostName`) are stowed only on that host, and bootstrap loads their LaunchAgents there. `office-tv-relay/` is the only one.
- Other background workers stay opt-in. `git-auto-ff/` ships a systemd user timer (Linux) and a LaunchAgent (macOS); it is in `NO_FOLDING` so `systemctl --user enable` writes into `~/.config`, not the repo. Bootstrap stows it everywhere but never enables it; `./enable-git-auto-ff.sh` does, per host.

## Deploying

- Deploy merged `main` only, and never leave a machine on another branch: the checkout is the live config.
- Machines are arrakis and corrino (macOS). Work locally on the one `hostname` names; reach the other with `ssh -o BatchMode=yes <host> '…'`.
- On each: in `~/.dotfiles`, `OLD=$(git rev-parse HEAD); git pull --ff-only` (stop and report a dirty tree or a pull that won't fast-forward), then `git diff --name-only "$OLD"..HEAD | cut -d/ -f1 | sort -u` lists changed packages.
- Restow packages whose set of files changed with `stow -t "$HOME" --restow <pkg>`, adding `--no-folding` for `NO_FOLDING` packages.
- Reload what runs in the background: `launchctl bootout gui/$(id -u)/<label>; launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/<label>.plist` for `nightly-maintenance` and `office-tv-relay`'s two agents (arrakis only), `duti ~/.config/duti/default-apps`, `sync-aws-config` for `aws`, and `./enable-git-auto-ff.sh` on hosts that enabled it when its units change. Open Ghostty windows need cmd+shift+, to reload.
- Run `./bootstrap.sh` when `bootstrap.sh` or `agent-config/` changes, or a package is added.
- Finish by deleting dangling links into the checkout: `find ~ -maxdepth 5 -type l -lname '*.dotfiles/*' ! -exec test -e {} \; -print`.

## pnpm globals

- Launchers directly in `$PNPM_HOME` rather than `$PNPM_HOME/bin` come from pnpm before 11. `grep -ho 'global/5/.pnpm/[^/]*@[^/]*' "$PNPM_HOME"/* | sort -u` names their packages (`+` stands for `/`); reinstall those with `pnpm add -g`, run `pnpm approve-builds -g <pkg>` for any it reports as ignored, then delete the old launchers and `$PNPM_HOME/global/5`.
