---
name: pr-reviewer
description: Review pull requests using the tools available in the current environment. Works with GitHub or Bitbucket, MCP tools or CLI tools, and local git diffs. Produces actionable review findings, optional human-inspection callouts, and optional PR comments.
compatibility: Requires git access plus at least one way to inspect a pull request, such as GitHub tools, Bitbucket tools, host-provided MCP tools, provider CLIs, or local repository diffs.
labels:
  - code-review
  - pull-request
  - github
  - bitbucket
metadata:
  version: 0.1.0
---

## When to Use This Skill

Use this skill when you need to:
- Review the current branch's pull request
- Review a specific pull request by URL, number, or ID
- Analyze code changes for correctness, maintainability, testing, security, performance, and conventions
- Optionally post the review back to the pull request using whatever posting tool is available
- Re-review after code changes based on previous review feedback

## Tool Selection

This skill is intentionally provider-neutral and agent-neutral. Use the best available tool for the environment you are running in.

Prefer tools in this order:

1. **Structured PR tools** provided by the environment, such as provider connectors, plugins, MCP servers, or API-backed tools. Use these for PR metadata, changed files, diffs, existing comments, and posting review comments when available.
2. **Provider CLIs**, such as `gh` for GitHub or a Bitbucket CLI/API wrapper, when authenticated and available.
3. **Git commands** against local and remote branches when PR-specific tools are unavailable.
4. **User-provided diff or patch text** when no repository or provider tool can be queried.

Do not assume:
- The PR host is Bitbucket or GitHub until the remote URL, PR URL, or available tools make that clear.
- PR access is exposed through MCP.
- A specific coding agent, product, or host application is running this skill.
- Posting comments is possible or desired. Treat posting as optional and only do it when the user asks or the surrounding workflow clearly permits it.

### Capability Discovery

Before reviewing, quickly establish:
- Current branch and local git state
- Remote provider and repository identity
- Available PR tools or CLIs
- Whether the user requested local-only output or posting back to the PR
- Whether the user explicitly requested that tests and testing-related feedback be skipped

Useful discovery commands when shell access exists:

```bash
git branch --show-current
git remote -v
git status --short
command -v gh
command -v bb
```

If a structured tool is available, prefer it over parsing terminal output. If multiple tools are available, use the one that gives the most complete PR metadata and diff with the least brittle parsing.

## Workflow: Review Current Branch

Follow these steps when asked to review the current branch's PR.

### Step 1: Identify the Current Branch

```bash
git branch --show-current
```

If the working tree has uncommitted changes, mention whether the review is based on the remote PR, the local working tree, or both. Do not silently mix unrelated uncommitted changes into a PR review.

### Step 2: Determine Provider and Repository

Inspect the remote URL:

```bash
git remote get-url origin
```

Recognize common URL forms, including:
- `https://github.com/OWNER/REPO.git`
- `git@github.com:OWNER/REPO.git`
- `https://bitbucket.org/WORKSPACE/REPO.git`
- `git@bitbucket.org:WORKSPACE/REPO.git`

If the provider or repository cannot be determined, ask the user for the PR URL or repository identity.

### Step 3: Find the PR for This Branch

Use the best available method:
- GitHub structured tool or `gh pr view --json ...`
- Bitbucket structured tool or available Bitbucket CLI/API wrapper
- Provider web/API tool exposed by the environment
- User-provided PR URL or number

For GitHub CLI, typical commands are:

```bash
gh pr view --json number,title,headRefName,baseRefName,isDraft,url,headRefOid
gh pr diff
```

For Bitbucket, use the available structured tool, CLI, or API wrapper to list open pull requests whose source branch matches the current branch.

If no open PR is found, inform the user and stop. If the PR is a draft, inform the user and ask whether to continue unless they already asked to review drafts.

### Step 4: Get PR Metadata, Diff, and Changed Files

Collect:
- PR title, number/ID, URL, source branch, target branch, and draft status
- Current source/head SHA
- Unified diff or changed-file patches
- Existing review comments, if comment tools are available

