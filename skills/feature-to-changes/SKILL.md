---
name: feature-to-changes
description: Break a feature definition markdown file into independently-grabbable OpenSpec changes organized by feature capability, then scaffold each one via OpenSpec Propose. Use when the user wants to convert a feature file into OpenSpec changes, create spec-driven change proposals from a feature definition, or split a medium/small feature into sequenced OpenSpec work items. Assume the feature file is passed as input; if it is not provided, ask the user for the feature file before proceeding.
---

# Feature to Changes

Break a feature definition into independently-grabbable units of work, but instead of producing plain issue files, produce **OpenSpec changes**. Each unit is called a **change**. Every change is scaffolded with full OpenSpec artifacts (proposal, design, tasks) via OpenSpec Propose (`/opsx:propose`, or the `openspec-propose` skill).

This skill is the OpenSpec-native counterpart of `feature-to-issues`. Use it when the project is driven by OpenSpec (`openspec/` exists with `config.yaml`) and you want each capability to flow through the spec-driven `propose → apply → archive` lifecycle. Everything `feature-to-issues` calls an "issue", this skill calls a "change".

## Sequencing scheme

Each change name encodes its place in the execution order using a **wave number + lane letter** prefix, kept inside a feature-slug-first name:

```
<feature-slug>-<NN><lane>-<change-slug>
```

- **`NN`** is the **wave** — the dependency level / execution order. Lower waves run before higher waves. Zero-padded to two digits.
- **`lane`** is a lowercase letter (`a`, `b`, `c`, …) — a slot **within** a wave. Changes that share the same wave number are independent of each other and **safe to run in parallel**; the letter just distinguishes siblings.
- A wave with only one change still gets lane `a`.

Example for a feature with slug `search-filters`:

```
openspec/changes/
  search-filters-01a-add-db-schema/    ┐ wave 1 — no dependencies
  search-filters-01b-add-config/       ┘ parallel with 01a
  search-filters-02a-add-query-api/    ── wave 2 — needs wave 1
  search-filters-03a-add-filter-ui/    ┐ wave 3
  search-filters-03b-add-audit-log/    ┘ parallel with 03a
```

Why this scheme:

- **Sorts by execution order.** `01a < 01b < 02a < 03a` lexically, so OpenSpec's alphabetical change listing already reflects the order to run them in.
- **Parallelism is visible in the name.** All `01*` changes can be picked up at once; an executor like `implement-tasks-using-subagents` can see the parallel-safe set without opening the index.
- **No special characters.** Letters and digits only, so `openspec new change "<name>"` accepts the directory name.
- **Insert-friendly.** A late parallel change takes the next free lane (`01c`); a change that splits a wave takes the next number.

The change name is the quick signal. The **index file holds the authoritative `Blocked by` dependency graph** — keep them consistent.

## Process

### 1. Locate the feature file and verify OpenSpec

Assume the feature file is passed as input. If the user did not provide a feature file path, file mention, or pasted feature definition, ask for it before proceeding. Do not invent requirements from memory — the feature file is the source of truth.

Verify OpenSpec is set up: confirm `openspec/config.yaml` exists and the `openspec` CLI is available. If OpenSpec is not initialized, tell the user and stop — this skill requires OpenSpec. (If they want plain issue files instead, point them to `feature-to-issues`.)

Determine where the per-feature **change index** should live. If the user does not specify, default to:

`docs/changes/<feature-file-stem>/index.md`

The OpenSpec changes themselves are created by the CLI under the planning home it resolves (typically `openspec/changes/`); do not assume that path — read it from `openspec status --json`.

### 2. Read and validate the feature

Read the feature file and identify:

- Summary and problem
- Goals and non-goals
- Users and use cases
- Proposed behavior
- Scope boundaries
- Requirements
- Risks and dependencies
- Edge cases and failure behavior
- Acceptance criteria
- Implementation notes
- Open questions

If unresolved open questions block the breakdown, ask the user to resolve them before drafting changes. Non-blocking questions get carried into the relevant HITL change or noted as risks.

### 3. Explore the codebase

Explore enough to make each change concrete and executable. Focus on:

- Files, modules, routes, commands, UI areas, or services likely affected
- Existing patterns to follow
- Test conventions and relevant existing tests
- Integration points implied by the feature file
- Migration, configuration, or compatibility concerns

Keep exploration bounded — the goal is change planning, not implementation.

