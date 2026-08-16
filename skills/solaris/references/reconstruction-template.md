# Reconstruction Megaprompt Template

Use this outline as a drafting contract. Omit sections only when genuinely inapplicable, and say why. Replace every placeholder; never ship braces or TODOs.

## Table of contents

1. Opening directive
2. Result and fidelity
3. Evidence and compatibility
4. Product and workflows
5. System model and ownership
6. Information architecture and screens
7. Visual system and responsive behavior
8. Components and interactions
9. State, data, APIs, and events
10. Security, privacy, and reliability
11. Implementation and verification
12. Completion contract

## 1. Opening directive

Start with a compact operating mandate:

```markdown
Build a complete reconstruction of {APP} using only this megaprompt package. This package is the sole reconstruction authority: do not seek, inspect, run, browse, query, or obtain the original app, its source repository, deployment, private documentation, or the investigator's workspace. You may inspect your destination workspace, installed toolchain, and files bundled beside this prompt. Work autonomously from destination-environment discovery through verification. Preserve existing destination work, implement every required flow, run the reconstruction and tests, inspect it at the specified viewports, and repair failures. Do not stop at a plan, scaffold, static mockup, or happy path.
```

Add safety and clarification rules. State which side effects require confirmation.

## 2. The result and fidelity contract

Define:

- Who the app serves and the job it completes.
- What a user must be able to accomplish end to end.
- Required platforms, input modes, viewports, themes, locales, and user roles.
- Fidelity priorities in order: product, behavior, visual, data, integration, operational.
- Acceptable differences and forbidden shortcuts.
- Explicit non-goals.

Use a capability table:

| ID | Capability | User-visible outcome | Fidelity | Proof |
|---|---|---|---|---|
| C-01 | {name} | {observable result} | exact/equivalent/representative | {test or inspection} |

## 3. Handoff authority and destination discovery

Require the implementing agent to verify before coding:

- That this megaprompt and its explicit companion artifacts are the only permitted knowledge of the original.
- The artifact manifest, relative paths, checksums when provided, and normative versus illustrative status.
- The destination current directory, existing files, dirty work, and safe project placement.
- OS, runtime, package manager, lockfile, required tools, and relevant set/unset overrides without printing secrets.
- Required compatibility versions, schemas, and contracts stated or bundled in this handoff.
- Any stop condition that prevents satisfying the handoff safely, such as an unresolvable exact dependency.

Never instruct the agent to dump environments, credentials, auth stores, or private config. Never direct it back to the original app to fill a gap.

Include a self-contained authority and artifact summary:

| Item | Role | Relative path or embedded section | Normative status | Permitted use |
|---|---|---|---|---|
| megaprompt | complete specification | `MEGAPROMPT.md` | normative | implementation and verification |

## 4. Product model

Describe:

- Primary and secondary users.
- Roles, entitlements, trust levels, and role changes.
- Core objects using the product's exact nouns.
- Object lifecycle and meaningful status values.
- First-run, daily-use, recovery, and administrative workflows.
- Business rules, quotas, limits, ordering, filtering, and destructive-action semantics.

For every critical journey:

| Step | Preconditions | User action | System behavior | Visible feedback | Stored effect | Failure/recovery |
|---|---|---|---|---|---|---|

## 5. Architecture and sources of truth

State the system in one paragraph and one ownership table:

| Concern | Authority/source of truth | Reader/writer | Persistence | Identity | Concurrency rule |
|---|---|---|---|---|---|
| authentication | {system} | {components} | {location/lifetime} | {opaque/public ID} | {lease/conflict rule} |

Cover:

- Process and deployment topology.
- Frontend, server, worker, external service, and storage boundaries.
- Canonical working directory, tenant, project, account, or workspace context.
- Durable versus ephemeral state.
- Identity mapping across UI, API, and storage.
- Single-writer, locking, idempotency, generation, or stale-event rules.
- Restart, resume, migration, and reconciliation behavior.
- What must not be duplicated, rewritten, cached, or accepted from the client.

Include a small adapter boundary for volatile integrations and define the fake's observable behavior.

## 6. Information architecture

Inventory all destinations:

| ID | Route/destination | Purpose | Entry points | Exit paths | Roles | Deep-link/reload behavior |
|---|---|---|---|---|---|---|

Describe global navigation, back behavior, breadcrumbs, tabs, drawers, modals, command menus, and preserved navigation state. Specify unknown-route and expired-deep-link behavior.

## 7. Per-screen dossier

Repeat this block for every distinct screen, overlay, modal, drawer, and meaningful responsive variant:

### {Screen name} — {route or trigger}

