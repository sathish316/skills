---
name: implement-in-worktree
description: Implement one issue or task file in an isolated git worktree. Use when the user asks to implement an issue or task with worktree isolation, when the current workspace is dirty, or when parallel implementation may be useful. If the input issue or task file is missing, ask for it before proceeding.
---

# Implement In Worktree

Implement a single issue or task file in an isolated git worktree.

## Inputs

Accept either:

- An issue file from `docs/issues/...`
- A task file produced from an issue

If no issue or task file is provided, ask the user for the file before proceeding.

## Branch Strategy

Create one branch and one worktree for the input issue or task.

Branch naming defaults:

- Issue file: `feature/<issue-id-or-slug>`
- Task file: `task/<issue-id-or-slug>-<task-number-or-slug>`

Choose the parent branch using this order:

1. If the input file declares `parent_branch`, use that branch.
2. If implementing a task file that depends on another task and that parent/dependency task has an existing branch, use the parent task branch.
3. If implementing a task file and the parent issue has an existing branch, use the parent issue branch.
4. If implementing a task file and the user says tasks should stack, use the previous completed task branch.
5. If implementing an issue, use the feature integration branch if one is declared or obvious.
6. Otherwise use `develop` if present, else `main`, else `master`.

If parent branch selection is ambiguous, ask the user before creating the worktree.

## Worktree Directory Selection

Follow this priority order:

1. Use `.worktrees/` if it exists.
2. Else use `worktrees/` if it exists.
3. Else check `CLAUDE.md`, `AGENTS.md`, or project docs for a worktree directory preference.
4. Else ask the user whether to use `.worktrees/` or a global location such as `~/.config/devskills/worktrees/<project-name>/`.

For project-local directories, verify the directory is gitignored before creating the worktree:

```bash
git check-ignore -q .worktrees 2>/dev/null || git check-ignore -q worktrees 2>/dev/null
```

If the chosen project-local worktree directory is not ignored, ask the user before modifying `.gitignore`.

## Process

### 1. Read the Input File

Read the issue or task file and identify:

- `issue_id`, `feature_id`, `parent_feature`, or parent issue metadata
- Task number and dependencies, if this is a task file
- Acceptance criteria and verification steps
- Likely files or modules to touch
- Human review gates

If required context is missing, ask for the parent issue or feature file.

### 2. Create the Worktree

Create a branch from the selected parent branch and attach it to a worktree path derived from the branch name:

```bash
git fetch --all --prune
git worktree add <worktree-path> -b <new-branch> <parent-branch>
```

If the branch already exists, ask whether to reuse it, create a differently named branch, or stop.

### 3. Install and Verify Baseline

Inside the worktree, run project setup only when needed and safe:

- Node: install dependencies if missing and project expects it
- Python: use the existing environment or documented setup
- Go: `go mod download` if needed
- Rust: `cargo build` if needed

Run the smallest relevant baseline verification before editing. If tests fail before changes, report the failure and ask whether to proceed or investigate.

### 4. Implement

Make the requested code changes in the worktree only.

Keep the implementation scoped to the input file. Do not edit the original checkout for this work.

### 5. Verify

Run the issue or task verification and focused tests for touched areas.

If verification fails, fix the issue or explain the blocker. Do not claim completion until verification passes or the user accepts the residual risk.

### 6. Report

Report:

- Worktree path
- Branch name and parent branch
- Input file implemented
- Files changed
- Verification run and result
- Whether the worktree should be kept, merged, or used for a PR

## Principles

- Use worktrees when isolation or parallelism matters.
- Verify project-local worktree directories are ignored.
- Ask before modifying `.gitignore` or choosing an ambiguous parent branch.
- Never revert unrelated user changes.
- Keep one issue or task per worktree unless the user asks to batch work.