### 4. Draft capability changes

Break the feature into capability-focused changes. Each change should represent one independently understandable and independently verifiable part of the feature, sized to flow cleanly through one OpenSpec `propose → apply → archive` cycle.

When splitting changes, prefer tracer-bullet slices where they make sense, but use your judgment — a feature's natural breakdown might instead follow capability, state, workflow, integration, or prerequisite, as appropriate.

A good change may be:

- A user-visible capability
- A backend capability needed by one or more user-facing behaviors
- A UI state or workflow that can be reviewed independently
- A data model, migration, or integration prerequisite risky enough to isolate
- A test or compatibility change that protects existing behavior

Changes may be **HITL** or **AFK**:

- **HITL** (Human In The Loop): requires a human decision or review during implementation (confirming UX, approving a migration, choosing an integration contract, resolving an open question).
- **AFK** (Away From Keyboard): can be implemented and verified without human interaction once assigned.

Prefer AFK wherever the feature definition already makes the decision clear.

<change-splitting-rules>
- Each change maps to a distinct feature capability, requirement, acceptance criterion, risk, or dependency
- Each change is independently understandable and independently verifiable
- Each change is sized to fit one OpenSpec propose/apply/archive cycle
- Prefer several focused changes over one broad change
- Split changes that contain unrelated decisions or unrelated implementation paths
- Merge changes that are only meaningful when implemented together
- Do not require every change to span schema, logic, API, UI, and tests
</change-splitting-rules>

### 5. Assign waves and lanes

Turn the dependencies between changes into the wave/lane prefix:

