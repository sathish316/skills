# Programmer Mode

**Loop scope: outer only.**

The human drives the specs; you make their document true.

| Artifact | Owner |
|----------|-------|
| Oath prose (`specs/**`) | **Human** — 100% human-authored requirements |
| Step bindings (glue) | Agent |
| Production code | Agent |

## Permission setup

Ask the human to **deny you write access to `specs/**`** in the project's
permission settings. This closes the classic failure mode: an agent that
can't make a test pass will eventually try to "fix" the test. Here, it
physically can't. If the spec's wording needs normalizing (inconsistent
phrasing would force duplicate glue), ask the human to change it — through
conversation, never by editing the file yourself.

## The loop

1. Human writes or extends an oath in `specs/` and hands it to you.
2. You add only the step bindings needed to bind the new phrases — no
   production code yet. Stub just enough to compile so the red is
   behavioral, not a build error.
3. Run the suite. Present the failure and why it fails for the right
   reason. `🔴 Red gate — programmer mode.` **STOP.** Wait for the human
   to confirm the red.
4. Implement the **minimum** production code to pass. Run the suite.
   Present the passing output and the diff.
   `🟢 Green gate — programmer mode.` **STOP.** Wait for acknowledgment —
   the human is checking the diff is minimal, not just that it passes.
5. Refactor on green if warranted (show still-green), then wait for the
   next claim.

## What each gate means here

- **Red gate:** the human confirms the failure matches their intent — the
  claim isn't already satisfied and fails for the right reason.
- **Green gate:** the human reviews for **over-implementation**. Agents
  love to "helpfully" build the next behavior while making this one pass —
  which destroys the feedback loop, because the next red arrives already
  green. Expect that review; make the diff easy to audit.

## Mode-specific pitfalls

- **Hardcoded sensors.** Glue is your soft spot: a sensor returning a
  hardcoded expected value passes vacuously. Sensors are one-line reads of
  the domain object, nothing more.
- **Vocabulary drift.** You bind to the human's exact sentences. If their
  phrasing diverges across oaths ("lands at" vs. "is dropped at"), raise
  it rather than silently multiplying glue.

## Hint sources (when the human is stuck red → green)

The human implements here, so hints draw from the failing output and the
spec:

- "Read the expected value again — what's the delta from the actual?"
- "What does the failing sensor currently know about <missing concept>?"
- "Which claim went red first when you ran the whole suite?"

Follow the shared hint ladder; never paste a ready-made production diff.
