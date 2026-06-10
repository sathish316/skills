---
name: finish-work-in-branch-and-create-pr
description: Finish completed work on the current git branch by confirming source and target branches, marking current issue/task/feature index markdown as done when present, diffing against the target branch, generating a PR summary, and either creating a GitHub or Bitbucket pull request or merging locally. Use when implementation is complete and the user wants to finish work, create a PR, open a pull request, merge locally, or prepare branch changes for review.
---

# Finish Work In Branch And Create PR

Finish completed work from the current git branch by verifying state, confirming the target branch and repository, summarizing the diff, and either creating a pull request or merging locally.

## Hard Rules

- Do not create a PR until the user confirms the current branch, target branch, origin provider, and repository URL.
- Do not merge locally until the user confirms the target branch.
- Do not proceed if tests or required verification fail unless the user explicitly accepts the risk.
- Do not mark issue, task, or feature index markdown as done until verification has passed, or until the user explicitly accepts proceeding with known failures.
- Do not force-push unless the user explicitly asks.
- Do not delete branches or clean up worktrees in this skill.

## Process

### 1. Verify Current Branch

Determine the current branch:

```bash
git branch --show-current
```

Show the branch to the user and ask them to confirm it is the source branch for the PR or local merge.

If the current branch is `main`, `master`, `develop`, or another protected branch, stop and ask the user whether they really intend to finish work from that branch. Do not proceed without explicit confirmation.

### 2. Confirm Target Branch

The target branch is the branch the PR should merge into.

Recommend a likely target branch by finding which candidate branch the current branch appears to be based on. Check common integration branches first, then use merge-base recency and commit distance to make a recommendation:

```bash
git fetch --all --prune
git branch --list main master develop
git branch -r --list '*/main' '*/master' '*/develop'
git merge-base HEAD main 2>/dev/null
git merge-base HEAD master 2>/dev/null
git merge-base HEAD develop 2>/dev/null
git rev-list --count <candidate-branch>..HEAD
```

Prefer the candidate branch that has a plausible merge-base with `HEAD` and the smallest sensible commit distance. If the current branch has an upstream configured, also consider the upstream branch and its remote's default branch.

Show the recommended target branch and ask the user to confirm it before diffing, creating a PR, or merging locally.

If the user prefers another target branch, list available local and remote branches and let them choose:

```bash
git branch --format='%(refname:short)'
git branch -r --format='%(refname:short)'
```

If the target branch is still ambiguous, ask the user. Do not infer silently.

### 3. Verify Clean Enough State

Check repository state:

```bash
git status --short
```

If there are uncommitted changes, show the changed files and ask whether to commit them, leave them uncommitted for a draft PR, or stop. Prefer committing before PR creation or local merge.

Do not discard or revert changes unless explicitly requested.

### 4. Run Verification

Run project-appropriate verification before offering finish options. Prefer commands documented in the issue, task, README, package scripts, or project docs.

Common defaults:

- Node: `npm test` or documented test script
- Python: `pytest`
- Go: `go test ./...`
- Rust: `cargo test`

If verification fails, report the failing command and failure summary. Stop before PR creation or local merge unless the user explicitly accepts proceeding with known failures.

### 5. Mark Current Issue And Task Done

Before creating a PR or merging locally, update completion state for the work item markdown files that correspond to the branch.

Find the current issue and task files from the user's request, branch name, recent commits, or repository conventions. Common locations include `features/`, `issues/`, `tasks/`, `.agents/issues/`, `.agents/tasks/`, and feature-specific task directories. If a task file references a parent issue or feature index, follow those links. If the matching files are ambiguous, ask the user which issue/task should be marked done.

Update all present matching files:

- Issue markdown file: mark the current issue as done.
- Task markdown file: mark the current task as done.
- Feature index markdown file, if present: mark the corresponding issue/task entry as done.

Preserve the existing status format. For example:

- Change unchecked checklist entries for the completed issue/task from `[ ]` to `[x]`.
- Change frontmatter/status labels such as `status: todo`, `status: in_progress`, `Status: In Progress`, or `State: Open` to the repository's done/completed equivalent.
- If the file uses a table, update only the row for the current issue or task.

