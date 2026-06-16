---
name: cmux-codex-fanout
description: Launch parallel Codex CLI sessions in the current cmux workspace from a list of input items. Use when the user wants to script cmux, keep the current pane on the left, create a right-side vertical stack with one pane per item, run interactive Codex starter prompts by default, optionally run daemon/exec `codex exec` jobs, trigger a custom Codex skill for each item, or monitor parallel agent runs in cmux.
---

# Cmux Codex Fanout

Use cmux's socket CLI to split the current workspace into a left working pane plus a right stack of Codex panes. This is the only supported layout: the current pane stays on the left, the first work item opens to the right, and each remaining item opens as a downward split in that right-side stack.

Interactive Codex mode is the default. When `--mode` is omitted on a real launch, the script asks whether to run panes in interactive mode or daemon/exec mode before spawning panes. Use `--mode interactive` or `--mode daemon` to skip the prompt.

## Quick Start

Run the script from this skill:

```bash
skills/cmux-codex-fanout/scripts/cmux-codex-fanout.sh \
  --skill code-review \
  --prompt "Review {{item}} and report findings only." \
  --file files.txt
```

Run non-interactive daemon/exec jobs instead:

```bash
skills/cmux-codex-fanout/scripts/cmux-codex-fanout.sh \
  --mode daemon \
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
5. Choose a mode:
   - `--mode interactive`: launch `codex "<starter prompt>"` and keep the interactive Codex session open.
   - `--mode daemon` or `--mode exec`: launch `codex exec "<prompt>"` and exit after the job completes.
   - Omit `--mode`: ask before spawning panes on real launches; dry-runs default to interactive.
6. Use `--dry-run` first when the generated commands may be expensive or destructive.
7. Launch from the cmux workspace you want to split. The script keeps that current pane on the left, creates the first Codex pane to the right, then targets the newly created right-side surface for every downward split so all item panes stay in the right column.

## Script

`scripts/cmux-codex-fanout.sh` supports:

- `--file <path>`: read newline-separated items.
- `--skill <name>`: prepend `Use $<name>.` to every prompt.
- `--prompt <text>`: prompt template. `{{item}}` is replaced with each item.
- `--mode <interactive|daemon|exec>`: choose interactive Codex TUI or non-interactive `codex exec`.
- `--cd <dir>`: pass `--cd <dir>` to `codex`.
- `--model <model>` and `--profile <profile>`: pass through to `codex`.
- `--title-prefix <text>`: cmux workspace title prefix.
- `--dry-run`: print commands instead of launching cmux workspaces.
- Items after `--` or remaining positional arguments.

The script uses `cmux new-pane --direction right` for the first item, then `cmux new-split down --surface <previous-right-surface>` for later items. It creates the full right-side stack before starting Codex, then uses `cmux respawn-pane --command <command>` for each created surface. It does not wait for completion.
