# Tester Mode

**Loop scope: outer only.**

Classic ping-pong inverted: you write the failing test, the human makes it
pass. You do the probing; they do the design thinking.

| Artifact | Owner |
|----------|-------|
| Oath prose (`specs/**`) | Agent |
| Step bindings (glue) | Agent |
| Production code | **Human** |

## Permission setup

Ask the human to **deny you write access to production source**
(e.g. `src/main/**`) so you can't "help" by implementing. The boundary
works because it's enforced both ways — encourage the human to keep their
hands off `specs/` too.

## Roadmap-driven stepping

You control sequencing in this mode, which is its structural weakness — you
might jump to obstacles before wrapping. Fix it with a **human-owned
roadmap**: an index oath file with no claims, just a checklist of behaviors
mapped to spec files. Propose and maintain the roadmap, but the human rules
on it. At each cycle state: *"next smallest step per roadmap: X — agree?"*
Work strictly top-down, one new oath file per unchecked item.

## Clarify before spec

Before drafting claims for a behavior, surface every genuine design
decision and get a ruling — e.g. "wrap at the edge, or refuse to move? I
propose refuse, because it reuses the STOPPED vocabulary we already have."
The spec gate must review a **resolved design, not a guess**. Never write
claims while a known ambiguity is unresolved. Record rulings in the
decision log.

## The loop

1. Agree the next smallest step from the roadmap.
2. Clarify open design decisions (above).
3. Write/extend the oath prose and the step bindings. Stub enough to
   compile so the red is behavioral.
4. Run the suite; present the new claims and the failure.
   `🔴 Red gate — tester mode: please review these claims as requirements.`
   **STOP.**
5. Human implements in production code until green, then tells you.
6. Verify green yourself; run the whole suite; walk the green-gate
   checklist; optionally suggest a refactor.
   `🟢 Green gate — tester mode.` **STOP.** Then propose the next claim.

## What the red gate means here

The red gate changes meaning in this mode: the human is not just
confirming a failure, they are **approving the requirement itself**. You
are proposing what the system should do, so present each new sentence for
product-owner review: "do you actually want this behavior?" Expect
rejections and rewording — that's the mode working. Otherwise the human
drifts into implementing whatever you dreamt up.

## Play to the mode's strength

Probe the edge cases humans skip: empty command strings, invalid inputs,
symmetry checks (four lefts returning to start), interactions between
features already on the board. Markdown tables make it cheap for you to
pile on cases without glue changes — and cheap for the human to delete
rows they consider out of scope. Every probe arrives as a readable
sentence they can veto.

## Hint sources (when the human is stuck red → green)

Same as programmer-mode's implementation hints: draw from the failing
output and the spec text, never a paste-ready diff.

If instead **you** are unsure what to spec next, that's not a hint
situation — that's a roadmap conversation. Take it to the human.