Do not rewrite unrelated entries, reorder feature indexes, or mark sibling tasks done unless they were part of the completed work. Include these markdown status updates in the branch changes before PR creation or local merge.

### 6. Confirm Origin Provider And Repository URL

Before creating a PR, ask the user to confirm:

- Origin provider: `github` or `bitbucket`
- Repository URL or repository identifier
- Source branch
- Target branch

Assume the necessary MCP, CLI, or API tools for GitHub or Bitbucket are available, but still confirm which provider and repo to use.

If multiple git remotes exist, show them and ask which remote/repo should receive the PR:

```bash
git remote -v
```

### 7. Diff Against Target Branch

Fetch the target branch, then diff the current branch against it:

```bash
git fetch --all --prune
git diff --stat <target-branch>...HEAD
git diff --name-only <target-branch>...HEAD
git log --oneline <target-branch>..HEAD
```

Use the diff to prepare a PR summary. Focus on user-visible behavior, important implementation changes, tests, migrations, and risks.

### 8. Prepare PR Summary

Create a concise PR summary from the target-branch diff:

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
- Source branch: `<source-branch>`
- Files changed: <count or short list>
- Work item status updates: <issue/task/feature index files marked done, or "none found">
```

If verification was not run, mark it explicitly as not run and state why.

### 9. Present Finish Options

After verification and diff summary, present exactly these options:

```text
Work on <source-branch> is ready against <target-branch>. What would you like to do?

1. Create a GitHub PR
2. Create a Bitbucket PR
3. Merge locally into <target-branch>

Which option?
```

Do not include a do-nothing option in this skill.

### 10. Execute Selected Option

#### Option 1: Create a GitHub PR

Before creating the PR, confirm:

- Provider: GitHub
- Repository URL or identifier
- Source branch
- Target branch
- PR title
- PR body

Push the source branch if needed, then create the PR using the available GitHub MCP, CLI, or API tool.

If using CLI, the command shape is:

```bash
git push -u <remote> <source-branch>
gh pr create --repo <repo> --base <target-branch> --head <source-branch> --title "<title>" --body "<body>"
```

Report the PR URL.

#### Option 2: Create a Bitbucket PR

Before creating the PR, confirm:

- Provider: Bitbucket
- Repository URL or workspace/repo identifier
- Source branch
- Target branch
- PR title
- PR body

Push the source branch if needed, then create the PR using the available Bitbucket MCP, CLI, or API tool.

If using CLI or API, use the equivalent of:

```bash
git push -u <remote> <source-branch>
# create Bitbucket PR with source=<source-branch>, destination=<target-branch>, title=<title>, body=<body>
```

Report the PR URL.

#### Option 3: Merge Locally

Before merging, confirm the target branch one more time.

Then:

```bash
git switch <target-branch>
git pull --ff-only
git merge <source-branch>
```

Run verification again on the merged result. If verification passes, report the merge result. If verification fails, report the failure and do not delete the source branch.

Do not delete the source branch unless the user explicitly asks.

## PR Title Guidance

Use a clear title derived from the branch name, issue/task title, or commit messages.

Examples:

- `Add saved search filters`
- `Implement prompt request session logging`
- `Fix metrics query timeout handling`

Avoid vague titles such as `Updates`, `Changes`, or `Work in progress` unless the user explicitly wants a draft PR.

## Report Format

After completion, report:

- Source branch
- Target branch
- Provider and repository, if PR was created
- PR URL, if created
- Merge commit or result, if merged locally
- Verification commands and results
- Issue/task/feature index markdown files marked done, if any
- Any risks, skipped checks, or follow-up needed

## Principles

- Confirm branch and target before acting.
- Confirm provider and repository before creating PRs.
- Base PR summaries on actual diffs, not memory.
- Mark the current issue, task, and feature index done when those markdown files are present.
- Prefer passing verification before PR or merge.
- Keep finish-work focused: no worktree cleanup, no branch deletion, no discard flow.
