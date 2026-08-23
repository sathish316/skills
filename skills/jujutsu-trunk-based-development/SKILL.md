---
name: jujutsu-trunk-based-development
description: Trunk-based development with Jujutsu (jj) for simple or solo projects where you mostly push changes directly to main and only occasionally open a PR for review. Covers the core mental model (main tracks origin/main, bookmark points to a commit, PR is just a GitHub view), the direct-to-main loop, the occasional review-PR flow with three merge strategies (GitHub merge, local jj-native merge, hybrid), the constant fetch+rebase sync loop, graph visualization, cleanup, and an optional mentor mode that guides the user step by step instead of executing for them. Use for lightweight trunk-based workflows, and activate mentor mode when the user asks to "mentor me" or "help me do X in jujutsu". Not for multi-agent workspaces, merge queues, or finishing branch work — see jujutsu-basics and the other jj skills for those.
---

# Jujutsu Trunk-Based Development

A lightweight Jujutsu (`jj`) workflow for **simple or solo projects**: keep one trunk (`main`), push most changes straight to it, and only spin up a PR when you actually want review or CI.

This skill is intentionally narrow. Do not mix it with the other `jj` skills:

- `jujutsu-basics` — general `jj` command reference and multi-agent workspace setup.
- `jujutsu-merge-queue` / `github-merge-queue` — serialized integration of many approved PRs.
- `finish-work-in-jujutsu-workspace` — formal finish-and-PR flow.

Use **this** skill when the answer to "do I need a PR for this change?" is usually "no".

## Mentor Mode (optional)

By default, just run the documented commands to get the user's trunk-based work done. **Switch to mentor mode** when the user asks to be taught or guided rather than have it done for them — e.g. "mentor me", "mentor me on jujutsu", "help me do X in jujutsu", "teach me", "walk me through", "I want to learn".

In mentor mode, guide; do not silently execute:

- Explain the **why** behind each step using this skill's mental model (the PR is a view of the graph; merge = move `main` forward; keep `main` fast-forwardable), not just the command to type.
- Hand the user one step at a time. Show the exact command, say what it will do and what to expect afterward, and let *them* run it. Ask them to share the output before moving on.
- Prefer guiding questions ("what does `jj status` show now?", "where do you want `main` to point?") over doing it for them.
- Do **not** run state-changing commands (`jj bookmark set`, `jj git push`, merges, `jj rebase`) on their behalf while mentoring unless they explicitly ask you to take over. Read-only inspection (`jj status`, `jj log`) to orient is fine if useful.
- Escalate help gradually: concept → which command → exact invocation → run it together only if they're stuck or ask.
- Confirm understanding at decision points (direct push vs review PR; which of the three merge options) instead of choosing for them.

Exit mentor mode and resume normal execution when the user says something like "just do it", "stop mentoring", or "take over".

Suggested mentor response shape:

```markdown
**Goal:** [what we're trying to achieve]

**Why:** [the relevant trunk-based / jj concept]

**Your next step:** `<command>` — [what it does, what to expect]

**Then tell me:** [what output to check before the next step]
```

## Core Mental Model

You always have:

- `main` — the trunk bookmark, tracking `origin/main`.
- A feature bookmark (e.g. `login-feature`) — just a pointer to a commit, created only when you want a PR.
- A PR — just GitHub's UI over that bookmark, not the source of truth.

In `jj`, **merge = move `main` forward to include the commits you want**. Treat GitHub PRs as views of your commit graph, not the system of record.

## Daily Loop: Push Directly To main

The common case. Stay current, make a change on top of trunk, advance `main`, push.

```bash
jj git fetch
jj rebase -d origin/main          # stay current with trunk
jj new main                        # start a change on top of trunk
# ... edit files ...
jj describe -m "Add password reset" # set the commit message
jj bookmark set main -r @           # move trunk to your change (@ = current change)
jj git push --bookmark main         # push straight to main
```

That is the whole trunk-based loop: small change, advance `main`, push. Repeat.

> Note: older `jj` (and the source conversation) used `jj git push --branch <name>`; current `jj` uses `--bookmark`.

## Occasional Review PR

When a change is risky or needs review/CI, route it through a short-lived bookmark instead of pushing to `main`:

```bash
jj new main
jj bookmark create login-feature
jj git push --bookmark login-feature   # open the PR on GitHub
```

Then pick one of three ways to land it.

### Option A — GitHub merges (simplest, most common)

Best when you want GitHub checks/CI/approvals and the team relies on the PR UI.

1. Push the bookmark and open the PR (above).
2. On GitHub, click **Squash and merge** (recommended for trunk-based) or **Rebase and merge**.
3. Sync locally:

```bash
jj git fetch
jj rebase -d main
```

4. Clean up:

```bash
jj bookmark delete login-feature
```

### Option B — Merge locally (jj-native, clean history)

Best when you want full local control and deterministic history, and don't care about the GitHub merge button.

```bash
jj git fetch
jj edit main
jj rebase -d origin/main                          # ensure main is current
jj new main login-feature -m "merge login-feature into main"  # merge commit
jj bookmark set main -r @
jj git push --bookmark main
jj bookmark delete login-feature
```

### Option C — Hybrid (best balance for trunk-based teams)

GitHub handles review + CI; you do the final history shaping locally so `main` stays clean and fast-forwardable.