Use provider tools when possible. Fall back to git diffs when needed:

```bash
git fetch --all --prune
git diff origin/TARGET_BRANCH...HEAD
git diff --name-status origin/TARGET_BRANCH...HEAD
git rev-parse --short HEAD
```

If the target branch is unknown, infer it from the PR metadata. If it cannot be inferred, ask the user before reviewing.

### Step 5: Check for Existing Review

When comments can be read from the PR, check for an existing review marker:

```markdown
<!-- PR-REVIEWER -->
```

If an existing review is found:

1. Save the existing root comment ID or thread ID if the platform supports replies or updates.
2. Extract the reviewed SHA from the `**HEAD:**` line.
3. Compare it with the current source/head SHA.
4. If the SHAs match, skip analysis and tell the user the PR was already reviewed at this commit.
5. If the SHAs differ, parse previous Concerns and Suggestions so the new review can identify resolved, remaining, and new concerns.
6. Track the next review round number. If the previous review says "Round N", use Round N+1; otherwise use Round 2.

If comments cannot be read, continue with a fresh local review and state that existing PR comments were not checked.

### Step 6: Analyze the Code

If the user explicitly asks to skip tests, not run tests, ignore tests, omit testing feedback, or avoid test-related comments:
- Do not run test commands.
- Do not add comments about missing tests, test coverage, test quality, test strategy, or test gaps.
- Omit the `### Testing` section from the review.
- Ignore testing-related preferences in the custom preference sections for this review.

Review the diff for:
- **Merge conflicts**: unresolved conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`). Treat these as critical blockers.
- **Correctness**: logic errors, edge cases, off-by-one errors, error handling, null/empty states, concurrency, transaction boundaries, and data consistency.
- **Maintainability**: clarity, naming, complexity, coupling, cohesion, duplication, and whether the change fits existing architecture.
- **Testing**: missing coverage, weak assertions, untested edge cases, brittle tests, and whether tests exercise the behavior changed by the PR. Skip this category entirely when the user explicitly disables testing feedback.
- **Security**: input validation, authentication/authorization, secrets, unsafe deserialization, injection, data exposure, and dependency risk.
- **Performance**: unnecessary I/O, N+1 queries, avoidable allocations, expensive loops, cache behavior, and algorithmic complexity.
- **Provider and framework conventions**: repository-specific patterns, framework idioms, and the preference sections below.

If a previous review exists, compare current findings against prior concerns:
- Resolved concerns
- Remaining concerns
- New concerns introduced since the last review

Prioritize concrete, actionable findings. Avoid listing generic advice unless it is tied to a specific changed line, behavior, or risk.

## Custom Style Guide Preferences

Use this section to store style preferences that should influence review comments. Treat these as review guidance, not absolute blockers, unless the preference explicitly says it is mandatory.

### General

- Prefer clear names over abbreviations except for widely understood terms such as `id`, `url`, and `api`.
- Keep comments focused on why a decision exists; avoid comments that restate the code.

### Java

- Prefer constructor injection over field injection.
- Prefer `Optional` for return values

### Python

- Prefer explicit exception types over broad `except Exception` blocks.
- Prefer type hints on public functions and module boundaries.

### TypeScript

- Prefer `unknown` over `any` at external boundaries, then narrow explicitly.
- Prefer discriminated unions over boolean flag combinations when modeling states.

## Custom Coding Convention and Practices Preferences

Use this section to store team or project engineering conventions that should influence severity, suggestions, and verdicts.

### General

- New behavior should include tests at the closest practical level: unit tests for local logic, integration tests for cross-component behavior, and end-to-end tests only for critical user flows.
- Prefer small, cohesive functions with single responsibilities. Extract helpers when branching or nested logic obscures the main behavior.

### Java

- Prefer immutable DTOs or records where framework constraints allow.
- Validate external input at service/API boundaries before passing data into domain logic.

### Python

- Keep side effects out of module import time unless the file is explicitly an executable entry point.
- Prefer dependency injection for clients and clocks so tests do not require network access or wall-clock timing.

### TypeScript

- Keep API response parsing and validation near the boundary before data enters application state.
- Avoid non-null assertions (`!`) unless the preceding code proves the value is present.

## Human Inspection Callouts

While reviewing, identify areas that warrant closer human attention because they require broad codebase context, domain knowledge, product judgment, operational context, or long-term maintenance judgment.

Mark these with a `🔍` emoji in the main review summary. Include the file path and most relevant line number or line range from the diff. Keep these consolidated in the main review; do not split them into separate inline comments unless the user explicitly asks.

Flag areas such as:

| Category | What to look for |
|----------|------------------|
| **Data models** | New fields, schema changes, serialization changes, or model restructuring that could affect downstream consumers, migrations, analytics, or compatibility contracts. |
| **Broadly callable code** | Functions, methods, APIs, hooks, commands, or shared utilities that can be invoked from many places and may have impact beyond the visible diff. |
| **Extension points** | Abstract classes, interfaces, plugin hooks, event handlers, dependency injection bindings, or public contracts that other code may implement or override. |
| **Maintainability concerns** | High complexity, deeply nested logic, excessive coupling, unclear naming, or missing abstractions that will create future maintenance friction. |
| **Standing maintenance burden** | Hardcoded configuration, manual operational steps, tight coupling to external systems, or patterns likely to require repeated follow-up work. |

Threshold for flagging: only flag genuinely nuanced spots. Aim for 0-5 callouts per PR, focused on the highest-leverage areas where human judgment adds value.

If there are no callouts, omit the section.

## Step 7: Format the Review

Lead with findings. Order concerns by severity and include file/line references whenever possible.

### First Review

Use this format when no existing review marker was found:

```markdown
## PR Review: [PR Title]