1. Build the dependency graph: for each change, list which other changes must complete first (its blockers).
2. Assign **waves** by topological level: a change with no blockers is wave `01`; a change's wave is one greater than the highest wave among its blockers.
3. Within each wave, assign **lanes** `a`, `b`, `c`, … to the changes that share it (order them by the feature file's natural reading order or by name).
4. Derive the full change name: `<feature-slug>-<NN><lane>-<change-slug>`.

Derive `<feature-slug>` from the feature file stem (drop a leading date like `2026-05-06-` if present) unless the feature file defines a stable `id` in frontmatter.

Sanity-check: every blocker of a change must be in a strictly lower wave. If two changes block each other, the split is wrong — merge or re-cut them.

### 6. Quiz the user

Present the proposed breakdown as a table grouped by wave. For each change show:

- **Name**: the full `<feature-slug>-<NN><lane>-<change-slug>` change name
- **Type**: HITL / AFK
- **Wave / lane**: and what running in that wave implies
- **Blocked by**: which other changes must complete first (by change name), or `None`
- **Feature coverage**: which goals, requirements, or acceptance criteria this addresses
- **Verification**: the manual or automated signal that proves it is done

Ask the user:

- Does the granularity feel right? (too coarse / too fine)
- Are the dependency relationships — and therefore the waves — correct?
- Should any changes be merged or split further?
- Are all HITL changes correctly identified?
- Are the parallel-safe sets (same-wave changes) actually independent?

Flag any change that covers too many requirements, depends on several unrelated decisions, or would not fit one OpenSpec cycle — it is probably too coarse and should be split.

Iterate until the user approves the breakdown. **Do not scaffold any OpenSpec change before approval** — change creation is outward-facing and creates real directories.

### 7. Scaffold each change with OpenSpec Propose

Once approved, create each change through OpenSpec Propose, in wave order (wave `01` first). For each change, run the `openspec-propose` flow (equivalent to `/opsx:propose`) using the full change name:

1. Create the change:
   ```bash
   openspec new change "<feature-slug>-<NN><lane>-<change-slug>"
   ```
2. Read the artifact build order and resolved paths:
   ```bash
   openspec status --change "<name>" --json
   ```
3. Create artifacts in dependency order until apply-ready, following `openspec instructions <artifact-id> --change "<name>" --json` for each. Seed every artifact from the feature file: the proposal's "why" comes from the feature's problem/goals, the design from its proposed behavior and implementation notes, and the tasks from its requirements and acceptance criteria — scoped to **this** change only, never the whole feature.
4. In each change's `proposal.md`, record the cross-change relationship so the OpenSpec change is self-describing:
   - **Parent feature**: relative path to the feature file
   - **Wave / lane**: e.g. `wave 02, lane a`
   - **Blocked by**: blocker change names, or `None`
5. Verify each artifact file exists before moving on.

Follow the `openspec-propose` guardrails: create all artifacts required for implementation, read dependency artifacts first, and if a change with that name already exists, ask whether to continue it or pick a new lane/number.

Within a single wave the changes are independent, so they may be scaffolded in any order (or in parallel if you are orchestrating subagents). Across waves, keep to ascending wave order so blockers are proposed before the changes that depend on them.

### 8. Write the change index

Write the index file to the chosen directory (default `docs/changes/<feature-file-stem>/index.md`). It is the authoritative map from the feature to its OpenSpec changes and the source of truth for the dependency graph.

Do not modify the feature file by default. Maintain the feature-to-changes association through the index file and the `Parent feature` line inside each change's `proposal.md`. If the user explicitly wants backlinks in the feature file, append a short "Changes" section there after writing the index.

## Association format

Change ids are the full change name: `<feature-slug>-<NN><lane>-<change-slug>`. The wave/lane prefix carries sequencing; the index carries the authoritative `Blocked by` graph.

The index frontmatter stays minimal (`artifact`, `id`, `title`, `status`, `created`) — matching the shared planning-artifact contract. Relationships live in the document body.

<change-index-template>
---
artifact: change-index
id: <feature-file-stem>-changes
title: OpenSpec changes for <feature title>
status: not-started        # not-started | in-progress | done
created: <YYYY-MM-DD>
---

# OpenSpec Changes for Feature: <feature title>

Parent feature: `<relative-path-to-feature-file>`
OpenSpec changes home: `<planningHome from openspec status, e.g. openspec/changes/>`

## Sequencing

Change names use `<feature-slug>-<NN><lane>-<change-slug>`: `NN` is the execution wave, the letter is a lane within the wave. Same wave = independent = safe to run in parallel. Run lower waves before higher waves.

## Change Index

| Change | Type | Status | Wave | Blocked By | Feature coverage |
| --- | --- | --- | --- | --- | --- |
| `<feature-slug>-01a-<change-slug>` | AFK | not-started | 1 | None | <goal / requirement> |
| `<feature-slug>-01b-<change-slug>` | AFK | not-started | 1 | None | <goal / requirement> |
| `<feature-slug>-02a-<change-slug>` | HITL | not-started | 2 | `<feature-slug>-01a-<change-slug>` | <goal / requirement> |

## Parallel-safe sets

- **Wave 1** (run together): `<feature-slug>-01a-<change-slug>`, `<feature-slug>-01b-<change-slug>`
- **Wave 2**: `<feature-slug>-02a-<change-slug>`
- **Wave 3** (run together): `<feature-slug>-03a-<change-slug>`, `<feature-slug>-03b-<change-slug>`

## Notes

<Cross-change context, risks, or `None`.>
</change-index-template>

If the user asks to add backlinks to the feature file, append:

```markdown
## Changes

Change index: `../changes/<feature-file-stem>/index.md`

- `<feature-slug>-01a-<change-slug>` (wave 1): <change title>
```

## Status frontmatter contract

The index shares the one minimal frontmatter used across all planning artifacts (features, issues, tasks, changes): exactly `artifact`, `id`, `title`, `status`, `created`. Rules:

- `status` uses exactly `not-started`, `in-progress`, or `done` — no other vocabulary.
- New indexes start at `status: not-started`.
- OpenSpec owns each change's own lifecycle status; the index's per-row Status column mirrors it for reporting. When a change starts or finishes, update its index row and keep the index frontmatter `status` in sync (`in-progress` once any change starts, `done` when all changes are archived).
- Update the parent feature file's frontmatter `status` to `in-progress` once any change starts (not when changes are merely proposed), and to `done` when all changes are done.
- Reporting skills read only the frontmatter to determine status; keep it accurate.

## Principles

- Treat the feature file as the source of truth; never expand scope or invent requirements while creating changes.
- Preserve the feature's non-goals.
- One change = one OpenSpec propose/apply/archive cycle = one independently verifiable capability.
- The wave/lane prefix is the quick sequencing signal; the index is the authoritative dependency graph — keep them consistent.
- Scaffold real OpenSpec changes only after the user approves the breakdown.
- Make parallel-safe sets explicit so changes can be picked up safely by different agents or developers.
- Seed each change's OpenSpec artifacts from the feature file, scoped strictly to that change.
