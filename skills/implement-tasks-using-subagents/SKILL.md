---
name: implement-tasks-using-subagents
description: Implement a feature directory, list of issue files, or list of task files by scheduling independent work across subagents. Use when the user wants parallel implementation, wants multiple issues or tasks executed, or asks to use subagents to implement a feature. Determine dependency order, ask the user for branch or worktree strategy, run unblocked work in parallel, and wait for completion or user confirmation before dependent work.
---

# Implement Tasks Using Subagents

Implement multiple issues or tasks by building a dependency graph, running independent work in parallel with subagents, and sequencing dependent work safely.

Use this only when subagents are available. If subagents are not available, fall back to a serial execution plan and tell the user.

## Inputs

Accept one of:

- A feature issue directory such as `docs/issues/<feature-id>/`
- A list of issue files
- A list of task files

If no input is provided, ask the user for a feature directory, issue files, or task files before proceeding.

## Required User Gate

Before launching subagents, ask the user to choose the branch strategy if it is not already specified:

1. **Worktree per issue/task**: best for parallel work and dirty current workspaces
2. **Feature branch with serial integration**: best when changes overlap heavily
3. **Branch per issue/task from a shared parent**: useful for independent PRs without worktrees
4. **Stacked task branches**: useful when tasks must build on each other

Recommend worktree-per-issue/task for parallel independent work. Recommend a single feature branch only when the work is tightly coupled and should be integrated serially.

Do not launch subagents until the user approves the strategy.

## Process

### 1. Load Inputs

Read all provided issue or task files. If given a feature issue directory, read `index.md` first, then each issue file referenced from the index.

For each work item, extract:

- `issue_id` or task identifier
- File path
- Type: issue or task
- `blocked_by` or `Depends on`
- Parent feature or parent issue
- Acceptance criteria
- Verification instructions
- Likely files/modules from notes
- HITL or REVIEW gates

### 2. Build the Dependency Graph

Build a graph where each work item points to the items it depends on.

Classify work items as:

- **Blocked**: dependencies are incomplete
- **Unblocked**: dependencies are complete or absent
- **Parallel-safe**: unblocked and likely touches disjoint files/modules
- **Needs serialization**: unblocked but likely overlaps with another item or has an explicit human review gate

If dependencies are unclear, ask the user before executing.

### 3. Plan Execution Waves

Group work into waves:

- Wave 1: all unblocked parallel-safe items
- Later waves: items that become unblocked after prior waves complete
- Serialized items: run one at a time, even if technically unblocked

Before each wave, show:

- Items to execute
- Dependencies satisfied
- Branch/worktree strategy to use
- Any expected file ownership boundaries

For the first wave, get user approval before launching. For later waves, proceed automatically only if the user previously approved automatic continuation; otherwise ask for confirmation.

### 4. Launch Subagents

For each parallel-safe item, launch one subagent with a concrete, bounded assignment.

Use this instruction shape:

```text
Implement this work item: <path>
Branch/worktree strategy: <approved strategy>
Ownership: <files/modules this agent owns>
Do not revert or overwrite edits made by other agents. You are not alone in the codebase; adapt to already-completed changes.
Read the parent feature/issue context if referenced by the work item.
Implement only this item.
Run the verification listed in the file and focused tests for touched areas.
Final response must include: branch/worktree path, files changed, verification run, result, blockers, and any follow-up needed.
```

Keep write ownership disjoint when running subagents in parallel. If two items need the same files, serialize them.

### 5. Integrate Results

As subagents finish:

- Review their final status and changed files.
- Check verification results.
- Identify conflicts or overlapping edits.
- Mark completed items in the dependency graph.
- Do not start dependent work until dependencies are complete and verified, or until the user explicitly accepts proceeding with risk.

If a subagent fails or reports a blocker, stop dependent work and ask the user whether to fix, retry, skip, or replan.

### 6. Continue Through Dependency Waves

After a wave completes, recompute unblocked work.

If new items are unblocked:

- Launch parallel-safe items according to the approved strategy.
- Serialize overlapping or risky items.
- Ask for confirmation before proceeding when the next wave depends on a human review, failed verification, or ambiguous integration state.

### 7. Final Verification

After all selected work items complete, run an integration-level verification from the appropriate branch or worktree.

If using multiple worktrees or branches, verify each item independently and then verify the integrated branch if one exists.

### 8. Report

Report:

- Work items completed
- Work items skipped or blocked
- Branches and worktrees created
- Verification results
- Merge/PR recommendation
- Remaining human review gates

## Scheduling Rules

- Parallelize only independent work with low file overlap.
- Serialize work with shared files, shared migrations, shared API contracts, or unclear dependencies.
- Do not run dependent items before blockers complete.
- Do not hide failed verification by continuing downstream.
- Prefer fewer, clean waves over maximum parallelism.

## Principles

- Subagents are for bounded, independently verifiable work.
- Branch/worktree strategy is a user-approved execution policy, not an agent guess.
- Dependency order matters more than speed.
- Each subagent must have clear ownership.
- Stop and replan on blockers rather than compounding bad state.
