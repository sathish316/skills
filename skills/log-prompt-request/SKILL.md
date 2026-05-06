---
name: log-prompt-request
description: Log user prompt requests from the current coding session into one append-only session markdown file. Use when the user asks to log, capture, record, journal, audit, or save their prompts, instructions, requests, or coding-session inputs. Use this skill whenever prompt_requests or prompt logging are mentioned.
---

# Log Prompt Request

Capture user inputs from the current coding session as durable markdown records in a single session log file.

This skill logs prompt requests only. It does not log command output, model reasoning, hidden system/developer messages, credentials, or unrelated file contents unless the user explicitly asks and it is safe to do so.

## Default Storage

Write prompt request logs under:

`logs/prompt_requests/`

Use one datetime-sortable file per coding session:

`YYYY-MM-DDTHH-MM-SS±TZ--session.md`

Example:

`logs/prompt_requests/2026-05-06T18-42-10+05-30--session.md`

The timestamp in the filename is the session log start time. Append all subsequent logged user requests from the same coding session to that same file. If the user specifies a different directory or file format, follow the user's instruction.

## Session File Format

When creating a new session log file, initialize it with:

```markdown
# Prompt Requests: Coding Session

**Session started**: <ISO-like local datetime with timezone>
**Source**: visible user prompts

```

Append each user request using this format, separated by blank lines:

```markdown
---

## Request <n> - <ISO-like local datetime with timezone>

<verbatim user prompt text, preserving line breaks where practical>

```

Use newline separation exactly as shown: a horizontal rule, a blank line, the request heading, a blank line, the prompt text, and a trailing blank line.

## Filtering Logging-Control Lines

Filter out lines whose only purpose is to control prompt logging. Do not append pure logging-control requests to the session log.

Examples of logging-control lines to omit:

- `log this prompt`
- `start logging my prompts`
- `stop logging prompt requests`
- `modify log-prompt-request skill`
- `make sure log-prompt-request filters logging requests`
- `save my prompts under logs/prompt_requests`

If a user prompt contains both logging-control text and a substantive request, log only the substantive request. Preserve the original wording of the substantive request as much as possible, but omit the logging-control lines.

If removing logging-control text leaves the prompt empty, do not append a request entry. Report that no substantive prompt request was logged.

## Process

### 1. Determine Scope

Identify what the user wants logged:

- **Current prompt only**: append the latest user request to the current session log.
- **Specific prompts**: append only the prompts the user identifies.
- **Ongoing session logging**: when the user asks to log the coding session, append each subsequent visible user request whenever this skill is applicable.

If the scope is unclear, default to the current prompt only and say that ongoing logging requires the user to ask for session logging explicitly.

### 2. Create or Reuse the Session Log

Ensure `logs/prompt_requests/` exists before writing.

For the current coding session, reuse the same session log file once created. If no session log file is known for the current session, create a new one using the current local datetime.

Do not place prompt request logs inside `skills/`, `resources/`, or temporary directories unless explicitly requested.

### 3. Filter the Request

Before appending, remove logging-control lines as described above. This prevents the prompt log from filling with requests about the logging mechanism itself.

If the filtered request is empty, stop and report that no substantive prompt request was logged.

### 4. Append the Request

Append one section per user request. Preserve the user's wording as much as possible.

Before appending, check for obvious secrets such as API keys, passwords, private tokens, or credentials. If a secret appears in the prompt, redact the secret value in the log and add a short redaction note after the prompt text. Do not print the secret back to the user.

Use the next request number by counting existing `## Request ` headings in the session log. Do not overwrite prior requests.

### 5. Report the Result

After appending, report the path to the session log file and the request number appended. Keep the response concise.

## Ongoing Session Logging

If the user explicitly asks to log all prompts in the current coding session, treat future user prompts as loggable prompt requests until the user says to stop. For each future prompt:

- Append the prompt to the same session file before doing substantial work on it.
- Keep using `logs/prompt_requests/` unless the user changes the destination.
- Do not log assistant-only progress updates.
- Do not log tool output unless the user explicitly asks.

Because skill invocation depends on the agent recognizing the logging context, mention any limitation if continuous logging cannot be guaranteed by the runtime.

## Principles

- Preserve user intent and wording.
- Prefer one append-only file per coding session over one file per prompt.
- Keep requests chronologically ordered by append order.
- Avoid storing secrets.
- Do not let logging derail the user's actual coding task.
