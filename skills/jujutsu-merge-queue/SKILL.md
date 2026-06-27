---
name: jujutsu-merge-queue
description: Run a serialized merge queue for approved GitHub PRs using Jujutsu (jj). Covers a manual local merge queue from the main workspace and an automated jj-based merge-queue worker that stacks approved PRs onto trunk, tests each against the latest tip, drops conflicting or failing PRs, and advances the main bookmark only when the stack is green. Use when an agent develops features across multiple jj workspaces and wants to serialize integration into main locally with jj instead of, or ahead of, a hosted merge queue. See github-merge-queue for the GitHub-native / git-based equivalent.
---

# Jujutsu Merge Queue

Serialize integration of approved PRs into `main` using Jujutsu (`jj`). The essence of a merge queue is: process approved changes one at a time, rebase/stack each onto the latest trunk, test it, and advance `main` only on success.

This skill is the `jj`-native counterpart of `github-merge-queue`. It builds on the workspace/bookmark/rebase commands from `jujutsu-basics`. Prefer this when you already run `jj` across multiple agent workspaces and want local control over integration.

## When To Use

- You develop features across multiple `jj` workspaces (`workspace1..N`), each with its own feature bookmark and GitHub PR.
- Changes may land on `main` only after PR approval, and you want them to land **pre-rebased and tested** against the latest trunk.
- You want cheaper failure recovery than git: `jj` records conflicts as first-class commit state and gives you `jj op log` / `jj undo` for clean rollback when the worker dies mid-run.

If your org mandates the hosted GitHub merge queue, or you want maximum ecosystem maturity, use `github-merge-queue` instead.

## Mental Model

- `main` is the trunk bookmark. It advances only when a tested stack is green.
- Each approved PR is a feature bookmark pushed from a workspace.
- "Stacking" = rebasing each eligible PR's commits onto the result of the previous one, in order.
- The queue can run as **one more jj workspace** pointed at the same repo (`jj workspace add`), or as a dedicated clone — no separate git worktree machinery needed.

## Option 1: Manual Local Merge Queue

From the main workspace, after PRs are approved, integrate one feature at a time. Repeat per feature, rebasing each onto the new `main` tip in order:

```bash
jj git fetch
jj new main -m "merge-queue: feature1"
jj rebase -d main -s feature1
# run tests against the working copy
jj bookmark set main -r @
jj git push --bookmark main
```

Serialize integration, test each change against the latest trunk, and only advance `main` on success. This is the whole idea of a merge queue done by hand — good for a handful of workspaces where wiring up a worker is more overhead than the queue itself.

## Option 2: Automated jj Merge-Queue Worker

For repeatable runs, use the bundled worker script. It performs one full pass: fetch, find eligible approved PRs, stack each onto trunk, gate on conflicts and (optionally) CI, drop the failures, and advance `main` only if the surviving stack is green.

```bash
skills/jujutsu-merge-queue/scripts/jj-merge-queue.sh \
  --base main \
  --ci-cmd "npm test" \
  --require-ci-status
```

Key options:

- `--base BOOKMARK` — trunk bookmark to advance (default `main`).
- `--ci-cmd "CMD"` — command run as the CI gate against each stacked PR; non-zero exit drops that PR.
- `--require-ci-status` — only consider PRs whose GitHub `statusCheckRollup` checks are all passing (or have none).
- `--search QUERY` — extra `gh` PR search filter (default `review:approved`).
- `--dry-run` — do everything except pushing the trunk bookmark.

Run it inside a dedicated workspace/clone that humans never edit:

```bash
jj git clone <repo> merge-queue-workspace
cd merge-queue-workspace
# or, since the queue is just another working copy:
jj workspace add ../merge-queue
```

### What the worker does each cycle

1. `jj git fetch` to import the latest refs.
2. Query eligible PRs: `gh pr list --state open --search "review:approved" --json number,headRefName,statusCheckRollup`.
3. For each PR in order: `jj new -m "..." <base>` then `jj rebase -d @ -s "<headRef>@origin"` to stack it.
4. Detect conflicts directly on the commit (`jj log -T 'if(conflict, ...)'`) — no parsing of merge exit codes.
5. Run the CI gate; on conflict or failure, comment on the PR and drop it from this cycle.
6. Advance the stack pointer to the green tip.
7. `jj bookmark set main -r <tip>` and `jj git push --bookmark main` only if the stack survived.

## Why jj For The Queue Worker

- **Conflict detection**: commits hold conflicts as first-class state; check programmatically with `jj log` instead of branching on `git merge` exit codes.
- **Undo/recovery**: `jj op log` + `jj undo` give a reliable operation history. Recovering from "the worker died at PR #3" is a clean rollback, not reasoning about detached HEADs.
- **Re-stacking**: `jj rebase` automatically rebases descendants — drop a failed PR from the middle and `jj` re-parents what follows, no manual replay.
- **Working copy / workspace model**: run the queue as one more workspace against the same repo; no separate clone required.
- **Colocated repo**: `jj` runs colocated with `.git`, so `gh` and git-based CI tooling work unmodified.

Tradeoff: nothing off-the-shelf speaks `jj`'s merge-queue semantics yet, so you build this rather than configure it. For ecosystem maturity and zero custom tooling, see `github-merge-queue`.

## Hard Rules

- Only advance `main` when the entire surviving stack passes its conflict and CI gates.
- Run the worker in a dedicated workspace/clone; do not run it against a workspace a human is editing.
- Never push `main` on a dry run.
- Drop conflicting/failing PRs from the cycle and report them; do not attempt automatic conflict resolution.

## Report Format

After a run, report:

- Trunk bookmark and its new tip (or "unchanged").
- PRs merged this cycle.
- PRs dropped this cycle and why (conflict vs CI).
- Whether the run was a dry run.

## Principles

- Serialize integration; test each change against the latest trunk.
- Advance `main` only on a green stack.
- Prefer the manual flow for a few workspaces; use the worker for repeatable automation.
- Lean on `jj op log` / `jj undo` for recovery instead of fragile SHA bookkeeping.
