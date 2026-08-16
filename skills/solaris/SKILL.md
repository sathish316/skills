---
name: solaris
description: Analyze an existing application and produce a standalone, evidence-backed, implementation-ready reconstruction prompt for another coding agent. Use when asked to reverse-engineer, clone, recreate, document, or describe an app in painful detail from source code, a running app, URLs, screenshots, videos, docs, or a user walkthrough; when creating a one-shot build prompt; or when converting observed product behavior into an executable specification with architecture, state, interactions, edge cases, security, tests, and definition of done.
---

# Solaris

Produce a closed-book reconstruction contract that lets a fresh agent rebuild the app without access to the original app, its source, its URL, or your investigation context. Agent 1 uses this skill to study the original; Agent 2 receives only the resulting megaprompt and explicitly bundled artifacts. Capture the app as a working system, not a collection of screenshots.

Treat the handoff as an app engram: externalize enough of Agent 1's observed memory that Agent 2 can reproduce the product without contacting the original.

Painful detail means eliminating consequential decisions. Prefer exact behavior, ownership, constraints, and acceptance criteria over long prose.

## Load the references

Read both before drafting:

- [reconstruction-template.md](references/reconstruction-template.md) for the required output structure.
- [quality-gates.md](references/quality-gates.md) for the final audit and common failure modes.

## Establish the reconstruction target

Identify:

- The app, version or commit, platform, user roles, and intended outcome.
- The evidence available: source, running build, deployed URL, screenshots, video, docs, tests, design files, API schemas, or user narration.
- The fidelity target: visual, behavioral, data-compatible, architecture-compatible, or some combination.
- The requested output location and handoff form. Default to `MEGAPROMPT.md`. Create a companion `megaprompt-artifacts/` directory only when the reconstruction needs supplied images, icons, fonts, sanitized fixtures, schemas, or visual references that cannot be expressed faithfully in prose.

Do not block on details that can be discovered safely. Ask only when a missing choice would materially change the reconstruction and evidence cannot resolve it.

## Build an evidence ledger

Investigate before prescribing. Keep working notes with these labels:

- **Observed**: directly witnessed in the running app or verified in source, tests, types, config, assets, or official docs.
- **Derived**: logically implied by multiple observations.
- **Decision**: a reconstruction choice required because the original is unknowable or unsuitable.
- **Unknown**: consequential behavior that remains unresolved.

Attach a source pointer to important facts in Agent 1's private working ledger: file and symbol, route, screenshot/frame, interaction sequence, network contract, or document section. Never upgrade a guess into a fact. Do not rely on these pointers in the final handoff unless the referenced material is intentionally bundled; translate the evidence into complete requirements.

Resolve conflicts using this order unless the target demands otherwise:

1. Actual runtime behavior for user-visible semantics.
2. Executed tests, public contracts, types, and current source.
3. Current configuration, assets, and official documentation.
4. Inference from conventions.

Call out conflict instead of silently blending incompatible evidence. Treat the installed version or captured build as the compatibility target.

## Inspect by evidence mode

### Source available

Preserve existing work. Inspect manifests, lockfiles, runtime versions, entry points, routes, components, styles/tokens, state stores, domain types, persistence, APIs/events, auth, feature flags, assets, tests, build/deploy configuration, and error handling. Run only safe, relevant diagnostics. Use the real implementation to identify sources of truth and ownership boundaries.

### Running or deployed app available

Exercise harmless workflows at desktop and mobile widths. Record navigation, keyboard behavior, focus, scrolling, loading, success, empty, error, permission, offline/reconnect, and persistence behavior. Capture exact copy, control states, timing thresholds when meaningful, responsive transitions, and observable request/event contracts. Do not mutate production data or cross authorization boundaries.

### Screenshots or video only

Inventory every distinct screen and frame. Infer cautiously. Separate visible facts from guessed behavior, and specify the smallest sensible behavior needed to connect the observed states. Ask for missing critical states when they would alter architecture or workflows.

### Documentation or narration only

Turn claims into testable requirements. Preserve domain terminology exactly. Flag ambiguities, contradictions, and missing failure states rather than inventing certainty.

## Capture four fidelity layers

Cover all applicable layers:

