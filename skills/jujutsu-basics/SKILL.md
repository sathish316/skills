---
name: jujutsu-basics
description: Concise Jujutsu (jj) workflows and commands for agent development against a Git-backed repo. Covers creating an agent workspace, committing changes for a feature, creating a bookmark, opening a GitHub PR, refetching/rebasing onto the latest main, amending a feature to incorporate PR feedback, and an optional mentor mode that guides the user step by step instead of executing for them. Use when the user wants to work with jj, set up an isolated jj workspace per agent, push a jj bookmark as a PR branch, sync local jj history with Git main, or update an existing PR after review feedback; activate mentor mode when the user asks to "mentor me" or "help me do X in jujutsu".
---

# Jujutsu Basics

Concise reference for the core Jujutsu (`jj`) workflows an agent uses when developing against a Git-backed repository.

## Mentor Mode (optional)

By default, just run the documented commands to get the user's `jj` work done. **Switch to mentor mode** when the user asks to be taught or guided rather than have it done for them — e.g. "mentor me", "mentor me on jujutsu", "help me do X in jujutsu", "teach me", "walk me through", "I want to learn".

In mentor mode, guide; do not silently execute:

- Explain the **why** using this skill's mental model (change-centric workflow, bookmarks as PR pointers, protected `main`, the fetch+rebase sync loop), not just the command to type.
- Hand the user one step at a time. Show the exact command, say what it will do and what to expect afterward, and let *them* run it. Ask them to share the output before moving on.
- Prefer guiding questions ("what does `jj status` show?", "is this change ready to become a PR yet?") over doing it for them.
- Do **not** run state-changing commands (`jj commit`, `jj rebase`, `jj bookmark set`, `jj git push`) on their behalf while mentoring unless they explicitly ask you to take over. Read-only inspection (`jj status`, `jj log`, `jj op log`) to orient is fine if useful.
- Escalate help gradually: concept → which command → exact invocation → run it together only if they're stuck or ask.
- Confirm understanding at decision points (e.g. when to create a bookmark, follow-up commit vs in-place amend) instead of choosing for them.

Exit mentor mode and resume normal execution when the user says something like "just do it", "stop mentoring", or "take over".

Suggested mentor response shape:

```markdown
**Goal:** [what we're trying to achieve]

**Why:** [the relevant jj concept]

**Your next step:** `<command>` — [what it does, what to expect]

**Then tell me:** [what output to check before the next step]
```

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

## 6. Amend a Feature / Incorporate PR Feedback

The PR is driven by the **bookmark**, not by whatever the workspace currently shows. To update an already-pushed feature, re-point the workspace at the feature, revise its history, move the bookmark, and push again — the existing PR updates automatically.

Scenario: `feature1` bookmark points at `A → B → C` with a PR open, but the workspace has since moved on to other work (e.g. a `feature2` commit `D`). Feedback arrives on the `feature1` PR.

### Option 1 (recommended): add a follow-up commit

Switch the workspace back to the feature, add new commit(s), then move the bookmark forward. The in-progress work (`D`) is not lost — it still exists in history.

```bash
jj workspace update <workspace> -r feature1   # re-point this workspace at the feature1 tip (C)
# make the requested changes
jj new                                         # new commit on top of feature1 -> C'
jj bookmark set feature1 -r @                  # move the bookmark to the updated tip (@ = current change)
jj git push                                    # updates the existing PR automatically
```

Repeat as needed; squash the follow-ups later if you want a clean history (`jj squash`).

### Option 2: amend the existing commit directly

If you want to revise commit `C` in place rather than stacking a `C'`:

```bash
jj edit feature1                  # put the working copy directly on C
# make the requested changes
jj describe -m "updated feature1" # update the commit message if needed
jj git push                       # rewrites C; the bookmark moves with it implicitly
```

### Mental model

- The workspace is just your current editing context — re-pointing it is safe and non-destructive.
- The bookmark is what the PR tracks; pushing it after revision updates the PR.
- Commits are immutable unless you explicitly `edit`/rewrite them, so you never "go back" destructively — you re-point the workspace and rebuild history cleanly.

## Quick Reference

| Goal | Commands |
| --- | --- |
| Create agent workspace | `jj git init --colocate`; `jj workspace add ../agent-a` |
| Inspect / commit changes | `jj status`; `jj diff`; `jj commit -m "..."`; `jj log` |
| Create / update bookmark | `jj bookmark create pr/feature1`; `jj bookmark set pr/feature1` |
| Push for GitHub PR | `jj git push --bookmark pr/feature1` |
| Sync with main | `jj git fetch`; `jj rebase -d main` |
| Amend / incorporate PR feedback | `jj workspace update <ws> -r feature1`; `jj new`; `jj bookmark set feature1 -r @`; `jj git push` (or `jj edit feature1`; `jj describe -m "..."`; `jj git push`) |
| Recover | `jj op log`; `jj undo` |

## Bash/Zsh Aliases

Optional shell shortcuts for the most-used commands above. Add the ones you want to `~/.bashrc` or `~/.zshrc` (or a sourced `~/.jj_aliases`), then reload with `source ~/.bashrc` / `source ~/.zshrc`.

Guidelines:

- Plain `alias` works when you only ever append arguments at the end (e.g. `jjbc my-bookmark`).
- Use a shell **function** when an argument goes in the middle of the command (e.g. picking a workspace to switch). Functions work in both bash and zsh.
- Keep the `jj`-prefixed naming so the shortcuts are easy to discover and don't collide with `git` habits.
- These are conveniences only — the skill's documented full commands remain the source of truth.

TODO — aliases to consider adding:

- [ ] `alias jjs='jj status'` — current change, working-copy diff summary, conflicts.
- [ ] `alias jjd='jj diff'` — preview working-copy changes.
- [ ] `alias jjl='jj log'` — change graph.
- [ ] `alias jjf='jj git fetch'` — import latest Git refs.
- [ ] `alias jjsync='jj git fetch && jj rebase -d main'` — the steady-state sync loop (fetch + rebase onto `main`).
- [ ] `alias jjbc='jj bookmark create'` — create a bookmark: `jjbc pr/feature1`.
- [ ] `alias jjbs='jj bookmark set'` — move a bookmark: `jjbs pr/feature1 -r @`.
- [ ] `alias jjpush='jj git push --bookmark'` — push a bookmark as a PR branch: `jjpush pr/feature1`.
- [ ] `alias jjundo='jj undo'` and `alias jjop='jj op log'` — recovery.
- [ ] Workspace switch (needs a function — argument is in the middle):

```bash
# usage: jjws <workspace> <revision>   e.g. jjws workspace1 feature1
jjws() { jj workspace update "$1" -r "$2"; }
```

- [ ] Commit + describe in one step (function, takes a message):

```bash
# usage: jjci "commit message"
jjci() { jj commit -m "$1"; }
```

## Principles

- Keep `main` protected: only rebase onto it; advance it only via PR merge.
- Commit small and often; reshape history freely with rebase/split/squash/abandon.
- Create bookmarks only for work that becomes a PR.
- One workspace + one bookmark + one PR per agent for clean parallelism.
- Re-push the same bookmark to update an existing PR after rebasing.
- To incorporate PR feedback, re-point the workspace at the feature, revise history, move the bookmark, and push — the PR is driven by the bookmark.
