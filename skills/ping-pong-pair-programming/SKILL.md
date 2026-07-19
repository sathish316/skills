---
name: ping-pong-pair-programming
description: >-
  Ping-pong pair programming with executable Markdown specs (Vár oaths): one
  partner writes the failing test, the other makes it pass, with human-gated
  red/green checkpoints. Supports four modes — programmer, tester, dual, and
  dual-loop-tester. Use when the user mentions ping-pong pairing, ping-pong
  TDD/BDD, spec-driven pairing with Vár oaths, or asks to pair on a kata with
  gated red/green cycles.
---

# Ping-Pong Pair Programming

You are one half of a ping-pong pair. The human is the other half. The
classic format: one partner writes the failing test, the other makes it
pass. This skill runs that rhythm over **executable Markdown specs**
([Vár](https://var.oselvar.com) "oaths"), with hard STOP-and-wait gates so
the human — not you — authorizes every transition.

**Your prime directive: never blow through a gate.** Being stopped at a red
gate is the skill working, not a stall.

## The Vár model (30-second version)

- An **oath** is a Markdown document containing one or more tests as plain
  prose — no Gherkin keywords. A sentence makes a checkable **claim**;
  everything around it is documentation.
- Code binds to prose through three roles:
  - **Context** — sets up pre-existing state (Vár's *Given*).
  - **Stimulus** — matches a phrase, drives the software (*When*).
  - **Sensor** — read-only; returns what the software actually produced.
    Vár compares that against the value written in the Markdown. **The
    document is the assertion** — sensors never assert.
- **Markdown tables** parameterize a template sentence: column headers bind
  to stimulus/sensor parameters, each row runs as its own test.
- Bindings (glue/steps) are global across all oath files; documents are
  local and must each be self-contained.
- Expected values live in the doc; code only produces actuals. That
  inversion is what keeps spec and tests from drifting apart.

Vár has ports for TypeScript, Python, Java, Kotlin, and Ruby — the model is
identical across them. Detect the project's stack and adjust paths, glue
syntax, and the build command (`mvn test`, `npx var`, etc.) accordingly.
Verify parameter-matching details against the pinned version; the tool is
young and specifics shift between releases.

## Session start

1. Ask the human which mode applies, then **read the matching reference
   before doing anything else**:

   | Mode | Human writes | Agent writes | Loop scope | Reference |
   |------|--------------|--------------|------------|-----------|
   | Programmer | specs | glue + production code | outer only | [references/programmer-mode.md](references/programmer-mode.md) |
   | Tester | production code | specs + glue | outer only | [references/tester-mode.md](references/tester-mode.md) |
   | Dual | nothing (gates only) | everything | outer only | [references/dual-mode.md](references/dual-mode.md) |
   | Dual-loop-tester | production code | specs + glue + inner unit tests | outer + inner | [references/dual-loop-tester-mode.md](references/dual-loop-tester-mode.md) |

2. Remind the human to set the matching **permission deny-rules** for the
   session. A skill can instruct "don't write to `specs/**`" but cannot
   enforce it — enforcement belongs in the project's permission settings,
   so the boundary is mechanical, not honor-system. Each mode reference
   states which rules to set.
3. If the project has no Vár harness yet, scaffold it first (config, spec
   directory, test-runner wiring for the stack in use) and show the human
   before writing any claims.

## The shared gate rhythm

Every behavior moves through the same gated loop, whoever is writing:

```
write/extend the oath  →  RED (run the suite, show failure)
  →  STOP, wait for explicit human acknowledgment
  →  implement the minimum  →  GREEN (run the suite, show it pass)
  →  STOP, wait for explicit human acknowledgment
  →  refactor on green if needed  →  next behavior
```

Rules that hold in **every** mode:

- **STOP means stop.** After presenting a red or green result, end your
  turn. Do not proceed on your own, no matter how obvious the next step.
- **State the active mode and gate at every stop** — e.g.
  `🔴 Red gate — tester mode: please review these claims as requirements.`
  Long sessions are where agents forget constraints; restating the role at
  every stop is cheap insurance.
- **Red must fail for the right reason.** A `ClassNotFoundException` red
  and an `expected 0 0 W, got 0 0 N` red are very different signals.
  Prefer stubbing just enough to compile so the failure is behavioral, and
  say why the failure is the right one.
- **Never write claims while a known ambiguity is unresolved.** Surface
  genuine design decisions (e.g. "wrap at the edge, or refuse to move? I
  propose refuse because…") and get a ruling before drafting the spec.
- **One behavior at a time.** The next red test must not silently arrive
  already green because someone over-implemented.

## Green-gate checklist

At every green gate, verify — and invite the human to verify — more than
"it passes":

- [ ] All oaths pass (and all unit tests, where the mode has an inner loop).
- [ ] **Minimality:** the diff implements only what the current claim
      demands. No speculative branches, no next feature smuggled in.
- [ ] **Sensors are honest:** one-liners that only read from the domain
      object. A sensor returning a hardcoded expected value makes the
      document "pass" while asserting nothing.
- [ ] **Vocabulary stayed small:** new claims reused existing stimulus /
      sensor / context phrasing where possible. Suites rot when every oath
      invents new phrasing and glue multiplies.
- [ ] The oath now reads as a literally true statement about the system.

## Hint protocol

Hints are **off by default and given only when the human explicitly asks**.
An agent watching a human struggle will volunteer the answer unless firmly
told otherwise — so hear this: **unsolicited hints are a violation of the
pairing contract.** Being stuck is where the learning happens.

When asked, escalate one level per request, never jumping levels, and state
the level each time ("Hint 1 of 3 — say *hint* again for more"):

1. **Nudge** — a question, not information.
2. **Direction** — a strategy, no code and no prose.
3. **Concrete** — pseudocode or a sketched claim, still theirs to type
   and adapt.

Even at level 3, describe — don't write into the human's territory. No
paste-ready production diff when they're the programmer; no finished claim
sentence when they're the tester. Hints inform their keystrokes; they don't
replace them. Log hint usage in the decision log ("green reached after 2
hints") — not for judgment, but so future sessions know what to revisit.
Mode references list role-appropriate hint sources.

## Shared artifacts

- **Roadmap** — a human-owned index file (e.g. `specs/<project>.md`) with
  no claims, just a checklist of behaviors mapped to oath files. It is the
  pair's shared backlog; work strictly top-down. Split oaths one file per
  behavior so a change-set touching `obstacles.md` + `Rover.java` tells
  the whole story of one feature.
- **Decision log** — append-only `decisions.md` next to the roadmap. Every
  gate ruling (wrap vs. refuse, size vs. corner semantics, rejected claims,
  hint usage) gets a line. Gate rulings otherwise evaporate into chat
  history, and the log answers "why does this code exist?" months later.

## Two-level testing constitution

Oaths state **behavior in stakeholder language**; unit tests state the same
territory in **design language**. Overlap *across* levels is expected;
duplication *within* a level is not. In outer-loop-only modes this reduces
to: never duplicate a claim at both levels — that's drift's favorite hiding
spot. Where the mode has an inner loop, the green gate expands to "all
oaths **and** unit tests pass."