```bash
jj git push --bookmark login-feature   # 1. push branch, open PR
# 2. let CI run and approvals happen
# 3. when approved, merge locally:
jj git fetch
jj edit main
jj rebase -d origin/main
jj new main login-feature -m "merge login-feature"
jj bookmark set main -r @
jj git push --bookmark main
# 4. the PR auto-closes once main includes the commits
```

## Sync Loop (do this constantly)

Safe default — fetch and rebase your work onto the latest trunk:

```bash
jj git fetch
jj rebase -d origin/main
```

To update and stay on `main` specifically:

```bash
jj git fetch
jj edit main
jj rebase -d origin/main
```

Handy shell alias:

```bash
alias jjp='jj git fetch && jj rebase -d origin/main'
```

## Visualize The Graph

`jj log --graph` replaces most GUI tools.

```bash
jj log                                  # compact graph
jj log --graph -r 'all()'               # full graph with branches/merges/bookmarks
jj log -r 'bookmarks()'                 # focus on bookmarks
jj status                               # current commit + working-copy diff + conflicts
jj op log                               # every operation you did (recovery secret weapon)
```

Git graph tools still work because `jj` uses a git backend (VS Code Git Graph/GitLens, `lazygit`, `gitk --all`).

## Helper Script

Common flows are codified in `scripts/jj-trunk.sh`:

```bash
skills/jujutsu-trunk-based-development/scripts/jj-trunk.sh sync
skills/jujutsu-trunk-based-development/scripts/jj-trunk.sh push-main -m "Add password reset"
skills/jujutsu-trunk-based-development/scripts/jj-trunk.sh feature login-feature
skills/jujutsu-trunk-based-development/scripts/jj-trunk.sh graph
skills/jujutsu-trunk-based-development/scripts/jj-trunk.sh cleanup login-feature
```

- `sync` — `jj git fetch && jj rebase -d origin/main`.
- `push-main [-m "msg"]` — optionally describe, then `jj bookmark set main -r @` and push `main`.
- `feature <name>` — `jj new main`, create the bookmark, push it for a PR.
- `graph` — `jj log --graph -r 'all()'`.
- `cleanup <name>` — delete a merged feature bookmark.

`TRUNK` and `REMOTE` env vars override the defaults (`main`, `origin`).

## Recommended Workflow Summary

- **Daily work**: `jj new main`, edit, `jj describe`, `jj bookmark set main -r @`, `jj git push --bookmark main`.
- **Feature for review**: `jj new main` → `jj bookmark create <name>` → `jj git push --bookmark <name>` → merge via Option A/B/C.
- **Sync**: `jj git fetch && jj rebase -d origin/main`.
- **Cleanup**: `jj bookmark delete <name>`.

## Bash/Zsh Aliases

Optional shell shortcuts for this trunk-based loop. Add the ones you want to `~/.bashrc` or `~/.zshrc` (or a sourced `~/.jj_aliases`), then reload with `source ~/.bashrc` / `source ~/.zshrc`.

Guidelines:

- Plain `alias` works when you only append arguments at the end (e.g. `jjfeat login-feature`).
- Use a shell **function** when an argument goes in the middle, or when chaining multiple commands that take input (e.g. push-to-main with a message). Functions work in both bash and zsh.
- These mirror the `scripts/jj-trunk.sh` subcommands; pick whichever interface you prefer (aliases for muscle memory, the script for a stable contract).
- Conveniences only — the documented full commands remain the source of truth.

TODO — aliases to consider adding:

- [ ] `alias jjsync='jj git fetch && jj rebase -d origin/main'` — the constant sync loop.
- [ ] `alias jjg='jj log --graph -r "all()"'` — full commit graph with bookmarks/merges.
- [ ] `alias jjs='jj status'` — current change + working-copy diff + conflicts.
- [ ] `alias jjnew='jj new main'` — start a fresh change on top of trunk.
- [ ] `alias jjfeat='jj new main && jj bookmark create'` — start a review branch: `jjfeat login-feature` (then `jj git push --bookmark login-feature`).
- [ ] `alias jjclean='jj bookmark delete'` — remove a merged feature bookmark: `jjclean login-feature`.
- [ ] Push current change directly to `main` (function — sets message, advances trunk, pushes):

```bash
# usage: jjpushmain "commit message"   (message optional)
jjpushmain() {
  [ -n "$1" ] && jj describe -m "$1"
  jj bookmark set main -r @ && jj git push --bookmark main
}
```

## Hard Rules

- Default to pushing directly to `main`; only create a bookmark/PR when you actually want review or CI.
- Always sync (`jj git fetch && jj rebase -d origin/main`) before advancing `main`.
- Advance `main` only via `jj bookmark set main -r @` then `jj git push --bookmark main` — keep it fast-forwardable.
- Delete feature bookmarks after they land; do not accumulate stale bookmarks.
- This is a single-trunk workflow — do not introduce merge queues, multi-workspace orchestration, or formal finish-work gating here.

## Principles

- The PR is a view of the graph, not the source of truth.
- Keep `main` clean and fast-forwardable.
- Prefer the smallest ceremony that fits the change: direct push by default, PR only when review/CI is wanted.
- `jj log --graph` and `jj op log` are your primary inspection/recovery tools.
