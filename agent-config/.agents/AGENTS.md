## Engineering judgment

- Before writing new code, check what the codebase, the standard library or platform, and the dependencies and frameworks already installed provide, and use it the way the surrounding code does. Check the framework's docs before hand-rolling something it may already do.
- Add a dependency only when it replaces real complexity, never for a few lines. Prefer one that is maintained, widely used, and fits the stack, and say why in the PR.
- Fix root causes. Reproduce the failure, trace it to the first place the system went wrong, fix it there, and fix every other place with the same fault. A guard, retry, swallowed error, or clamped value is a fix only when the state it handles is legitimate; otherwise find what produced that state. A workaround that needs a paragraph of comment to justify it means the code is wrong.
- When two fixes built on the same assumption have failed, write the assumption down and test it before trying a third.
- Integrate a new requirement as if it had been there from the start instead of bolting it on, and carry it through types, docs, and examples.
- Push back. When something learned mid-task (a constraint, a cost, a framework limit) changes the tradeoffs behind the request, stop and say so with a recommendation before building the original plan. "This doesn't earn its place" is a valid answer; agreement is not the default.
- Build only what was asked: no speculative options, abstractions, or "for later" code. Name what you skipped in one line.

## Skills

- Before writing or reviewing code, load the matching `code-style` skill: `typescript`, `rust`, `frontend`, `terraform`, `github-actions`, or `mise`. Load `testing` before writing or changing a test. A repository's own skill on the same topic overrides it.
- When editing docs, comments, or any prose, load `no-accretive-writing`; when the reader is an agent (`AGENTS.md`, `CLAUDE.md`, a skill), also load `writing-for-agents`.
- Before committing, pushing, opening or updating a pull request, resolving conflicts, or cleaning up branches, load the Tractorbeam `git` skill.
- Before reading, filing, or updating Linear issues, projects, initiatives, or milestones, load the Tractorbeam `linear` skill.

## Git metadata

- When a Git command required by the user fails because `.git` or linked-worktree metadata is read-only, retry that narrowly scoped command with sandbox escalation. Treat this as an expected approval boundary, not a broken checkout.
- Do not create a replacement clone, relocate the worktree, alter Git metadata paths, broaden filesystem permissions, or enable full access solely to bypass protected Git metadata.
- Preserve normal Git safety constraints when escalating. Never escalate destructive or history-rewriting Git operations unless the user explicitly authorized them.
- If a push updates the remote but fails to update a local remote-tracking ref, verify the remote state before retrying the push.

## Waiting on CI

- When a repository's own instructions or skills say how to wait on its CI (for example with `rwx results`), follow them instead of this section.
- Otherwise, wait with `gh watch pr <PR> --interval 15s --exit-on ci-passed,ci-failed,pr-merged,pr-closed`, run with the Monitor tool in Claude Code and in the background elsewhere; the Tractorbeam git skill's "Waiting on CI" section has the details.
- If gh answers `unknown command "watch" for "gh"`, run `gh extension install justincampbell/gh-watch --pin v0.4.0` and retry.

## Library documentation

- For questions about a library, framework, SDK, API, or cloud service, even a well-known one and even when you think you know the answer, fetch current docs with the Context7 MCP tools before relying on training data, and prefer them over web search. Skip them for refactoring, writing scripts from scratch, debugging business logic, code review, and general programming concepts.
- Start with `resolve-library-id` (the library name plus what to look up) unless you have an `/org/project` ID. Pick the best match by name, relevance, snippet count, source reputation, and benchmark score, preferring a version-specific ID when a version is named. Then call `query-docs` once per concept and answer from what it returns.

## File search

- To search the current git-indexed directory, use the fff tools: for file contents, `grep` from the fff MCP server or `ffgrep` in Pi; for several patterns at once, `multi_grep` or `fff-multi-grep`; for file paths, `find_files` or `fffind`. Use them instead of the harness's built-in search tools (including Pi's own `grep` and `find`) and instead of `rg`, `grep`, `find`, `fd`, or `ls -R` in the shell, including searches chained with pipes, `xargs`, or loops.
- Include the directory or module you already know in the first search. Read more of a file only when the returned lines need more context.
- Use shell search only outside the git-indexed directory, or for a search fff can't express, such as one across files that aren't tracked by git.
