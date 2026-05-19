---
name: codewiki-viewer
description: >
  Build or serve a local HTML viewer for markdown documentation in a repository's `codewiki/`
  folder. Use when the user asks to launch, open, view, serve, render, or generate an HTML
  site for CodeWiki docs. If `codewiki/` markdown files are missing, ask the user whether
  they want to generate the wiki first before attempting to start the viewer.
metadata:
  short-description: Serve CodeWiki markdown as a local HTML site
---

# CodeWiki Viewer

Use this skill to turn an existing `codewiki/` markdown folder into a local Eleventy HTML site.
The bundled script lives next to this skill at `generate.py`.

## Prerequisites

- Python 3
- Node.js 18+
- npm access for installing the viewer's Eleventy dependencies the first time

## Workflow

1. Resolve the target repository root. Default to the current working directory unless the user provides another path.
2. Check for markdown files in `<repo>/codewiki/`, including top-level `*.md` files and `codewiki/6-deep-dive/*.md`.
3. If no wiki markdown files are present, stop and ask the user whether they want to generate the wiki first.
   - If they say yes, use the `codewiki` skill to generate markdown documentation in `<repo>/codewiki/`, then rerun this viewer workflow.
   - If they say no, do not start the viewer.
4. Start the viewer from the target repository:

```bash
python3 <path-to-this-skill>/generate.py --codewiki-dir codewiki --output-dir codewiki/_site --serve
```

5. Tell the user the local URL. The default is:

```text
http://localhost:<repo-specific-port>
```

By default, `generate.py` chooses a stable port from the repository path so
different repositories do not always compete for the same port. If that
repo-specific port is already in use, it scans forward to the next available
viewer port. To force a specific port, pass `--port <port>`.

## Static Build

If the user wants a static HTML build without a live server, run:

```bash
python3 <path-to-this-skill>/generate.py --codewiki-dir codewiki --output-dir codewiki/_site
```

Then report the generated file:

```text
codewiki/_site/index.html
```

## Notes

- The script installs npm dependencies in this skill's directory if `node_modules/` is missing.
- If dependency installation fails because network access is blocked, ask for permission to rerun with network access.
- Keep generated HTML inside `codewiki/_site/`; the markdown files in `codewiki/` remain the source of truth.