- **Purpose:** {single job}
- **Entry/exit:** {all paths}
- **Access:** {role/permission/preconditions}
- **Page anatomy:** {regions in reading and visual order}
- **Primary action:** {label, placement, enabled rules}
- **Secondary actions:** {labels and hierarchy}
- **Displayed data:** {fields, formatting, ordering, truncation, freshness}
- **Controls:** {type, label, options, default, validation, persisted scope}
- **States:** initial, loading, skeleton, populated, empty, filtered-empty, partial, stale, disabled, forbidden, error, offline, reconnecting, success.
- **Scrolling:** owner, sticky regions, containment, restoration, auto-scroll threshold.
- **Responsive:** what reflows, wraps, collapses, becomes a drawer, hides, or remains fixed at each breakpoint.
- **Keyboard/focus:** tab order, shortcuts, initial/return focus, Escape, focus trap.
- **Announcements:** labels, live regions, error association, status updates.
- **Acceptance:** viewport-specific observable checks.

Name every consequential bit of copy exactly. If copy is unknown, give its semantic purpose and tone instead of inventing a quote.

## 8. Visual system

Capture relationships before isolated values.

### Geometry

| Token/region | Value or evidenced range | Relationship/rule | Responsive change |
|---|---|---|---|
| content width | {value} | {centering/gutter rule} | {change} |

Cover grids, max widths, gutters, spacing rhythm, density, radii, border widths, elevation, alignment, and z-index layers.

### Typography

Inventory family/fallback, scale, weight, line height, tracking, casing, wrapping, code, tabular numbers, and truncation. Preserve licensed assets only when supplied and permitted; otherwise specify a metric-compatible or clearly acceptable fallback.

### Color and themes

Specify semantic tokens for canvas, surface, raised surface, text levels, border, accent, focus, selection, success, warning, danger, disabled, overlay, and syntax. Include light/dark/high-contrast behavior where observed.

### Icons, imagery, and motion

Inventory assets and usage rights, size/stroke/fill rules, cropping and empty-image behavior, transition purpose/duration/easing, reduced-motion equivalents, streaming/update batching, and prohibited decorative substitutions.

## 9. Component contracts

For each reusable component, define variants, sizes, anatomy, inputs, outputs, state ownership, validation, disabled/busy behavior, overflow, keyboard behavior, accessibility role/name, and responsive behavior.

| Component | Variants | States | Contract | Accessibility | Edge cases |
|---|---|---|---|---|---|

Do not specify components that merely resemble functionality. A setting must change the active system behavior it claims to control.

## 10. Interaction contracts

Document each consequential interaction:

| Trigger | Preconditions | Immediate response | Async lifecycle | Success | Failure | Cancel/retry | Persisted effect |
|---|---|---|---|---|---|---|---|

Include hover-independent mobile behavior, double-submit prevention, destructive confirmation and undo, optimistic updates and rollback, drag/drop fallback, clipboard feedback, file limits, selection, search debounce, pagination/infinite scroll, queue semantics, and interrupted navigation where applicable.

## 11. State machines and reconciliation

Use an explicit transition table for non-trivial lifecycles:

| Current state | Event | Guard | Action | Next state | Visible result |
|---|---|---|---|---|---|

Cover:

- Accepted versus settled work.
- Queued, steering, follow-up, canceling, retrying, compacting, or reconnecting states where relevant.
- The authoritative completion signal; do not end on a convenient intermediate event.
- Stable item IDs, monotonic event IDs, replay window, snapshot fallback, and deduplication rules.
- Stale-event rejection after context/session replacement.
- Cross-tab, cross-device, and cross-process writers.
- Restart recovery and partial failure.

## 12. Data model, persistence, and contracts

Define entities and relationships:

| Entity | Fields and types | Required/default | Validation | Identity | Retention/sensitivity |
|---|---|---|---|---|---|

For each API, command, event, or stream provide method/name, path/channel, auth, request schema, response/event schema, status codes, ordering, idempotency, limits, error shape, retry policy, timeout, and examples with fabricated non-secret values.

Specify:

- Local/client storage allowlist.
- Server persistence and migration rules.
- Cache ownership, invalidation, and stale policy.
- File/path canonicalization and opaque identifier resolution.
- Payload and tool-output bounds.
- Secret redaction in logs, errors, built assets, and responses.

## 13. Content and command language

Inventory titles, labels, help text, validation, notices, permission errors, empty states, recovery actions, and confirmation copy. Specify terminology, tone, date/number/path formatting, pluralization, and localization behavior.

For command palettes, slash commands, shortcuts, or templates, distinguish discoverable commands from actions implemented as native UI. Define autocomplete, expansion, unsupported-command behavior, and collision rules.

## 14. Security, privacy, and trust boundaries

State threat boundaries and negative requirements explicitly:

