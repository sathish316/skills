# Typical Superpowers Workflow

Format: Mermaid Markdown. This is preferable to PNG for this workflow because it stays editable, diffs cleanly in git, and renders directly in GitHub-flavored Markdown.

Source: https://github.com/obra/superpowers README, verified 2026-05-08.

```mermaid
flowchart TD
    A[using-superpowers] --> B[brainstorming]
    B --> C[using-git-worktrees]
    C --> D[writing-plans]
    D --> E{subagent-driven-development or executing-plans}
    E --> F[test-driven-development]
    F --> G[requesting-code-review]
    G --> H[receiving-code-review]
    H --> I{more tasks?}
    I -- yes --> E
    I -- no --> J[verification-before-completion]
    J --> K[finishing-a-development-branch]
```
