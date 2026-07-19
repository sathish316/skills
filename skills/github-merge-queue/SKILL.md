---
name: github-merge-queue
description: Land approved GitHub PRs through a serialized merge queue. Covers enabling GitHub's native merge queue (branch protection) including its org/plan eligibility rules, hosted alternatives like Mergify for private repos, and a self-hosted git-based merge-queue worker that polls approved PRs, stacks them in a disposable branch, runs CI, drops conflicting or failing PRs, and fast-forwards main only when the stack is green. Use when changes may land on main only via approved PR and you want serialized, pre-tested integration. See jujutsu-merge-queue for the jj-native equivalent.
---

# GitHub Merge Queue

Land approved PRs on `main` through a serialized, pre-tested merge queue: process approved changes one at a time, stack each onto the latest trunk, run CI, and advance `main` only on success.

This skill covers the GitHub-native and git-based paths. For the `jj`-native equivalent (and why you might prefer it across multiple agent workspaces), see `jujutsu-merge-queue`.

## Decide Which Path

Pick the lowest-overhead option that satisfies your constraint that changes land on `main` only via approved PR:

1. **GitHub native merge queue** — zero custom tooling; enable it in branch protection. Best when eligible (see below).
2. **Mergify (hosted)** — works on private repos regardless of GitHub plan; free tier for small teams/open source.
3. **Self-hosted git worker** — costs nothing and needs no third-party app permissions, but you operate the queue. Use the bundled script.

For a handful of PRs/day the self-hosted worker (or even a manual loop) is often less overhead than wiring up a hosted queue. Native/hosted queues pay off most at higher PR volume from many contributors.

## Option 1: GitHub Native Merge Queue

Enable it via repository **Settings → Branches → branch protection rule for `main` → "Require merge queue"**. GitHub then serializes approved PRs, rebases each onto the latest trunk, runs the required checks, and merges on success — still gated on PR approval.

### Eligibility (important)

Merge queue is **organization-gated**, not simply public-vs-private:

- **Public repo + personal account** (not an org) → no merge queue.
- **Public repo owned by a free organization** → merge queue works, no cost.
- **Private repo** → requires GitHub Enterprise Cloud (not free).

If your repo lives under a personal username, the fix is to create a free GitHub organization and transfer the repo there; for public repos the queue checks repo ownership, not org plan tier.

> Verify current GitHub docs before relying on these tiers, as plan/eligibility details change.

## Option 2: Mergify (private repos without Enterprise)

If the repo must stay private and you are not on Enterprise, GitHub's native queue is unavailable. Mergify works on private repos regardless of GitHub plan, with a free tier for small teams and open source.

Tradeoff to know: Mergify does not rebuild the merge commit server-side, so the SHA that was tested is the SHA that gets merged. (GitHub's native queue has had a documented incident where the tested commit and merged commit could diverge.)

Bors-NG pioneered "test the merge result before merging" but is effectively in maintenance mode as of 2026; most teams have moved to GitHub's native queue or a commercial alternative, so it is not a good pick for a new setup.

## Option 3: Self-Hosted git Merge-Queue Worker

A worker process (cron, daemon, or GitHub Action) that:

1. Polls GitHub for PRs meeting your "eligible" criteria (approved, optionally CI-green).
2. Orders them into a queue.
3. Builds each one stacked on the last, in a disposable branch.
4. Runs/checks CI.
5. Fast-forwards `main` and (optionally) closes the PR.
6. On failure, drops that PR and retries the rest next cycle.

Run it in a dedicated clone that humans never touch:

```bash
git clone <repo> merge-queue-workspace
cd merge-queue-workspace
```

Then run one pass with the bundled script:

```bash
skills/github-merge-queue/scripts/git-merge-queue.sh \
  --base main \
  --ci-cmd "npm test" \
  --require-ci-status
```

Key options:

- `--base BRANCH` — trunk branch to advance (default `main`).
- `--attempt-branch NAME` — disposable stacking branch (default `mq-attempt`).
- `--ci-cmd "CMD"` — command run as the CI gate against each stacked PR; non-zero exit drops that PR.
- `--require-ci-status` — only consider PRs whose GitHub `statusCheckRollup` checks are all passing (or have none).
- `--search QUERY` — extra `gh` PR search filter (default `review:approved`).
- `--dry-run` — do everything except pushing to trunk.

### What the worker does each cycle

```bash
git fetch origin main
git checkout -B mq-attempt origin/main
# eligible_prs = approved (and optionally CI-green) PRs via: gh pr list --search "is:open review:approved" --json number,headRefName,statusCheckRollup
# for each PR in order:
#   git fetch origin pull/<n>/head:pr-<n>
#   git merge --no-ff pr-<n>      -> on conflict: git merge --abort, comment, drop
#   run CI                        -> on failure: git reset --hard HEAD~1, comment, drop
git push origin mq-attempt:main   # only if everything still on the stack passed
```

### Mechanics worth naming

- **Stacking** = sequential `git merge`/`git rebase` of each eligible PR's head onto the previous result, in a disposable branch.
- **State is implicit** in the branch tip. If PR #3 fails, either drop just #3 and re-stack #4 on #2's result, or (cheaper) drop everything after the failure and retry next cycle.
- **CI check** = read `statusCheckRollup` from the PR via `gh`/API; "build your own" CI means actually running tests against the stacked branch.
- **Crash recovery** = redo the fetch and re-stack. git has no native concept of queue position, so any bookkeeping (JSON file, DB row, branch-naming convention) is yours to invent.
- **Conflicts** go through normal 3-way merge; a conflicting PR is just dropped from this cycle, no special tooling.

## git vs jj Worker

The git version is the more battle-tested path and what most existing tools (GitHub's queue, Mergify, Bors) are built on — nothing novel to debug. The `jj` version (see `jujutsu-merge-queue`) buys cheaper failure recovery (real `undo`, automatic descendant rebasing when evicting a bad PR from the middle of the stack) at the cost of custom tooling, since nothing off-the-shelf speaks `jj` merge-queue semantics yet. If you want maturity and existing integrations, build the git version first.

## Hard Rules

- Only advance `main` when the entire surviving stack passes its conflict and CI gates.
- Run the worker in a dedicated clone/workspace; never against a human's working tree.
- Never push to trunk on a dry run.
- Drop conflicting/failing PRs from the cycle and report them; do not attempt automatic conflict resolution.
- Do not enable native merge queue or change branch protection without the user's confirmation.

## Report Format

After a run, report:

- Path used (native queue, Mergify, or self-hosted worker).
- Trunk branch and its new tip (or "unchanged").
- PRs merged this cycle.
- PRs dropped this cycle and why (conflict vs CI).
- Whether the run was a dry run.

## Principles

- Serialize integration; test each change against the latest trunk.
- Advance `main` only on a green stack.
- Prefer the native queue when eligible; otherwise Mergify (private) or the self-hosted worker.
- Keep the queue's working area isolated from human edits.
