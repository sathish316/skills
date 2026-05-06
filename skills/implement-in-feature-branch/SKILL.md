---
name: implement-in-feature-branch
description: Implement one issue or task file on a normal git feature branch. Use when the user asks to implement an issue or task without a worktree, wants git-flow style branch handling, or wants branch parent selection based on issue/task relationships. If the input issue or task file is missing, ask for it before proceeding.
---

# Implement In Feature Branch

Implement a single issue or task file on a dedicated git feature branch in the current checkout.

Use this when the user wants normal branch-based implementation rather than an isolated worktree.

## Inputs

Accept either:

- An issue file from `docs/issues/...`
- A task file produced from an issue

If no issue or task file is provided, ask the user for the file before proceeding.

## Branch Strategy

Use a dedicated branch for the work. Do not implement directly on `main`, `master`, `develop`, or another protected base branch unless the user explicitly approves.

Branch naming defaults:

- Issue file: `feature/<issue-id-or-slug>`
- Task file: `task/<issue-id-or-slug>-<task-number-or-slug>`

### Parent Branch Selection

Choose the parent branch using this order:

1. If the input file declares `parent_branch`, use that branch.
2. If implementing a task file that depends on another task and that parent/dependency task has an existing branch, use the parent task branch.
3. If implementing a task file and the parent issue has an existing branch, use the parent issue branch.
4. If the current branch appears to be the parent task branch or parent issue branch for this task, use the current branch.
5. If implementing an issue, use the current branch only if it is already the intended feature integration branch.
6. Otherwise use the repository's normal integration branch: `develop` if present, else `main`, else `master`.

If the correct parent is ambiguous, stop and ask the user which branch to use. Do not guess when branch ancestry affects merge safety.

## Process

### 1. Read the Input File

Read the issue or task file and identify:

- `issue_id`, `feature_id`, `parent_feature`, or parent issue metadata
- Task number and task dependencies, if this is a task file
- Acceptance criteria and verification steps
- Likely files or modules to touch
- Human review gates

If required context is missing, ask for the parent issue or feature file.

### 2. Check Repository State

Run `git status --short` before branching.

If the worktree has unrelated changes, do not overwrite or revert them. Ask the user whether to proceed, stash, commit, or switch strategy.

### 3. Create or Reuse the Feature Branch

Determine the parent branch using the rules above.

If already on the correct branch, continue after confirming it is not protected. Otherwise:

```bash
git fetch --all --prune
git switch <parent-branch>
git pull --ff-only
git switch -c <new-branch>
```

If the branch already exists locally, ask whether to reuse it or create a new branch.

### 4. Verify Baseline

Run the smallest relevant baseline verification before editing. Prefer project-specific commands if documented; otherwise detect common commands:

- Node: `npm test` or documented test script
- Python: `pytest`
- Go: `go test ./...`
- Rust: `cargo test`

If baseline tests fail, report the failure and ask whether to proceed or investigate first.

### 5. Implement

Make the requested code changes according to the issue or task file.

Keep the implementation scoped to the input file. Do not opportunistically implement sibling issues or unrelated cleanup.

### 6. Verify

Run the verification specified by the issue or task file. Also run focused tests for touched areas.

If verification fails, fix the issue or explain the blocker. Do not claim completion until verification passes or the user accepts the residual risk.

### 7. Report

Report:

- Branch name
- Input file implemented
- Files changed
- Verification run and result
- Any follow-up issues or review gates

## Principles

- One issue or task per branch unless the user asks to batch work.
- Ask when parent branch selection is ambiguous.
- Keep protected branches clean.
- Never revert unrelated user changes.
- Prefer small, reviewable commits and branches.
