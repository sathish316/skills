---
name: jujutsu-basics
description: Concise Jujutsu (jj) workflows and commands for agent development against a Git-backed repo. Covers creating an agent workspace, committing changes for a feature, creating a bookmark, opening a GitHub PR, and refetching/rebasing onto the latest main. Use when the user wants to work with jj, set up an isolated jj workspace per agent, push a jj bookmark as a PR branch, or sync local jj history with Git main.
---

# Jujutsu Basics

Concise reference for the core Jujutsu (`jj`) workflows an agent uses when developing against a Git-backed repository.

## Mental Model

- `jj` is the local workflow engine; Git remains the storage and remote (GitHub/GitLab) compatibility layer.
- Work is **change-centric**, not branch-centric. Agents commit freely and rebase often; commit IDs are expected to churn.
- `main` is a protected integration branch. Agents never push directly to `main` and never rewrite it; they only rebase onto the latest `main`.
- **Bookmarks** are lightweight Git branch pointers. Create one only when a change needs to be shared/exported as a PR branch.
- Each agent gets: its own jj workspace, its own Git branch (bookmark), and its own PR lifecycle.

## Safety / Recovery

`jj` records every operation. To inspect or undo a mistaken operation:

```bash
jj op log
jj undo
```

Prefer `jj undo` over manual history surgery when an operation goes wrong.

## 1. Create Agent Workspace

A workspace gives an agent an independent working copy that shares the same Git-backed object store.

First-time setup in an existing Git repo (colocate so Git tooling keeps working):

```bash
jj git init --colocate
```

Add a separate workspace per agent and switch into it:

```bash
jj workspace add ../agent-a
cd ../agent-a
```

Each workspace has independent working-copy and checkout state but shares history, so agents can evolve commits in parallel without filesystem contention.

To list workspaces:

```bash
jj workspace list
```

## 2. Commit / Make Changes for a Feature

`jj` auto-snapshots the working copy, so the loop is simply: edit, inspect, commit. Prefer small, frequent commits.

Inspect the current state and diff:

```bash
jj status
jj diff
```

Create a commit with a message (finalizes the current change and starts a new one):

```bash
jj commit -m "Implement feature"
```

View the change graph:

```bash
jj log
```

While iterating, agents can freely reshape history without destabilizing shared work:

```bash
jj edit     # resume editing a specific change
jj split    # split a change into smaller ones
jj squash   # fold a change into its parent
jj abandon  # discard a change
```

## 3. Create Bookmark for a Feature

A bookmark is the Git branch that will become the PR branch. Create it only when the work is ready to be shared.

Create a new bookmark at the current change:

```bash
jj bookmark create pr/feature1
```

Move/update an existing bookmark to the current change (e.g. after rebasing):

```bash
jj bookmark set pr/feature1
# or
jj bookmark move pr/feature1
```

Use an agent-scoped name when running multiple agents, e.g. `agent-a/auth-refactor`.

## 4. Create GitHub PR for a Feature

Push the bookmark to create/update the corresponding Git branch on the remote:

```bash
jj git push --bookmark pr/feature1
```

Then open the PR on GitHub from `pr/feature1` into `main` (via the GitHub UI, `gh pr create`, or an available GitHub tool).

After later rebases change the commits, re-push the same bookmark and the GitHub PR updates automatically:

```bash
jj bookmark set pr/feature1
jj git push --bookmark pr/feature1
```

Do not push directly to the `main` bookmark; let PR merge be the only thing that advances `main`.

## 5. Refetch Changes from Git main

The core sync loop: import updated Git refs, then rebase local work onto the new `main`.

```bash
jj git fetch
jj rebase -d main
```

Often `jj rebase` alone is enough when the destination is implied by repo config:

```bash
jj rebase
```

This is the `jj` equivalent of `git fetch origin && git rebase origin/main`, but rebasing is first-class and descendant changes are rebased automatically. Repeat `jj git fetch` + `jj rebase` as the steady-state sync loop. Rebasing rewrites commits (new IDs) — this is normal in `jj`.

## Quick Reference

| Goal | Commands |
| --- | --- |
| Create agent workspace | `jj git init --colocate`; `jj workspace add ../agent-a` |
| Inspect / commit changes | `jj status`; `jj diff`; `jj commit -m "..."`; `jj log` |
| Create / update bookmark | `jj bookmark create pr/feature1`; `jj bookmark set pr/feature1` |
| Push for GitHub PR | `jj git push --bookmark pr/feature1` |
| Sync with main | `jj git fetch`; `jj rebase -d main` |
| Recover | `jj op log`; `jj undo` |

## Principles

- Keep `main` protected: only rebase onto it; advance it only via PR merge.
- Commit small and often; reshape history freely with rebase/split/squash/abandon.
- Create bookmarks only for work that becomes a PR.
- One workspace + one bookmark + one PR per agent for clean parallelism.
- Re-push the same bookmark to update an existing PR after rebasing.
