# Dual Mode

**Loop scope: outer only.**

You write everything; the human mans the gates. Instead of two gates there
are **three**, each reviewing a different artifact:

| Gate | You produce | Human reviews |
|------|-------------|---------------|
| 1. **Spec gate** | Oath prose | Requirements: *is this the behavior I want?* |
| 2. **Design gate** | Step bindings with **wishful interfaces** + skeletal stubs; shown red | Design: *are these the right names, shapes, responsibilities?* — then confirms red |
| 3. **Green gate** | Production implementation; shown green | Code: *minimal, clean, passes?* |

## Wishful interfaces at the design gate

Write glue that calls the API you **wish existed** ("programming by
wishful thinking", per SICP/GOOS). Glue is the only place code touches the
domain, so the step bindings become a compact design proposal —
`rover.execute(commands)`, `rover.report()` — that the human can veto
before a line of it exists. That's the cheapest possible moment to change
a design.

**What counts as red here:** pure wishful code doesn't compile, and a
compile error is a weak red. You **may create skeletal stubs** — empty
records/classes, methods returning trivial defaults — just enough to
compile and fail *behaviorally*, so the "fails for the right reason" check
works. **Real logic remains forbidden until phase 3.** State this line
explicitly at the gate; it blurs otherwise.

## The loop

1. **Clarify before spec.** Surface genuine design decisions and get
   rulings first — the spec gate reviews a resolved design, not a guess.
2. Draft the oath prose only.
   `🔴 Spec gate — dual mode, phase 1 of 3: prose only, no code.` **STOP.**
3. On approval: write step bindings with wishful interfaces + stubs; run
   the suite; show the behavioral red and the phase-scoped diff.
   `🔴 Design gate — dual mode, phase 2 of 3: stubs only, no logic yet.`
   **STOP.**
4. On approval: implement the minimum; run; show green and the diff.
   `🟢 Green gate — dual mode, phase 3 of 3.` **STOP.**
5. Refactor on green if warranted; then next behavior.

## Mode-specific risks

- **No path-based enforcement is possible.** You legitimately write
  everywhere, so the gates are purely procedural. Restating the active
  phase at every stop is essential, and each gate must show a **diff
  scoped to its phase** so the human can verify nothing leaked ahead
  (logic hiding in a "stub", next feature hiding in this one's diff).
- **Rubber-stamp drift.** When you author everything, three quick
  "approve"s in a row is seductive. Present a genuine question or
  alternative at the spec gate ("wrap at edges, or refuse to move? I
  propose refuse because…") so the review has something to *decide*, not
  just bless.

## Reviewer heuristics to offer the human

- **Fence-post check (spec gate):** verify boundary claims and the
  context's stated dimensions agree — "a plateau of size 5 5" with a
  claim treating 5 as a valid coordinate is a 6×6 grid in disguise.
  Off-by-ones hide in the gap between prose and examples, and prose
  review is the cheapest this bug will ever be.
- **API smell check (design gate):** would you want to call these methods
  from real code? Hard-to-bind glue means a hard-to-use API.

## Hints

The human only gates here, so the ladder barely applies. The one variant:
when they say "I don't know whether to approve," argue **both sides of
your own proposal** rather than defending it.
