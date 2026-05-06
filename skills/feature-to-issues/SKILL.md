---
name: feature-to-issues
description: Break a feature definition markdown file into independently-grabbable implementation issues organized by feature capability. Use when the user wants to convert a feature file into issues, create implementation tickets from a feature definition, or split a medium/small feature into work items. Assume the feature file is passed as input; if it is not provided, ask the user for the feature file before proceeding.
---

# Feature to Issues

Break a feature definition into independently-grabbable implementation issues organized around the feature's independent capabilities.

This skill is the next step after `brainstorm-feature` when the feature is clear enough to plan implementation work, but does not need a full PRD.

## Process

### 1. Locate the Feature File

Assume the feature file is passed as input. If the user did not provide a feature file path, file mention, or pasted feature definition, ask the user to provide the feature file before proceeding.

Also determine where the issue files should be saved. If the user does not specify an output path, use the default issue directory:

`docs/issues/<feature-file-stem>/`

For example, if the feature file is:

`docs/features/2026-05-06-search-filters.md`

Store the issues in:

`docs/issues/2026-05-06-search-filters/`

Use one file per issue plus an index file:

- `docs/issues/<feature-file-stem>/index.md`
- `docs/issues/<feature-file-stem>/001-<issue-slug>.md`
- `docs/issues/<feature-file-stem>/002-<issue-slug>.md`

Do not invent requirements from memory or prior conversation if the feature file is missing. The feature file is the source of truth.

### 2. Read and Validate the Feature

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

If the feature file has unresolved open questions that block issue breakdown, ask the user to resolve them before drafting issues. If open questions are non-blocking, carry them into the relevant HITL issue or note them as risks.

### 3. Explore the Codebase

Explore the codebase enough to make capability issues concrete and executable. Focus on:

- Files, modules, routes, commands, UI areas, or services likely affected
- Existing patterns to follow
- Test conventions and relevant existing tests
- Integration points implied by the feature file
- Migration, configuration, or compatibility concerns

Keep exploration bounded. The goal is issue planning, not implementation.

### 4. Draft Capability Issues

Break the feature into capability-focused issues. Each issue should represent one independently understandable and independently verifiable part of the feature.

Do not force tracer-bullet vertical slices for feature files. PRDs often benefit from tracer bullets because they describe broad product areas; a feature definition is usually narrower, and its natural breakdown may be by capability, state, workflow, integration, or prerequisite.

A good feature issue may be:

- A user-visible capability
- A backend capability needed by one or more user-facing behaviors
- A UI state or workflow that can be reviewed independently
- A data model, migration, or integration prerequisite that is risky enough to isolate
- A test or compatibility issue that protects existing behavior

Avoid splitting purely by layer when that creates issues that cannot be understood or verified on their own. Also avoid bundling unrelated capabilities just to make an issue feel end-to-end.

Issues may be **HITL** or **AFK**:

- **HITL** (Human In The Loop): requires a human decision or review during implementation, such as confirming UX behavior, approving a migration, choosing an external integration contract, or resolving an open question
- **AFK** (Away From Keyboard): can be implemented and verified without human interaction once assigned

Prefer AFK wherever the feature definition already makes the decision clear.

<issue-splitting-rules>
- Each issue maps to a distinct feature capability, requirement, acceptance criterion, risk, or dependency
- Each issue is independently understandable and independently verifiable
- Prefer several focused issues over one broad issue
- Split issues that contain unrelated decisions or unrelated implementation paths
- Merge issues that are only meaningful when implemented together
- Do not require every issue to span schema, logic, API, UI, and tests
</issue-splitting-rules>

### 5. Quiz the User

Present the proposed breakdown as a numbered list. For each issue show:

- **Title**: short descriptive name
- **Type**: HITL / AFK
- **Blocked by**: which other issues, if any, must complete first
- **Feature coverage**: which goals, requirements, or acceptance criteria from the feature file this addresses
- **Verification**: the manual or automated signal that proves the issue is complete

Ask the user:

- Does the granularity feel right? (too coarse / too fine)
- Are the dependency relationships correct?
- Should any issues be merged or split further?
- Are all HITL issues correctly identified?

Flag any issue that covers too many requirements, depends on several unrelated decisions, or would likely take more than half a day. It is probably too coarse and should be split.

Iterate until the user approves the breakdown.

### 6. Write the Issue Files

Write all approved issues to the selected output directory. Number issues sequentially and use those numbers for cross-references.

Use the index template once, then the issue template for each issue. Write issues in dependency order, with blockers first.

Do not modify the feature file by default. Maintain the feature-to-issues association through the issue directory name, the `index.md` file, and `parent_feature` metadata in every issue file. If the user explicitly wants backlinks in the feature file, add a short "Issues" section there after writing the issue files.

## Association Format

Derive `feature_id` from the feature file stem unless the feature file already defines a stable ID in frontmatter. Use the same `feature_id` in the issue index and every issue file.

Each issue file should include:

- `parent_feature`: relative path to the feature file
- `feature_id`: stable feature identifier
- `issue_id`: `<feature_id>-<NNN>`
- `blocked_by`: issue IDs, not filenames; use an empty list when there are no blockers

This keeps each issue portable while preserving the relationship back to the feature.

If the user asks to add backlinks to the feature file, append this section to the feature file:

```markdown
## Issues

Issue directory: `../issues/<feature-file-stem>/`

- [<feature-id>-001](../issues/<feature-file-stem>/001-<issue-slug>.md): <issue title>
```

<issue-index-template>
---
feature_id: <feature-file-stem>
parent_feature: <relative-path-to-feature-file>
issue_count: <number>
status: planned
---

# Issues for Feature: <feature title>

Parent feature: `<relative-path-to-feature-file>`

## Issue Index

| Issue | Type | Status | Blocked By | Title |
| --- | --- | --- | --- | --- |
| [<feature-id>-001](001-<issue-slug>.md) | HITL / AFK | planned | None | <issue title> |

## Notes

<Cross-issue context, sequencing notes, or `None`.>
</issue-index-template>

<issue-template>
---
feature_id: <feature-file-stem>
parent_feature: <relative-path-to-feature-file>
issue_id: <feature-id>-<NNN>
type: HITL / AFK
status: planned
blocked_by: []
---

# Issue <NNN>: <title>

**Type**: HITL / AFK  
**Status**: planned  
**Parent feature**: `<relative-path-to-feature-file>`  
**Blocked by**: <issue-id> / None - can start immediately

### What to build

A concise description of this capability issue. Describe the behavior, prerequisite, workflow, or risk being addressed. Reference relevant sections of the feature file rather than duplicating the whole feature definition.

### Feature coverage

- Goal: <goal or "N/A">
- Requirement: <requirement or "N/A">
- Acceptance criteria: <acceptance criterion or "N/A">

### How to verify

Exactly how a developer or AI agent confirms the issue is complete:

- **Manual**: <step-by-step demo or inspection path>
- **Automated**: <test behavior or assertion>

### Acceptance criteria

- [ ] Given <context>, when <action>, then <outcome>
- [ ] Given <failure condition>, then <expected behavior>

### Notes

Implementation notes, likely files, existing patterns to follow, risks, or human decisions needed for this issue.

---
</issue-template>

If there are no notes for an issue, write `None`.

## Principles

- Treat the feature file as the source of truth.
- Preserve the feature's non-goals; do not expand scope while creating issues.
- Prefer independently verifiable capability issues over forced tracer bullets.
- Keep issue descriptions implementation-guiding but not code-prescriptive.
- Make dependencies explicit so issues can be picked up safely by different agents or developers.
