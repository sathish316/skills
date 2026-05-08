# Devskills Decision Tree Flowchart

Format: Mermaid Markdown. This keeps the decision tree editable in the repo and renderable in GitHub/Cursor Markdown preview.

Source: user-provided devskills usage workflow, recorded 2026-05-08.

```mermaid
flowchart TD
    A{feature size?}

    A -- large --> L1[write-prd]
    L1 --> L2["prd-to-rfc*"]
    L2 --> L3[prd-to-issues]
    L3 --> L4["issue-to-tasks*"]
    L4 --> L5{implementation path}
    L5 --> L6[implement-in-feature-branch]
    L5 --> L7[implement-in-worktree]
    L5 --> L8[implement-tasks-using-subagents]
    L6 --> L9[code-simplify]
    L7 --> L9
    L8 --> L9
    L9 --> L10[code-review]
    L10 --> L11["finish-work-in-branch-and-create-pr*"]
    L10 --> L12["finish-work-in-worktree-and-create-pr*"]
    L11 --> L13[final-review-and-create-pr]
    L12 --> L13
    L13 --> L14["apply-pr-comments*"]
    L14 --> Z([done])

    A -- medium/small --> M1[brainstorm-feature]
    M1 --> M2["feature-to-rfc*"]
    M2 --> M3[feature-to-issues]
    M3 --> M4["issue-to-tasks*"]
    M4 --> M5{implementation path}
    M5 --> M6[implement-in-feature-branch]
    M5 --> M7[implement-in-worktree]
    M5 --> M8[implement-tasks-using-subagents]
    M6 --> M9[code-simplify]
    M7 --> M9
    M8 --> M9
    M9 --> M10[code-review]
    M10 --> M11["finish-work-in-branch-and-create-pr*"]
    M10 --> M12["finish-work-in-worktree-and-create-pr*"]
    M12 --> M13["apply-pr-comments*"]
    M13 --> Z

    A -- one-shot code --> S1[code with agent]
    S1 --> S2[code-simplify]
    S2 --> S3[code-review]
    S3 --> S4[create-pr]
    S4 --> Z
```
