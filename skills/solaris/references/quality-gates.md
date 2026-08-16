# Megaprompt Quality Gates

Use this audit after drafting. A megaprompt is complete when another capable agent can implement it from the handoff alone—without the original app, source, URL, private docs, or investigator context—and success can be judged without taste-based debate.

## Table of contents

1. Hard gates
2. Scored rubric
3. Failure patterns
4. Compression pass

## Hard gates

Revise if any answer is no.

### Grounding

- Is the exact target version/build and evidence set named?
- Did Agent 1 trace consequential facts during capture, then translate them into complete handoff requirements rather than inaccessible evidence pointers?
- Are contradictions and unknowns visible rather than silently resolved?
- Does the prompt avoid invented pixels, APIs, events, copy, and guarantees?

### Standalone execution

- Can a fresh agent understand the product, users, flows, system boundaries, and completion target without the original source, runtime, URL, docs, or conversation?
- Does it explicitly forbid retrieving the original and declare the handoff the sole reconstruction authority?
- Does it require only destination-environment and supplied-package discovery before implementation?
- Are every referenced image, schema, fixture, font, icon, or document bundled at a working relative path with a manifest, or fully described inline?
- Does it say what to do when a required compatibility assumption fails?
- Does it distinguish actions the agent may take autonomously from side effects needing confirmation?

### Product and behavior

- Are all critical journeys specified from entry through persistence and recovery?
- Does every consequential control change real state rather than merely appear functional?
- Are loading, empty, partial, disabled, permission, error, offline, reconnect, cancel, retry, and restart states covered where relevant?
- Are queues, concurrency, identity, ownership, completion, replay, deduplication, and stale-event rules explicit for stateful apps?

### Experience fidelity

- Are routes, screens, overlays, responsive variants, navigation, and back/reload behavior inventoried?
- Are layout relationships, typography, colors, assets, motion, scrolling, overflow, and content hierarchy reproducible?
- Are mobile, touch, keyboard, focus, screen-reader, contrast, and reduced-motion behaviors stated?
- Are the narrowest width and important viewport comparison points named?

### System integrity

- Is each durable concern assigned one authority/source of truth?
- Are client/server/external boundaries, IDs, paths, persistence, and restart behavior explicit?
- Are real integrations isolated behind typed contracts, with deterministic fakes where appropriate?
- Are library and stack constraints justified by compatibility or evidence rather than preference?

### Security and operations

- Are trust boundaries and negative security requirements stated?
- Are secret handling, untrusted content, authorization, origin/host, path containment, request limits, and exposure addressed where relevant?
- Are install, dev, test, build, start, and health checks exact?
- Are machine-level, public, destructive, paid, or externally visible actions confirmation-gated?

### Verification

- Does every major capability have observable acceptance evidence?
- Do tests exercise failures and malicious inputs, not only the happy path?
- Does the default suite avoid production mutations, paid calls, and secrets?
- Is definition of done falsifiable, and does handoff require deviations and limitations?

## Scored rubric

Score each dimension 0–2:

- **0**: missing or mostly subjective.
- **1**: present but ambiguous, incomplete, or weakly testable.
- **2**: explicit, evidence-backed, and falsifiable.

| Dimension | Question |
|---|---|
| Target | Is the version/build, platform, user, scope, and fidelity target exact? |
| Evidence | Were observations converted into self-contained requirements, with honest unknowns and no inaccessible pointers? |
| Journeys | Are complete workflows and negative states reconstructable? |
| Experience | Can screens, responsive behavior, content, and accessibility be reproduced? |
| State | Are lifecycle, authority, persistence, concurrency, and recovery unambiguous? |
| Contracts | Are data, API, event, integration, identity, and limit contracts sufficient? |
| Security | Are trust boundaries, forbidden behavior, and allow/deny checks explicit? |
| Execution | Is build order practical, vertical, and compatible with the real environment? |
| Verification | Are commands, tests, visual inspection, definition of done, and handoff falsifiable? |

Pass only at 16/18 or higher, with no zero and all hard gates passing. A high word count does not increase the score.

## Failure patterns and repairs

### Leaky handoff

**Symptom:** Agent 2 is told to inspect the original repository, browse the live app, read an investigator-local path, follow an external/private document, or “match the reference” without receiving it.

**Repair:** Convert the observation into an explicit contract or bundle a sanitized, authorized artifact at a relative path. Declare the package the sole authority and give unknowns safe defaults.

### Screenshot-shaped shell

**Symptom:** Detailed colors and cards, vague workflows and state.

**Repair:** Specify journeys, transition tables, sources of truth, persistence, failure recovery, and contract tests. Treat the conversation/workflow as the product, not decorative chrome.

### Adjective specification

**Symptom:** “Modern,” “polished,” “fast,” “responsive,” or “secure” without observable meaning.

**Repair:** Replace each adjective with layout rules, viewports, timing/behavior budgets, focus behavior, or passing checks.

### Architecture fan fiction

**Symptom:** The prompt invents the original stack or forces familiar libraries without evidence.

**Repair:** Freeze observable and compatibility boundaries. Mark internal choices as permitted unless source-level fidelity matters.

### Split brain

**Symptom:** The reconstruction creates a second database, transcript, auth system, settings store, or model list beside the real authority.

**Repair:** Name one source of truth, define IDs and ownership, use public APIs, and prohibit manual rewriting of authoritative state.

### Cosmetic controls

**Symptom:** A toggle changes UI text but not the active tool/model/permission/runtime behavior.

**Repair:** Specify the mutation path, idle/busy guards, persistence scope, integration method, and an end-to-end assertion.

### Convenient completion

**Symptom:** Work is marked finished on an intermediate message/event while queues, retries, compaction, or continuations remain.

**Repair:** Name the authoritative settled signal and fallback invariant. Test abort, retry, queue, and reconnect races.

### Fuzzy reconciliation

**Symptom:** Streaming and restored content are deduplicated by text or timestamps.

**Repair:** Require stable IDs, generations, monotonic events, bounded replay, snapshot fallback, and stale-event rejection.

### Happy-path theater

**Symptom:** Only the populated desktop screen is described and tested.

**Repair:** Add first-run, empty, loading, partial, error, permission, offline, reconnect, narrow mobile, keyboard, and restart cases.

### Security slogan

**Symptom:** “Use best practices” replaces a threat boundary.

**Repair:** State allowed and forbidden hosts/origins/paths/content, secret fields, exposure, limits, proxy trust, sandbox reality, and targeted negative tests.

### Unbounded one-shot mandate

**Symptom:** “Work autonomously” implicitly authorizes publishing, installing services, changing global tools, spending money, or mutating production.

**Repair:** Separate in-workspace build/test autonomy from machine-level and external side effects that require confirmation.

### Checklist without proof

**Symptom:** “Feature complete” or “looks right” is the definition of done.

**Repair:** Turn completion into commands, routes, state transitions, viewports, fixtures, allow/deny tests, and visible outcomes.

## Compression pass

After all gates pass:

1. Delete duplicated rationale while retaining the requirement and its reason once.
2. Replace repeated prose with a table, state machine, schema, or shared invariant.
3. Remove facts that do not affect implementation, verification, security, operation, or fidelity.
4. Preserve non-goals, negative requirements, edge cases, and completion checks; these are high-value detail.
5. Read the prompt as a fresh implementing agent. If any consequential choice still requires guessing, add the missing contract.
6. Search for inaccessible phrases and pointers such as “inspect the source,” “open the original,” “see current app,” absolute investigator paths, private URLs, and unbundled screenshots. Replace or bundle them.

The ideal megaprompt is exhaustive in decisions, not maximal in words.
