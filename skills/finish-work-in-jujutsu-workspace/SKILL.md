---
name: finish-work-in-jujutsu-workspace
description: Finish completed work in a Jujutsu (jj) workspace by confirming the workspace and target branch, marking the current issue/task/feature index markdown as done when present, syncing onto the latest main, summarizing the diff, creating or updating a bookmark, and creating a GitHub PR. Use when implementation is complete in a jj workspace and the user wants to finish work, push a jj bookmark, open a pull request, or prepare jj changes for review. Uses a subset of the jujutsu-basics commands.
---

# Finish Work In Jujutsu Workspace

Finish completed work from a Jujutsu (`jj`) workspace by verifying state, syncing onto the latest `main`, summarizing the diff, creating/updating a bookmark, and creating a GitHub pull request.

This is the `jj` counterpart of `finish-work-in-branch-and-create-pr`. It uses only a subset of the commands in the `jujutsu-basics` skill. See `jujutsu-basics` for the full command reference and mental model.

## Hard Rules

- Do not create a PR until the user confirms the workspace, bookmark name, target branch, and repository URL.
- Do not push directly to the `main` bookmark, and do not rewrite `main`. PR merge is the only thing that should advance `main`.
- Do not proceed if tests or required verification fail unless the user explicitly accepts the risk.
- Do not mark issue, task, or feature index markdown as done until verification has passed, or until the user explicitly accepts proceeding with known failures.
- Do not run destructive history operations beyond the rebase/bookmark steps below (no `jj abandon`, no workspace removal) unless the user explicitly asks.

## Process

### 1. Verify Workspace And Change

Confirm which jj workspace and change the work is in:

```bash
jj workspace list
jj status
jj log
```

Show the current workspace and the change(s) to be finished, and ask the user to confirm this is the work to turn into a PR.

### 2. Confirm Target Branch

The target branch is the branch the PR should merge into, normally the protected `main`.

Show the candidate and ask the user to confirm before syncing, diffing, or creating a PR:

```bash
jj bookmark list
```

Default to `main` unless the user names a different integration branch. Do not infer silently if ambiguous — ask.

### 3. Verify Clean Enough State

`jj` auto-snapshots the working copy, so there is no staging step. Review what will be included:

```bash
jj status
jj diff
```

If there are unintended edits in the change, ask whether to keep them, or stop. Do not discard or revert changes unless explicitly requested.

### 4. Run Verification

Run project-appropriate verification before finishing. Prefer commands documented in the issue, task, README, package scripts, or project docs.

Common defaults:

- Node: `npm test` or documented test script
- Python: `pytest`
- Go: `go test ./...`
- Rust: `cargo test`

If verification fails, report the failing command and failure summary. Stop before PR creation unless the user explicitly accepts proceeding with known failures.

### 5. Mark Current Issue And Task Done

Before creating a PR, update completion state for the work item markdown files that correspond to this work.

Find the current issue and task files from the user's request, change description, recent commits, or repository conventions. Common locations include `features/`, `issues/`, `tasks/`, `.agents/issues/`, `.agents/tasks/`, and feature-specific task directories. If a task file references a parent issue or feature index, follow those links. If the matching files are ambiguous, ask the user which issue/task should be marked done.

Update all present matching files:

- Issue markdown file: mark the current issue as done.
- Task markdown file: mark the current task as done.
- Feature index markdown file, if present: mark the corresponding issue/task entry as done.

Preserve the existing status format. For example:

- Change unchecked checklist entries from `[ ]` to `[x]`.
- Change status labels such as `status: todo`, `status: in_progress`, or `State: Open` to the repository's done/completed equivalent.
- If the file uses a table, update only the row for the current issue or task.

Do not rewrite unrelated entries or mark sibling tasks done unless they were part of the completed work. Because `jj` auto-snapshots, these markdown edits are automatically included in the current change.

### 6. Sync Onto Latest main

Fetch updated Git refs and rebase local work onto the latest `main` so the PR is based on current history:

```bash
jj git fetch
jj rebase -d main
```

Rebasing rewrites commits (new IDs) — this is normal in `jj`. If conflicts appear, resolve them or report the blocker before proceeding.

### 7. Confirm Repository And Bookmark

Before creating a PR, ask the user to confirm:

- Repository URL or identifier (provider is GitHub)
- Bookmark name to use as the PR branch (e.g. `pr/<feature>` or `<agent>/<feature>`)
- Target branch

Check the configured Git remote(s):

```bash
jj git remote list
```

If multiple remotes exist, ask which should receive the push.

### 8. Diff Against Target Branch

Summarize what changed relative to the target branch:

```bash
jj diff --from main --to @
jj log
```

Use the diff to prepare a PR summary. Focus on user-visible behavior, important implementation changes, tests, migrations, and risks.

### 9. Prepare PR Summary

Create a concise PR summary from the diff:

```markdown
## Summary

- <What changed>
- <Important implementation detail or behavior change>
- <Risk, migration, or compatibility note if relevant>

## Test Plan

- [x] <verification command or manual check>
- [ ] <unchecked follow-up, if any>

## Diff Context

- Target branch: `<target-branch>`
- Bookmark: `<bookmark>`
- Workspace: `<workspace>`
- Files changed: <count or short list>
- Work item status updates: <issue/task/feature index files marked done, or "none found">
```

If verification was not run, mark it explicitly as not run and state why.

### 10. Create Or Update Bookmark And Push

Create the bookmark at the current change, or move an existing one onto it after the rebase:

```bash
jj bookmark create <bookmark>
# or, if it already exists (e.g. updating an existing PR after rebase):
jj bookmark set <bookmark>
```

Push the bookmark to the remote:

```bash
jj git push --bookmark <bookmark>
```

Never push the `main` bookmark.

### 11. Create The GitHub PR

Before creating the PR, confirm repository, bookmark (head), target branch, PR title, and PR body.

Create the PR using the available GitHub MCP, CLI, or API tool. With the CLI the shape is:

```bash
gh pr create --repo <repo> --base <target-branch> --head <bookmark> --title "<title>" --body "<body>"
```

If the bookmark commits change later (further rebases), update the PR by re-pushing the same bookmark:

```bash
jj bookmark set <bookmark>
jj git push --bookmark <bookmark>
```

Report the PR URL.

## PR Title Guidance

Use a clear title derived from the bookmark name, issue/task title, or commit messages.

Examples:

- `Add saved search filters`
- `Implement prompt request session logging`
- `Fix metrics query timeout handling`

Avoid vague titles such as `Updates`, `Changes`, or `Work in progress` unless the user explicitly wants a draft PR.

## Report Format

After completion, report:

- Workspace
- Bookmark and target branch
- Repository, if PR was created
- PR URL, if created
- Verification commands and results
- Issue/task/feature index markdown files marked done, if any
- Any risks, skipped checks, or follow-up needed

## Principles

- Confirm workspace, bookmark, and target before acting.
- Keep `main` protected: rebase onto it, never push or rewrite it; advance it only via PR merge.
- Base PR summaries on actual diffs, not memory.
- Mark the current issue, task, and feature index done when those markdown files are present.
- Prefer passing verification before creating a PR.
- Re-push the same bookmark to update an existing PR after rebasing.
- Keep this skill focused: no workspace removal, no abandoning changes, no direct `main` pushes.
