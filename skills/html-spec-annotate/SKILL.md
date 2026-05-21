---
name: html-spec-annotate
description: Use this skill when the user wants to annotate, review, or provide feedback on a generated HTML spec, diagram, prototype, or executive artifact. It adds a lightweight browser annotation plugin to the HTML, guides the reviewer to export feedback JSON, and applies unresolved feedback back to the source without rereading the entire HTML page.
---

# HTML Spec Annotate

Use this skill to support an annotation-and-fix loop for generated HTML artifacts such as strategy diagrams, spec mockups, architecture visuals, product flows, or executive overview pages.

The workflow has two parts:

1. Add the lightweight annotation plugin to an HTML file so the reviewer can click page elements and leave comments.
2. Read the exported sidecar feedback JSON and update the HTML/source artifact to address unresolved comments.

## Assets

This skill includes the annotation plugin at:

```text
assets/html-spec-annotate-plugin.js
```

Copy this file next to the target HTML artifact when enabling annotations.

## Add annotation support to an HTML artifact

1. Locate the target HTML file.
2. Copy this skill's bundled plugin asset into the same directory as the HTML file:

   ```text
   html-spec-annotate-plugin.js
   ```

3. Add this script tag immediately before `</body>`:

   ```html
   <script src="html-spec-annotate-plugin.js"></script>
   ```

4. Open the HTML in a browser.
5. Give the reviewer these instructions:

   > The HTML now has an annotation panel in the top-right. Click **Annotate**, click a diagram element, write feedback, and save. When finished, click **Export JSON** and send me the downloaded file or its path. I’ll apply the feedback and update the diagram.

The plugin stores draft comments in browser `localStorage`, so refreshing the same local file should preserve draft comments. Agents should not rely on browser storage; use the exported JSON.

## Sidecar feedback JSON

Use a small sidecar feedback JSON file as the agent-readable source of truth. Save exported feedback next to the HTML using this convention:

```text
<artifact-name>.feedback.json
```

Example:

```text
melt-investigation-strategy-framework.html
melt-investigation-strategy-framework.feedback.json
```

If the browser exports a hyphenated filename such as `<artifact-name>-feedback.json`, either use that explicit path or rename it to the sidecar convention.

This keeps review state separate from the HTML and lets agents inspect comments without loading the full page.

## Feedback JSON format

The plugin exports JSON like:

```json
{
  "version": 1,
  "source": {
    "title": "MELT Investigation Strategy Framework",
    "path": "/path/to/file.html",
    "exportedAt": "2026-05-21T12:00:00.000Z"
  },
  "comments": [
    {
      "id": "fb-...",
      "anchor": {
        "anchorId": "strategy-ts-is-123",
        "selector": "[data-feedback-anchor-id=...]",
        "text": "TS + IS",
        "tagName": "div",
        "className": "strategy",
        "boundingClientRect": { "x": 10, "y": 20, "width": 100, "height": 40 }
      },
      "content": "Clarify what IS means here",
      "author": "reviewer",
      "createdAt": "2026-05-21T12:01:00.000Z",
      "resolved": false,
      "replies": []
    }
  ]
}
```

Preserve unknown fields if rewriting feedback JSON. The normal path is to update the HTML/source artifact, not to edit the JSON unless marking comments resolved after applying them.

## Apply feedback efficiently

1. Confirm the target HTML/source file if the user has not given an exact path.
2. Locate the sidecar feedback JSON. Prefer `<artifact-name>.feedback.json`; otherwise use the explicit JSON path the user provided.
3. Read the feedback JSON first, not the whole HTML page.
4. Filter comments by status depending on the task:
   - Normal fix pass: read only comments where `resolved` is not `true`.
   - Audit/history pass: include resolved comments too.
5. For each relevant comment, inspect only:
   - `id`
   - `resolved`
   - `anchor.text`
   - `anchor.anchorId` / `anchor.selector`
   - `content`
   - unresolved replies, if present
6. Locate the relevant content surgically:
   - Prefer searching the HTML for `data-feedback-anchor-id="<anchorId>"`.
   - If that fails, search for the exact `anchor.text` or a distinctive substring.
   - Read only a small surrounding range around the match before editing.
   - Use the source diagram file, such as `.mmd`, when it is the cleaner source of truth.
7. Apply concise edits that address the comment without over-expanding the artifact.
8. If a comment is ambiguous, leave it unresolved and ask a targeted clarification.

## Resolution policy

Treat a comment as addressed when the HTML/source artifact has been changed so the feedback is clearly incorporated, or when the current artifact already satisfies the request.

If maintaining the feedback JSON as part of an iteration, set addressed comments to `resolved: true`. Do not delete comments by default.

Leave a comment unresolved when:

- The request is ambiguous.
- The feedback conflicts with another comment.
- The requested change is outside the intended scope of the artifact.
- The anchor can no longer be located and no safe equivalent exists.

## Output after applying feedback

Report:

- Files changed
- Number of feedback comments read
- Number addressed
- Comments left unresolved and why
- How to reopen the updated HTML for another review pass