**Branch:** `source` -> `target`
**PR:** [provider] #[ID]
**HEAD:** `[SHORT_SHA]`

### Summary
[Brief 2-3 sentence summary of what the PR changes and the overall assessment.]

### Strengths
- [What is done well, if useful and specific.]

### Concerns
- [Severity] `path/to/file.ext:123` - [Specific issue, risk, and suggested fix.]

### Suggestions
- `path/to/file.ext:45` - [Non-blocking improvement.]

### 🔍 Areas for Human Inspection
- 🔍 **[Category]** `path/to/file.ext:123-145` - [Why this needs human judgment and what to verify.]

### Testing
- [What tests are present in summary form]
- [What tests are missing in summary form]

### Verdict
[Approve / Approve with suggestions / Request changes]
```

### Follow-Up Review

Use this format when an existing review marker was found and the head SHA changed:

```markdown
## PR Review: [PR Title] (Round N)

**Branch:** `source` -> `target`
**PR:** [provider] #[ID]
**HEAD:** `[SHORT_SHA]`
**Updated:** [timestamp]

### Summary
[Brief summary of what changed since the last review and current assessment.]

### Resolved Concerns
- [Concern from previous review that is now fixed.]

### Remaining Concerns
- [Concern from previous review that is still present.]

### New Concerns
- [New issue introduced or discovered in the updated code.]

### Suggestions
- [Non-blocking improvement.]

### 🔍 Areas for Human Inspection
- 🔍 **[Category]** `path/to/file.ext:123-145` - [Why this needs human judgment and what to verify.]

### Testing
- [What tests are added as part of resolving concerns]
- [What tests are still missing to address concerns]

### Verdict
[Approve / Approve with suggestions / Request changes]
```

Formatting rules:
- Omit empty sections except Summary and Verdict.
- Omit the `### Testing` section when the user explicitly asks to skip tests or testing-related feedback.
- Use `Request changes` for correctness, security, data loss, unresolved conflicts, or likely production regressions. Include broken tests in this category only when testing feedback has not been explicitly disabled.
- Use `Approve with suggestions` for non-blocking maintainability or style improvements. Include test improvements only when testing feedback has not been explicitly disabled.
- Use `Approve` only when no blocking concerns remain.

## Step 8: Post the Review (Optional)

