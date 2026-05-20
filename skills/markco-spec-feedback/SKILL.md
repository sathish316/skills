---
name: markco-spec-feedback
description: Read Markco markdown comments from feature and issue planning files, confirm the exact file scope with the user, incorporate unresolved feedback into the markdown, and mark addressed Markco comments as resolved. Use when the user asks to handle Markco comments, annotated feedback, markdown feedback, or reviewer comments on feature/issue specs.
---

# Markco Spec Feedback

Use this skill to apply reviewer feedback stored by Markco in markdown files, especially `.plan/features/*.md` and `.plan/issues/**/*.md`.
Plans can also be in `docs/features/*.md` and `docs/issues/**/*.md`.

## Markco Format

Markco stores comments directly in the markdown file as a trailing HTML comment:

```markdown
<!-- markco-comments
{
  "version": 2,
  "comments": [
    {
      "id": "...",
      "anchor": {
        "text": "anchored markdown text",
        "startLine": 10,
        "startChar": 0,
        "endLine": 10,
        "endChar": 24
      },
      "content": "review feedback",
      "author": "reviewer",
      "createdAt": "2026-01-15T11:47:50.061Z",
      "resolved": false,
      "replies": []
    }
  ]
}
-->
```

Newer Markco versions may include additional fields such as reactions. Preserve unknown fields exactly.

## Required Confirmation

Before editing any feature or issue file, ask the user to confirm the target scope unless they already gave an exact path and explicit permission to apply feedback.

Acceptable scopes:

- One exact feature file, for example `.plan/features/2026-05-20-x.md`
- One exact issue file, for example `.plan/issues/2026-05-20-x/001-y.md`
- All issue files for one exact feature issue directory, for example `.plan/issues/2026-05-20-x/`
- A feature file plus all issues for that feature, only when the user explicitly confirms both

If the user says "all issues in this feature", resolve and show the exact directory and file list before editing.

## Workflow

1. Locate the confirmed markdown file or files.
2. Parse the final `<!-- markco-comments ... -->` block from each file.
3. Read only comments with `resolved: false`; include unresolved replies when interpreting the feedback.
4. For each unresolved comment, inspect:
   - `id`
   - `anchor.text`
   - anchor line and character fields
   - `content`
   - unresolved `replies`
5. Check whether the anchor still exists. If not, search nearby headings and similar text before deciding it is orphaned.
6. Summarize the actionable comments and the planned edits to the user when the changes are non-trivial.
7. Edit the markdown content to incorporate the feedback.
8. Mark a comment as resolved only when the file has been changed so the feedback is addressed, or when the current file already clearly satisfies the feedback.
9. Preserve the Markco block at the end of the file with valid JSON.

## Resolution Policy

Set `resolved: true` for a Markco comment when:

- The requested content, clarification, constraint, acceptance criterion, or issue split is incorporated.
- The feedback is already satisfied by the current file and no markdown change is needed; mention this in the final response.
- The comment is obsolete because the anchored section was intentionally removed or replaced by equivalent content.

Leave `resolved: false` when:

- The feedback is ambiguous and needs user clarification.
- The feedback conflicts with another unresolved comment or existing approved scope.
- The requested change is out of scope for the confirmed target.
- You cannot find enough context to safely apply it.

Do not delete comments by default. Do not edit comment text, authors, timestamps, replies, reactions, anchors, or unknown fields unless required to keep valid JSON. Only change `resolved` for addressed comments.

## Editing Rules

- Keep normal markdown content separate from the Markco JSON block.
- Preserve feature and issue metadata, IDs, and parent links unless feedback explicitly targets them.
- For `.plan` feature and issue files, keep issue/feature relationships consistent after edits.
- When comments ask for new requirements or acceptance criteria, add them to the most specific relevant section instead of appending loose notes.
- When comments ask to split or merge issues, update the index and affected issue metadata consistently.
- If applying feedback to all issues for a feature, do not modify the parent feature file unless the user included it in the confirmed scope.

## Practical Parsing Notes

Use a parser-aware approach when possible:

- Extract the last block matching `<!-- markco-comments` through the following `-->`.
- Parse only the JSON body between those markers.
- If JSON parsing fails, stop and report the malformed block instead of guessing.
- After edits, serialize with two-space indentation so Markco can still read the block.

If line numbers are stale, trust `anchor.text` and surrounding markdown structure more than numeric positions.

## Final Response

Report:

- Files changed
- Number of unresolved comments found
- Number of comments marked resolved
- Any comments left unresolved and why

Do not start implementation work from a feature or issue unless the user explicitly asks for it after the feedback pass.
