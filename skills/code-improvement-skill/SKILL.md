---
name: code-improvement-skill
description: Detect code-improvement catalog violations in recent PR files and guide small stacked commits/branches.
---

# Code Improvement Skill

Use this skill when working through `GOAL.md` code-improvement branches.

## Workflow

1. Identify recent Github or Bitbucket merge commits from local first-parent history.
2. Collect the files changed by those commits.
3. Run `scripts/scan_code_improvements.py` against the changed files.
4. Prefer small refactors that reduce one catalog violation at a time.
5. Update `code_improvement/PROGRESS.md` in the same commit as each improvement.
6. Keep branches local until the user explicitly approves pushing or PR creation.

## Scanner

Run from the repository root:

```bash
python3 .agents/skills/code-improvement-skill/scripts/scan_code_improvements.py --recent-pr-count 10
```

Useful planning modes:

```bash
python3 .agents/skills/code-improvement-skill/scripts/scan_code_improvements.py --recent-pr-count 20 --summary --top 20
python3 .agents/skills/code-improvement-skill/scripts/scan_code_improvements.py --changed-from code-improvement-010 --summary
```

The scanner intentionally uses conservative heuristics and reports candidates
for human review. It does not replace compilation or tests.
