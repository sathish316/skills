---
name: brainstorm-feature
description: Brainstorm and define a medium or small software feature before implementation. Use when the user wants to explore an idea, design a feature, clarify requirements, turn a vague feature request into a concrete markdown feature definition, or start the medium/small feature workflow before RFCs, issues, tasks, or code.
---

# Brainstorm Feature

Turn a rough feature idea into a clearly defined, implementation-ready feature definition markdown file.

Use this skill before creating RFCs, issues, tasks, or code for medium and small features. The goal is not to over-specify like a full PRD; the goal is to remove ambiguity, choose a practical approach, and leave behind a durable feature definition that downstream planning skills can consume.

## Output Location

Save the final feature definition to:

`docs/features/YYYY-MM-DD-<feature-slug>.md`

This is the default because feature definitions are project artifacts that should live with the project documentation. Do not store new feature definitions inside skill folders or reference-material folders unless the user explicitly asks.

If the user gives a different path, use their path. If `docs/features/` does not exist, create it.

## Hard Gate

<HARD-GATE>
Do NOT invoke any implementation skill, write any code, scaffold any project, or take any implementation action until you have presented a design and the user has approved it. This applies to EVERY project regardless of perceived simplicity.
</HARD-GATE>

After design approval, produce an approved feature definition markdown file before transitioning to downstream planning. Move to the next planning step only if the user asks or approves.

## Process

### 1. Understand the Starting Point

Capture the user's initial idea in your own words. Identify whether the request is truly a medium/small feature or whether it is large enough to need a PRD instead.

Use these boundaries:

- **Small feature**: one narrow behavior change or one focused UI/backend capability
- **Medium feature**: several related changes that still fit in one coherent feature definition
- **Large feature**: multiple independent subsystems, broad product strategy, or enough ambiguity that a PRD is more appropriate

If the request is too large, recommend using the PRD workflow instead of forcing it into this skill.

### 2. Explore Project Context

Before asking detailed design questions, inspect the repository enough to understand:

- Relevant modules, routes, commands, or UI areas
- Existing patterns and naming conventions
- Prior docs that might constrain the feature
- Likely integration points and risks

Keep exploration focused. Do not turn this into implementation analysis.

### 3. Interview the User

Ask one question at a time until the feature is unambiguous enough to define. Prefer concise multiple-choice questions when they reduce back-and-forth, but use open-ended questions for product intent.

Cover the areas that matter for this feature:

- Problem and target user
- Desired user-visible behavior
- Non-goals and explicit out-of-scope items
- Success criteria
- Edge cases and failure behavior
- Data, API, UI, or permission constraints
- Compatibility with existing behavior
- Any decisions that would be expensive to reverse

Do not accept vague answers where ambiguity would affect implementation. Ask a sharper follow-up.

### 4. Offer Approaches

Once the problem is clear, propose 2-3 viable approaches with trade-offs. Lead with the recommended approach and explain why it fits the current codebase and scope.

For each approach, include:

- What changes from the user's perspective
- Main implementation shape at a high level
- Trade-offs, risks, or limitations
- Why you recommend or reject it

Ask the user to choose or revise the approach before writing the final feature definition.

### 5. Draft and Validate the Feature Definition

After the user approves an approach, write the feature definition using the template below. Scale detail to the feature size: concise for small features, more explicit for medium features.

<feature-definition-template>
# Feature: <feature name>

## Summary

A short description of the feature and the user-visible outcome.

## Problem

What is currently missing, confusing, slow, risky, or manual? Describe the gap from the user's perspective.

## Goals

- <Specific outcome this feature must deliver>
- <Another concrete outcome>

## Non-Goals

- <Explicitly excluded behavior, integration, or future enhancement>

## Users and Use Cases

- **<Actor>**: <what they need to do and why>

## Expected Behavior

Describe the expected behavior in practical terms. Include the happy path and important alternate paths.

## Approach

Explain the selected approach and why it was chosen over the alternatives. Keep this at design level; do not include code snippets.

## Scope

### In Scope

- <Included change>

### Out of Scope

- <Excluded change>

## Requirements

- <Functional requirement>
- <Data/API/UI/permission requirement if applicable>
- <Compatibility requirement if applicable>

## Constraints

Explicit constraints on the feature, such as technical limitations, data requirements, or user experience constraints

## Validation

How will you know if the feature is working as expected?

## Expected Outputs

Describe the expected outputs of the feature in terms of artifacts, capability, API, data, UI changes.

## Edge Cases and Failure Behavior

- <Condition>: <expected behavior>

## Acceptance Criteria

- [ ] Given <context>, when <action>, then <observable result>
- [ ] Given <edge or failure condition>, then <expected result>

## Implementation Notes

High-level notes for future planning: likely modules, patterns to follow, migration concerns, test areas, or dependencies. Avoid brittle low-level instructions unless the user specifically requested them.

## Open Questions

- <Question, owner, and proposed resolution path>
</feature-definition-template>

If there are no open questions, write `None`.

Present the draft to the user before saving it. Ask whether the scope, behavior, and acceptance criteria look right. Revise until the user approves the feature definition. Not all sections are required for every feature - Use your best judgement to decide the sections required based on the size and complexity of the feature.

### 6. Save and Self-Review the File

After approval, save the feature definition markdown file to the selected path.

Before presenting the result, review the written markdown and fix issues inline:

- Remove placeholders, TODOs, and unresolved template text
- Check that goals, requirements, and acceptance criteria agree
- Verify that out-of-scope items do not contradict requirements
- Make ambiguous behavior explicit
- Confirm that the scope is still appropriate for one medium/small feature

### 7. Present and Hand Off

Tell the user where the feature definition was saved and summarize the key decisions. Ask them to review the file before moving to RFCs, issues, tasks, or implementation.

If the user approves and wants to continue, suggest the next appropriate workflow:

- `feature-to-rfc` when technical design is needed before work breakdown
- `feature-to-issues` when the feature is clear enough to split into implementation issues
- `issue-to-tasks` when a specific issue is ready for AI-executable tasks

## Principles

- Keep the feature definition concrete enough that another agent can plan from it without re-interviewing the user.
- Avoid premature implementation detail; capture decisions and constraints, not code.
- Prefer narrow, verifiable scope over ambitious bundled changes.
- Follow existing project patterns discovered during exploration.
- Make non-goals explicit so downstream planning does not expand scope accidentally.