1. **Product**: users, jobs, workflows, permissions, scope, and success conditions.
2. **Experience**: information architecture, screens, layout, visual tokens, content, interactions, accessibility, responsiveness, and polished non-happy states.
3. **Behavior**: state machines, validation, queues, retries, cancellation, persistence, synchronization, concurrency, identity, reconciliation, and failure recovery.
4. **System**: compatibility target, architecture, sources of truth, data/API/event contracts, security boundaries, operational model, tests, and deployment.

Do not mistake visual resemblance for reconstruction. A plausible shell with fake controls fails if the original control changes real state.

## Convert observations into executable requirements

Write the final megaprompt directly to the implementing agent in imperative language. Make it standalone: externalize all consequential knowledge from Agent 1's memory, but do not include investigation chatter.

Enforce the closed-book boundary:

- Tell Agent 2 that the megaprompt package is the sole reconstruction authority.
- Do not tell Agent 2 to inspect, run, browse, query, or obtain the original app, source repository, deployment, private docs, or Agent 1's workspace.
- Do not leave requirements as inaccessible file paths, source symbols, URLs, screenshots, videos, or phrases such as “match the original.” Describe the behavior and appearance fully or bundle the required artifact with a relative path.
- Allow Agent 2 to inspect only its own destination workspace, installed toolchain, and the supplied megaprompt package.
- Preserve uncertainty as an explicit permitted decision with a safe default. Never send Agent 2 back to the original for clarification.

Choose one handoff form:

1. **Single-file megaprompt**: embed every requirement, contract, value, and small example in `MEGAPROMPT.md`.
2. **Self-contained package**: provide `MEGAPROMPT.md` plus `megaprompt-artifacts/`; add a manifest describing every relative file, purpose, permitted use, and whether it is normative or illustrative.

Bundle only what Agent 2 may legitimately use. Remove secrets and personal data. Do not bundle original source code merely to avoid describing it. Preserve licensed assets only when the user has supplied or authorized their reuse; otherwise describe a replacement contract.

For each feature, specify:

- Preconditions and entry points.
- Exact user actions and system reactions.
- Visible states and transition rules.
- Data read, written, retained, or discarded.
- Ownership and source of truth.
- Validation, permissions, limits, and concurrency rules.
- Loading, empty, partial, error, reconnect, cancel, retry, and recovery behavior.
- Desktop, mobile, keyboard, focus, and screen-reader expectations.
- Observable acceptance checks.

Use tables for inventories and contracts, state diagrams or transition tables for non-trivial lifecycles, and exact copy where copy is part of the experience. Use ranges or relationships when exact pixels are not evidenced; do not fabricate measurements.

## Prescribe implementation deliberately

- Pin versions or a stack only when compatibility, evidence, environment, or the user requires it.
- Prefer behavior and contracts over needless library choices.
- Name the authoritative subsystem for models, sessions, auth, files, settings, and other durable state.
- Prevent parallel writers, duplicate stores, arbitrary identifiers/paths, cosmetic settings, and other split-brain designs.
- Put volatile integrations behind a small typed adapter and define a deterministic fake when tests would otherwise require external services, credentials, or paid calls.
- Specify trust boundaries and negative security requirements: what must never be exposed, logged, accepted, executed, widened, or deployed.
- Order work from discovery to contracts to one end-to-end vertical slice, then breadth, hardening, and verification.
- State explicit non-goals to stop attractive scope drift.

## Make completion falsifiable

End with:

- Exact destination install, development, typecheck, test, build, start, and health-check commands when applicable.
- A test matrix that covers core flows, responsive layouts, accessibility, failure recovery, security boundaries, persistence, and reconnect/concurrency behavior.
- A numbered definition of done written as externally observable outcomes.
- A handoff contract listing what the implementing agent must report.
- A short `Unknowns and permitted decisions` section. Give safe defaults and escalation rules rather than leaving silent gaps.

Require the implementing agent to inspect its destination environment and supplied package, then build, test, run, inspect, and repair—not merely plan, scaffold, or mock. Do not demand access to the original or unsafe/external side effects without explicit user confirmation.

## Audit before delivery

Apply [quality-gates.md](references/quality-gates.md). Revise until every hard gate passes. Remove repetition that adds no decision value, but retain detail needed to implement, test, secure, operate, or compare the reconstruction.
