---
name: pr-dashboard
description: List and inspect open GitHub and Bitbucket pull requests across configured repositories. Use this skill when the user asks for a PR dashboard, open PR summary, recent pull requests by repo, reviewer/status overview, or asks to drill into additional pages of PRs for a configured GitHub or Bitbucket project.
compatibility: Requires access to GitHub or Bitbucket through authenticated MCP tools, provider CLIs such as gh or bb, or available local wrapper scripts from installed skills.
labels:
  - github
  - bitbucket
  - pull-request
  - dashboard
metadata:
  version: 0.1.0
---

# PR Dashboard

## Purpose

Use this skill to produce a repository-wise dashboard of open pull requests from GitHub and Bitbucket repositories configured in `resources/projects.toml`.

If `resources/projects.toml` is missing, ask the user to create it from `resources/projects.toml.sample` and fill in the repositories they want tracked. Do not edit the user's local `projects.toml` unless they explicitly ask.

## Project Configuration

Read `resources/projects.toml` before fetching PRs. The file should contain one or more repository entries:

```toml
[[projects]]
name = "spring-framework"
provider = "gh"
url = "https://github.com/spring-projects/spring-framework"
owner = "spring-projects"
repo = "spring-framework"

[[projects]]
name = "elasticsearch"
provider = "gh"
url = "https://github.com/elastic/elasticsearch"
owner = "elastic"
repo = "elasticsearch"
```

For GitHub projects, use:

- `provider = "gh"`
- `url`: Full GitHub repository URL.
- `owner`: GitHub owner or organization.
- `repo`: GitHub repository name.

For Bitbucket projects, use:

- `provider = "bb"`
- `url`: Full Bitbucket repository URL.
- `workspace`: Bitbucket workspace.
- `repo`: Bitbucket repository slug.

Use `url` as the canonical repository link and display source. Use `owner`/`workspace` and `repo` as API parameters. If `owner` or `workspace` is omitted but `url` is present, parse it from the URL when the provider URL format is clear. Use `name` only as the display label when present. If `provider` is omitted, default to `gh` for backward compatibility.

## Capabilities

This skill supports:

- Listing open PRs in each configured repository.
- Listing only the 10 most recent open PRs per repository by default.
- Drilling into a specific repository and fetching more than 10 PRs only when the user asks for that repository.
- Offering paginated follow-up when the user wants to go beyond the first 10 PRs.

## Tool Selection

Prefer structured MCP tools when available. Otherwise use the provider CLI or installed local wrappers.

### GitHub

For GitHub, prefer GitHub MCP tools when available. Otherwise use authenticated `gh`.

Useful `gh` commands:

```bash
gh pr list --repo OWNER/REPO --state open --limit 10 --json number,title,author,reviewRequests,reviews,statusCheckRollup,url,updatedAt,createdAt,isDraft
gh pr list --repo OWNER/REPO --state open --limit 30 --json number,title,author,reviewRequests,reviews,statusCheckRollup,url,updatedAt,createdAt,isDraft
```

### Bitbucket

For Bitbucket, prefer Bitbucket MCP tools or the installed `twg`/`bb` workflow from the Bitbucket skills when available. Use repo and workspace values from `projects.toml`; do not guess slugs.

Useful Bitbucket commands from installed skills:

```bash
scripts/twg bb prs query --workspace WORKSPACE --repo REPO --state OPEN
bb prs query --workspace WORKSPACE --repo REPO --state OPEN
bb search prs "state = OPEN" --workspace WORKSPACE --repo REPO
```

If a command supports limit or pagination flags, request 10 records for the default dashboard. If it does not, fetch the smallest practical open-PR result set and show only the requested page.

When a user asks for page 2 or additional results, fetch enough records to cover the requested page and show only that page. Use a page size of 10 unless the user requests another size.

## Workflow

1. Read `resources/projects.toml`.
2. Resolve each configured repository and provider.
3. For a dashboard request, fetch the 10 most recently updated open PRs for each repo.
4. For a drill-down request, identify the target repo from the user's wording and fetch the requested page.
5. Normalize PR metadata into the required output fields.
6. If more results may exist beyond the current page, end that repo section with a short pagination hint.

## Status Mapping

Set `current status` to the most useful concise state available:

- `draft` when the PR is a draft.
- `checks failing` when required or reported checks have failures.
- `checks pending` when checks are pending or queued.
- `changes requested` when a latest review requests changes.
- `approved` when at least one latest review approval exists and no latest review requests changes.
- `open` when no richer status is available.

If the provider returns separate mergeability, review-decision, build, pipeline, or task fields, prefer those over inference from raw review history.

## Output Format

Group results by repository. Each PR row must include:

- `id`: provider PR number or ID, formatted as `#123` when numeric.
- `title`: PR title.
- `author`: provider username or display name when available.
- `reviewers`: requested reviewers and recent reviewers, or `none`.
- `current status`: concise status from the status mapping.
- `link`: full provider PR URL.

Use this shape:

```markdown
## gh: owner/repo

| id | title | author | reviewers | current status | link |
| --- | --- | --- | --- | --- | --- |
| #123 | Example PR title | octocat | hubot, monalisa | checks pending | https://github.com/owner/repo/pull/123 |
```

For Bitbucket sections, use `bb: workspace/repo` and include the full Bitbucket pull request URL in `link`.

Keep titles readable in tables. Do not omit the full URL even if the terminal or renderer auto-links it.

## Pagination Behavior

Default dashboard:

- Show at most 10 open PRs per repository.
- Do not fetch additional pages unless asked.

Repository drill-down:

- If the user asks for more PRs in a specific repo, show the next page of 10 for that repo only.
- Label pages clearly, such as `gh: owner/repo - page 2` or `bb: workspace/repo - page 2`.
- Preserve the same columns as the dashboard.
- Mention how to request the next page when additional open PRs may exist.

If provider access fails, report which repository failed and the command or tool surface used. Continue with other configured repositories when possible.