- Bind/exposure and allowed hosts/origins.
- Authentication, authorization, session, CSRF, CORS, CSP, and proxy trust.
- Workspace/file containment using canonical filesystem checks rather than string prefixes.
- Untrusted Markdown/HTML/URLs/images/file names/tool output handling.
- Request sizes, rate/concurrency limits, timeouts, and denial-of-service bounds.
- Secrets and sensitive fields that must never be returned, logged, copied, embedded, or displayed.
- Extension/plugin/tool trust and sandbox limitations.
- Network boundary versus execution sandbox distinctions.
- Forbidden public hosting, telemetry, arbitrary command endpoints, or credential forms when applicable.

Require targeted allow/deny tests for every stated boundary.

## 15. Accessibility, responsiveness, performance, and resilience

Define:

- Semantic regions and heading hierarchy.
- Accessible names/descriptions, focus visibility, modal/drawer focus management, error association, live announcements, and contrast.
- Keyboard-only and touch-only completion of core journeys.
- Viewport matrix including the narrowest supported width; safe-area and virtual-keyboard behavior.
- Loading and interaction budgets grounded in evidence or reasonable decisions.
- Render/update batching, virtualization thresholds, bounded output, and memory cleanup.
- Offline, slow, timeout, reconnect, replay, duplicate, stale, and server-restart behavior.

## 16. Fixed constraints and permitted choices

Separate these clearly:

| Category | Constraint | Why | Verification |
|---|---|---|---|
| fixed | {version/host/protocol/etc.} | {compatibility/evidence/security} | {check} |
| permitted | {library/design choice} | {not observable} | {must still satisfy} |

Avoid freezing a stack merely because it is familiar. Freeze compatibility boundaries; allow internal substitutions that preserve contracts unless the handoff requires source-level fidelity. Resolve gaps using the listed safe default; do not consult the original.

## 17. Build order

Use this sequence unless the app demands another dependency order:

1. Inspect the destination environment and supplied package, verify version constraints, and write a short implementation checklist.
2. Define browser-safe/domain contracts, sources of truth, and adapter interfaces.
3. Build a deterministic fake and one vertical slice end to end.
4. Add the real integration and remaining core flows while keeping default tests deterministic.
5. Implement responsive, accessible, loading, empty, error, offline, and recovery states.
6. Harden trust boundaries, limits, reconciliation, and production operation.
7. Run the entire verification suite, launch production, inspect manually, and repair defects.

Forbid TODOs, cosmetic toggles, fake data in production paths, and replacement of required behavior with prose.

## 18. Test without unsafe or costly side effects

Define a deterministic fake for external, paid, credentialed, or destructive dependencies. Default tests must not spend money, alter production, contact real users, or require secrets.

Use a matrix:

| Level | Scenario | Setup | Assertions | Negative case |
|---|---|---|---|---|
| unit | {rule} | {fixture} | {observable result} | {invalid input} |
| integration | {contract} | {fake} | {state/response} | {failure} |
| e2e | {journey+viewport} | {seed} | {visible outcome} | {recovery} |
| manual | {visual/real integration} | {safe environment} | {inspection} | {known limitation} |

Include contract, state-machine, responsive, keyboard, accessibility, malicious-input, path/ID containment, secret-redaction, reconnect/resnapshot, duplicate prevention, concurrency, and restart tests when applicable.

## 19. Commands and production operation

Give exact commands for install, dev, format/lint, strict typecheck, unit/integration tests, e2e, build, start, and health check. Define host/port/config validation, conflict errors, logging, shutdown, service lifecycle, backup/migration, and private access where relevant.

Do not install OS services, widen network exposure, publish, or change machine-level configuration without explicit confirmation. Document optional commands separately.

## 20. Definition of done

Write a numbered, falsifiable checklist. Include:

1. Every critical user journey works against the intended authority.
2. The app survives refresh/restart and reconciles without duplicate or lost state.
3. Loading, empty, partial, error, offline, retry, cancel, and permission states behave as specified.
4. Required desktop/mobile/keyboard/screen-reader flows pass.
5. Trust boundaries have passing allow and deny tests.
6. Typecheck, tests, e2e, build, production start, and health checks pass.
7. Manual comparison at named viewports meets the stated fidelity tolerance.
8. Built assets, sampled logs, and responses contain no secrets.
9. Documentation covers operation, limitations, and intentional omissions.

Customize these checks to the evidence. Never declare success based only on file existence or a passing build.

## 21. Final handoff contract

Require the implementing agent to report:

- Local URL or launch path and exact restart command.
- Architecture and source-of-truth summary.
- Files and durable state created or modified.
- Commands and checks passed.
- Viewports and workflows manually inspected.
- Deviations from the target, evidence gaps, and real integration limitations.
- Optional machine-level or external next action as an explicit question, not an assumed side effect.

End with `Unknowns and permitted decisions`, listing each unresolved item, safe default, impact, and the rare condition that requires user input. Never use “inspect the original” as a resolution path.
