---
name: project-scrum
description: Summarize project status across plans, features, issues, tasks, and OpenSpec changes as a color-coded scrum report. Use when the user asks for a scrum update, standup summary, project status, progress report, or where the project stands.
---

# Project Scrum

Produce a color-coded status report for the current project by scanning its planning artifacts. Read-only: never modify plans, features, issues, tasks, or OpenSpec changes while reporting.

## Status model

Every artifact gets exactly one status with a fixed color code:

| Status | Color | Meaning |
| --- | --- | --- |
| not-started | 🟡 yellow | planned but no work has begun |
| in-progress | 🔵 blue | some work done, not complete |
| done | 🟢 green | complete and verified |

Map source vocabulary onto this model: `planned`/`todo`/`not-started` → 🟡, `in-progress`/`doing`/`started` → 🔵, `done`/`completed`/`shipped`/✅ → 🟢.

## Artifact discovery

Scan these locations (skip any that don't exist, and say so briefly):

1. **Plans**: `docs/plans/PLAN-*.md` (note `docs/plans/BACKLOG.md` separately as a backlog, not a status item)
2. **Features**: `docs/features/YYYY-MM-DD-*.md`
3. **Issues**: `docs/issues/<feature-file-stem>/` — the index file (frontmatter `status:`, Issue Index table) and each `NNN-<slug>.md` (frontmatter `issue_id`, `status`, `blocked_by`)
4. **Tasks**: task files produced by issue-to-tasks (commonly `docs/tasks/`, or paths referenced from issues); tasks are numbered sections with Type/Output/Depends-on
5. **OpenSpec changes**: prefer the `openspec` CLI when available — `openspec changes` to list active changes and `openspec status --change "<name>" --json` for artifact completion (`artifacts[].status == "done"`). Fall back to scanning the changes directory: `openspec/changes/<change-id>/` holds active changes (each with a `tasks.md` using `- [ ]`/`- [x]` checkboxes), and `openspec/changes/archive/<YYYY-MM-DD-change-id>/` holds archived ones. Match changes to issues by change-id references in issue files or by slug similarity

If the project uses different paths, prefer what the user points at; ask only when nothing is discoverable.

## Frontmatter-first reading

Planning artifacts produced by `brainstorm-feature`, `feature-to-issues`, and `issue-to-tasks` carry one minimal shared frontmatter: `artifact` (feature | issue-index | issue | tasks), `id`, `title`, `status` (not-started | in-progress | done), `created`. Relationships (parent feature/issue, blockers) and task checkboxes live in the body.

Read ONLY the frontmatter block (the lines between the opening and closing `---`) of each artifact — e.g. `head -10` or an awk/sed extraction — and build the report from those fields. Read the whole file only when:

- the frontmatter is missing, empty, or lacks a `status` field — derive status from the body (Status fields, checkboxes) and flag the file in Drift as needing frontmatter; or
- you need detail the frontmatter doesn't carry, and only for the artifacts that need it (e.g. task checkbox counts for a 🔵 in-progress task file, or `blocked_by` from the body of a 🟡 issue).

## Status derivation rules

Apply these in order; later rules refine earlier ones.

### 1. Explicit status first

An artifact's frontmatter `status:` is the baseline (fall back to a `**Status**:` body field only for files without frontmatter).

### 2. Issues — combine task-level status

If an issue has a task file (match by issue id in task-file frontmatter `id`), the task file's frontmatter `status` is the rollup signal; read body checkboxes only to report counts for 🔵 in-progress files:

- task file 🟡 not-started → keep issue baseline (usually 🟡)
- task file 🔵 in-progress → issue is 🔵 (report checked/total from the body)
- task file 🟢 done → issue is 🟢

When the rollup disagrees with the issue's written status (e.g. all tasks done but frontmatter still says `planned`), report the derived status and flag the mismatch in a "Drift" note so the user can update the file.

### 3. Issues — combine OpenSpec change status

If an issue has associated OpenSpec changes, derive each change's status from the layout:

- Change folder under `openspec/changes/archive/` → 🟢 done
- Active change (under `openspec/changes/`, not archive) → 🔵 in-progress; refine with its `tasks.md` checkboxes and `openspec status --json` artifacts:
  - no `- [x]` and no done artifacts → 🟡 not-started (proposed but untouched)
  - some `- [x]` → 🔵 in-progress, report checked/total (e.g. `3/7 tasks`)
  - all `- [x]` but not yet archived → 🔵 with a "ready to archive" note in Drift

Roll up per issue: archived changes count toward done, any active change holds the issue at 🔵 in-progress. An issue with only archived changes (and no other open work) rolls up to 🟢.

### 4. Features — roll up from issues

- No issues generated yet → 🟡 (unless the feature file itself says otherwise)
- Any issue 🔵 or a mix of 🟢/🟡 → 🔵
- All issues 🟢 → 🟢

### 5. Plans — roll up from features

- No features derived yet → 🟡
- Any feature 🔵 or a mix → 🔵
- All features 🟢 → 🟢

## Report format

Output a single scrum report, most-important-first:

```markdown
# Project Scrum — <project name> (<date>)

## TL;DR
<2-3 sentences: what shipped, what's in flight, what's next, anything blocked>

## Plans
| Plan | Status |
| --- | --- |
| PLAN-first-willows | 🔵 in-progress |

## Features
| Feature | Status | Issues done |
| --- | --- | --- |
| core-foundation | 🔵 in-progress | 2/4 |

## Issues
| Issue | Feature | Status | Tasks | OpenSpec |
| --- | --- | --- | --- | --- |
| core-foundation-001 | core-foundation | 🟢 done | 5/5 | 1 archived |
| core-foundation-002 | core-foundation | 🔵 in-progress | 2/6 | add-config 3/7 tasks |

## Drift
<status-field vs derived-status mismatches, or "None">

## Blocked / Needs decision
<issues with unmet blocked_by, REVIEW tasks awaiting humans, or "None">
```

Omit empty sections except TL;DR. Keep the tables tight; put explanations in prose after the tables, not in cells.

## Principles

- Derived status beats stale written status, but always surface the drift rather than silently disagreeing with the files.
- Counts in tables (`2/4`), reasons in prose.
- This skill reports; it never edits. If the user asks to sync statuses after seeing drift, that is a follow-up action they must confirm.