Only post back to the PR when the user asks, when the invocation explicitly expects posting, or when the local workflow's norms make posting clear. Otherwise, present the review in the conversation and save it locally when appropriate.

When posting:
- Use the available provider-specific comment tool, CLI, or API.
- Prefer updating or replying to the existing `<!-- PR-REVIEWER -->` review thread if one exists.
- Include the marker so future runs can detect the previous review.
- Keep all human-inspection callouts in the main review comment unless the user asks for inline comments.

Comment body pattern:

```markdown
<!-- PR-REVIEWER -->

[REVIEW CONTENT]

---
*This review was generated by PR Reviewer Skill.*
```

If posting is unavailable or fails due to authentication or permissions, report the issue and keep the review local. Do not retry with a different provider unless the repository identity clearly supports it.

## Workflow: Review a Specific PR

When given a PR URL, number, or ID:

1. Parse the provider, repository, and PR identifier from the input when possible.
2. Use available provider tools or CLI to fetch PR metadata, diff, changed files, and existing comments.
3. If a bare number is provided and the repository/provider cannot be inferred, ask for the repository or PR URL.
4. Follow Steps 4-9 above.

## Workflow: Review All Open PRs

When asked to review all open PRs:

1. Determine the provider and repository.
2. Use the available provider tool or CLI to list open PRs.
3. Handle pagination according to the chosen tool's documented behavior.
4. Exclude draft PRs unless the user asked to include them.
5. Present the PR list for confirmation before starting reviews.
6. Review each selected PR using Steps 4-9.
7. End with a concise summary of verdicts and blockers.

## User Preferences

Respect these request patterns:

| Request | Behavior |
|---------|----------|
| "don't upload" / "local only" / "don't post" | Skip Step 8. Present and optionally save the review locally. |
| "post it" / "comment on the PR" | Post the review if a suitable tool and permissions are available. |
| "just the summary" | Provide a shorter review without detailed line-by-line analysis. |
| "focus on security" | Weight security analysis more heavily and lead with security findings. |
| "focus on testing" | Weight test coverage and test quality more heavily. |
| "skip tests" / "don't run tests" / "ignore tests" / "no testing comments" / "omit testing feedback" | Do not run test commands, omit the `### Testing` section, and avoid comments about missing tests, coverage, test quality, or test strategy. |
| "no annotations" / "skip inspection" | Omit the human-inspection callouts. |
| "annotations only" / "inspection only" | Skip the full review and produce only consolidated human-inspection callouts with file/line context. |
| "include drafts" | Include draft PRs in discovery and review. |

## Example Interactions

**User:** "Review my current branch's PR"  
Follow the full workflow using whatever PR tools are available.

**User:** "Review PR #42"  
Infer the provider/repo from the current git remote if possible, then review that PR.

**User:** "Review this GitHub PR but don't post it: [URL]"  
Fetch the GitHub PR, review locally, skip posting.

**User:** "Review this Bitbucket PR and comment on it: [URL]"  
Fetch the Bitbucket PR and post the review if an authenticated tool is available.

**User:** "Review all open PRs"  
List open PRs, confirm the selection, then review each selected PR.

**User:** "I've fixed the issues you found" / "done" / "updated"  
Trigger the re-review workflow.

**User:** "Just flag the areas I should look at more closely"  
Use inspection-only mode and produce consolidated human-inspection callouts.

## Error Handling

| Situation | Action |
|-----------|--------|
| No PR found for branch | Inform the user and suggest creating a PR or providing a PR URL. |
| Cannot determine provider or repository | Ask the user to provide the PR URL or repository identity. |
| Diff is empty | Inform the user the PR has no visible changes. |
| Existing review cannot be checked | Continue with a fresh local review and state that prior comments were unavailable. |
| HEAD SHA matches last review | Skip analysis and inform the user the PR was already reviewed at this commit. |
| API, CLI, or permission error | Report the specific failing tool and fall back to local git diff when possible. |
| Posting fails | Keep the review local and report that posting was unavailable. |
