## Git metadata

- When a Git command required by the user fails because `.git` or linked-worktree metadata is read-only, retry that narrowly scoped command with sandbox escalation. Treat this as an expected approval boundary, not a broken checkout.
- Do not create a replacement clone, relocate the worktree, alter Git metadata paths, broaden filesystem permissions, or enable full access solely to bypass protected Git metadata.
- Preserve normal Git safety constraints when escalating. Never escalate destructive or history-rewriting Git operations unless the user explicitly authorized them.
- If a push updates the remote but fails to update a local remote-tracking ref, verify the remote state before retrying the push.

## Waiting on CI

- Wait with `gh watch pr <PR> --interval 15s --exit-on ci-passed,ci-failed,pr-merged,pr-closed`, run with the Monitor tool in Claude Code and in the background elsewhere; the Tractorbeam git skill's "Waiting on CI" section has the details.
- If gh answers `unknown command "watch" for "gh"`, run `gh extension install justincampbell/gh-watch --pin v0.4.0` and retry.

## Library documentation

- For questions about a library, framework, SDK, API, or cloud service, even a well-known one and even when you think you know the answer, fetch current docs with the Context7 MCP tools before relying on training data, and prefer them over web search. Skip them for refactoring, writing scripts from scratch, debugging business logic, code review, and general programming concepts.
- Start with `resolve-library-id` (the library name plus what to look up) unless you have an `/org/project` ID. Pick the best match by name, relevance, snippet count, source reputation, and benchmark score, preferring a version-specific ID when a version is named. Then call `query-docs` once per concept and answer from what it returns.

## File search

- For any file search or grep in the current git-indexed directory, use fff tools.
