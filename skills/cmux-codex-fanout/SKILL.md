---
name: cmux-codex-fanout
description: Launch parallel Codex CLI jobs in cmux tabs/workspaces from a list of input items. Use when the user wants to script cmux, fan out work across multiple visible terminal tabs, run `codex exec` once per item, trigger a custom Codex skill for each item, or monitor parallel agent runs in cmux.
---

# Cmux Codex Fanout

Use cmux's socket CLI to either create one workspace per input item or split the current workspace into a left working pane plus a right stack of Codex panes. Prefer the bundled script for repeatability.

## Quick Start

Run the script from this skill:

```bash
skills/cmux-codex-fanout/scripts/cmux-codex-fanout.sh \
  --skill code-review \
  --prompt "Review {{item}} and report findings only." \
  --file files.txt
```

To keep the current workspace on the left and run every item in a right-side vertical stack:

```bash
skills/cmux-codex-fanout/scripts/cmux-codex-fanout.sh \
  --layout right-stack \
  --skill code-review \
  --prompt "Review {{item}} and report findings only." \
  --file files.txt
```

Pass items directly when that is more convenient:

```bash
skills/cmux-codex-fanout/scripts/cmux-codex-fanout.sh \
  --skill pr-reviewer \
  --prompt "Review PR {{item}} using the PR reviewer skill." \
  PROJ/repo#123 PROJ/repo#124
```

## Workflow

1. Confirm `cmux` and `codex` are available with `command -v cmux` and `command -v codex`.
2. Put one work item per line in a file, pipe newline-separated items on stdin, or pass items as arguments.
3. Write a bounded prompt. Include `{{item}}` where the item should be inserted. If the prompt has no placeholder, the script appends:

```text
Input item:
<item>
```

4. Include `--skill <skill-name>` when each job should explicitly trigger a skill.
5. Use `--dry-run` first when the generated commands may be expensive or destructive.
6. Choose the layout:
   - `--layout new-workspaces`: create one cmux workspace per item.
   - `--layout right-stack`: keep the current pane on the left, create the first Codex pane to the right, then split downward for the remaining items.
7. Launch and monitor the created cmux workspaces or panes.

## Script

`scripts/cmux-codex-fanout.sh` supports:

- `--file <path>`: read newline-separated items.
- `--skill <name>`: prepend `Use $<name>.` to every prompt.
- `--prompt <text>`: prompt template. `{{item}}` is replaced with each item.
- `--layout <new-workspaces|right-stack>`: choose between separate workspaces and a right-side pane stack.
- `--cd <dir>`: pass `--cd <dir>` to `codex exec`.
- `--model <model>` and `--profile <profile>`: pass through to `codex exec`.
- `--title-prefix <text>`: cmux workspace title prefix.
- `--dry-run`: print commands instead of launching cmux workspaces.
- Items after `--` or remaining positional arguments.

`new-workspaces` uses `cmux new-workspace --command <command>`, which creates parallel visible terminal workspaces. `right-stack` uses `cmux new-pane --direction right` for the first item, `cmux new-pane --direction down` for later items, and `cmux respawn-pane --command <command>` to start each `codex exec` process. The script does not wait for completion.
