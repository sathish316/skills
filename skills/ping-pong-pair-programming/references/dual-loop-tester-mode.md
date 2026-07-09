# Dual-Loop-Tester Mode

**Loop scope: outer + inner.**

Tester mode's sibling: the human still writes all production code, but your
tests now come at **two levels**. You plant the outer oath as the
destination (red — and it *stays* red for a while), then lay down inner
unit tests as **waypoints**: small, reachable steps the human implements,
each green waypoint closing the distance until the last one tips the outer
oath green. The finished trail is something the human should be able to
marvel at.

| Artifact | Owner |
|----------|-------|
| Oath prose (`specs/**`) | Agent |
| Step bindings (glue) | Agent |
| Inner unit tests (e.g. `src/test/**`) | Agent |
| Production code (e.g. `src/main/**`) | **Human** |

## Permission setup

Deny the agent write access to production source only — note the split:
`src/test/**` is agent-writable (waypoints live there), `src/main/**` is
not.

Everything from [tester-mode.md](tester-mode.md) carries over — the
roadmap discipline, clarify-before-spec, requirements review at the red
gate. This file adds the inner loop.

## Waypoint (defined term)

A **waypoint** is an inner unit test that forces exactly **one new design
decision**. Not every waypoint makes the outer oath green — that's the
point. Good routes follow classic TDD triangulation: degenerate case first,
then one axis, then generalize.

## The loop

1. Write the outer oath + glue; show the outer red.
   `🔴 Outer red gate — dual-loop-tester mode: review these claims as
   requirements.` **STOP.**
2. Lay the first waypoint. **Name its purpose** — "this one forces the
   movement delta out of the switch and into Heading" — so the trail reads
   as a design narrative, not a test list.
3. Inner gates are **lighter**: a one-line announcement per cycle
   ("inner red: `left()` from N expects W"), human implements, you confirm
   inner green. Full STOP-and-wait ceremony at unit granularity would be
   exhausting; save the full review for the outer green gate.
4. **Re-run the outer oath at every waypoint green** — not because it
   should pass, but so the human sees the distance closing. If it passes
   *early*, you over-decomposed: review the remaining waypoints for
   deletion.
5. When the outer oath goes green, run the full green-gate checklist
   (oaths **and** unit tests). `🟢 Outer green gate.` **STOP.**

## The trail is the artifact

Maintain `trail.md` (or a section of the decision log) mapping each
waypoint to **what it forced into existence**. At the outer green gate the
human gets a readable story of how the design emerged.

## Waypoints are permanent

Waypoints stay in the unit-level suite forever — no pruning ceremony at
the outer gate; the trail *is* the suite. Two consequences:

- **Each waypoint must survive on its own merits**, readable a year later
  detached from its trail: name it for the rule it pins
  (`left_from_north_faces_west`), never its sequence position
  (`step3_test`). The narrative lives in `trail.md`; the tests keep the
  rules.
- **Maintenance cost is accepted — so own it.** Behavior changes now touch
  two levels, and you own both specs and unit tests: update affected
  waypoints proactively rather than leaving the human red at a level they
  don't own.

## Amended constitution

The outer-loop rule "never duplicate a claim across levels" becomes:
**oaths state behavior in stakeholder language; waypoints state the same
territory in design language — overlap across levels is expected,
duplication within a level is not.** The redundancy is a feature: when a
refactor breaks something, the oath tells you *what* behavior broke while
the waypoint tells you *where* — coarse and fine bisection for free.

## Hints

Stuck on an inner red → green is a smaller version of the outer situation:
same ladder, same sources (the failing output and the waypoint's stated
purpose), same boundary — no paste-ready production code, ever.
