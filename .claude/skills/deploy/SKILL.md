---
name: deploy
description: Push merged dotfiles changes out to every machine (arrakis, corrino) — pull on each, restow changed packages, restart affected services, and verify. Use after merging a dotfiles PR, or when asked to "deploy dotfiles", "push out to corrino/arrakis", "sync my machines", or "roll out" config changes.
---

# Deploy dotfiles to all machines

Roll merged `main` out to every machine: pull, restow what changed, restart the services whose config changed, verify.

## Machines

| Machine | Hostname        | How to reach                          |
| ------- | --------------- | ------------------------------------- |
| arrakis | `Arrakis.local` | local, or `ssh arrakis` over tailnet  |
| corrino | `Corrino-2.local` | local, or `ssh corrino` over tailnet |

Both are macOS. Run `hostname` to learn which machine you're on: deploy there directly, and reach the others with `ssh -o BatchMode=yes <host> '<commands>'` (key auth between the machines is set up by `bootstrap.sh`'s `setup_tailnet_ssh`). Non-interactive SSH still sources `~/.zshenv`, so brew binaries (`yabai`, `sketchybar`) are on PATH; if one isn't found, use `/opt/homebrew/bin/<bin>`.

## Preconditions

- The change is merged to `origin/main`. If not, finish the PR flow first — this repo is `wadefletch/*`, so it is NOT on bulldozer: merge with `gh pr merge --squash --delete-branch`.
- Never leave a machine's checkout on a feature branch. Configs are stow-symlinked into the repo, so whatever is checked out IS the live config.

## Steps (repeat per machine)

1. **Pull, recording the old HEAD** so you can compute what changed:

   ```sh
   cd ~/.dotfiles
   OLD=$(git rev-parse HEAD)
   git pull --ff-only
   ```

   If the tree is dirty or the pull won't fast-forward, stop and report that machine's state instead of stashing or forcing.

2. **List changed packages:**

   ```sh
   git diff --name-only "$OLD"..HEAD | cut -d/ -f1 | sort -u
   ```

   A stow package is any non-dot top-level directory. Ignore root files (`README.md`, `bootstrap.sh`, …) and dot-dirs (`.claude/`, `.githooks/`) — they aren't stowed.

3. **Restow packages whose file SET changed** (files added, deleted, or renamed — content-only edits need nothing, symlinks already point at the new content):

   ```sh
   cd ~/.dotfiles && stow -t "$HOME" --restow <pkg>...
   ```

   Restow is idempotent — when unsure, restow.

4. **Restart services** per the matrix below, only for packages that actually changed.

5. **Verify:** `git status -sb` clean and even with `origin/main`; `pgrep -fl <daemon>` shows a fresh PID for anything you restarted.

## Restart matrix

| Package changed | Action |
| --------------- | ------ |
| `skhd-zig` | `launchctl kickstart -k gui/$(id -u)/com.jackielii.skhd` (`skhd --reload` is unreliable — no PID file) |
| `yabai` | `yabai --restart-service`. This also reloads sketchybar (`.yabairc` ends with `sketchybar --reload`), so skip the sketchybar row when both changed. |
| `sketchybar` | `sketchybar --reload` |
| `nightly-maintenance` | `launchctl bootout gui/$(id -u)/com.wadefletcher.nightly-maintenance 2>/dev/null; launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.wadefletcher.nightly-maintenance.plist` |
| `duti` | `duti ~/.config/duti/default-apps` |
| `ghostty` | No CLI reload — tell the user open Ghostty windows need cmd+shift+, (Reload Configuration). |
| `zsh`, `starship`, `git`, `gh`, `ssh`, `mise`, `cargo` | Nothing — next shell picks it up. |
| `nvim`, `claude`, `codex`, `factory`, `cursor`, `vscode`, `alacritty`, `docker`, `crowdcontrol`, `terraform`, `wallpapers` | Nothing — next app launch. |
| `bootstrap.sh`, or a brand-new package directory | Run `./bootstrap.sh` (idempotent) so new deps/casks/packages get installed and stowed. |

## Report

Per machine, report: old → new commit, packages restowed, services restarted (with new PIDs), and anything skipped (dirty tree, unreachable host, manual steps like Ghostty reload).
