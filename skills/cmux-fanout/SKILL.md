---
name: cmux-fanout
description: Launch parallel agent sessions in the current cmux workspace from a list of input items. Use when the user wants to script cmux, keep the current pane on the left, create a right-side vertical stack with one pane per item, run Codex, Claude Code, Cursor Agent, or Rovo Dev over a list, trigger a custom skill or prompt for each item, or monitor parallel agent runs in cmux. If the user has not clearly specified an agent, ask which agent to use before spawning panes.
---

# Cmux Fanout

Use cmux's socket CLI to split the current workspace into a left working pane plus a right stack of agent panes. The layout is fixed: the current pane stays on the left, the first work item opens to the right, and each remaining item opens as a downward split targeted at the right-side stack.

Ask which agent to use when the user has not clearly said Codex, Claude Code, Cursor Agent, or Rovo Dev. The dispatcher script also prompts for the agent when `--agent` is omitted.

## Quick Start

Codex:

```bash
skills/cmux-fanout/scripts/cmux-fanout-codex.sh \
  --skill code-review \
  --prompt "Review {{item}} and report findings only." \
  --file files.txt
```

Claude Code:

```bash
skills/cmux-fanout/scripts/cmux-fanout-claude.sh \
  --prompt "Review {{item}} and report findings only." \
  --file files.txt
```

Cursor Agent:

```bash
skills/cmux-fanout/scripts/cmux-fanout-cursor-agent.sh \
  --prompt "Review {{item}} and report findings only." \
  --file files.txt
```

Rovo Dev:

```bash
skills/cmux-fanout/scripts/cmux-fanout-rovodev.sh \
  --prompt "Review {{item}} and report findings only." \
  --file files.txt
```

Dispatcher, when the agent is known:

```bash
skills/cmux-fanout/scripts/cmux-fanout.sh \
  --agent codex \
  --prompt "Review {{item}}" \
  --file files.txt
```

If `--agent` is omitted, `cmux-fanout.sh` asks which agent to use.

## Workflow

1. Identify the agent. If the user's request does not clearly name Codex, Claude Code, Cursor Agent, or Rovo Dev, ask before launching.
2. Put one work item per line in a file, pipe newline-separated items on stdin, or pass items as arguments.
3. Write a bounded prompt. Include `{{item}}` where the item should be inserted. If the prompt has no placeholder, the script appends:

```text
Input item:
<item>
```

4. Include `--skill <skill-name>` when each job should explicitly trigger a skill or skill-like behavior. Codex uses `Use $<skill>.`; other agents use `Use the <skill> skill.`
5. Choose a mode:
   - `--mode interactive`: launch the agent with a starter prompt and keep its interactive session open.
   - `--mode daemon` or `--mode exec`: launch the agent's non-interactive print/exec mode when supported.
   - Omit `--mode`: ask before spawning panes on real launches; dry-runs default to interactive.
6. Use `--dry-run` first when the generated commands may be expensive or destructive.
7. Launch from the cmux workspace you want to split.

## Scripts

- `scripts/cmux-fanout.sh`: dispatcher; prompts for an agent when `--agent` is omitted.
- `scripts/cmux-fanout-codex.sh`: Codex wrapper. Interactive uses `codex "<prompt>"`; daemon uses `codex exec "<prompt>"`.
- `scripts/cmux-fanout-claude.sh`: Claude Code wrapper. Interactive uses `claude "<prompt>"`; daemon uses `claude --print "<prompt>"`.
- `scripts/cmux-fanout-cursor-agent.sh`: Cursor Agent wrapper. Interactive uses `cursor-agent "<prompt>"`; daemon uses `cursor-agent --print "<prompt>"`.
- `scripts/cmux-fanout-rovodev.sh`: Rovo Dev wrapper. Interactive uses `rovodev "<prompt>"`; daemon uses `rovodev --print "<prompt>"`. This local environment does not have `rovodev` installed, so verify the command shape on a machine with Rovo Dev before relying on real launches.

All agent scripts support:

- `--file <path>`: read newline-separated items.
- `--skill <name>`: prepend an agent-specific skill instruction.
- `--prompt <text>`: prompt template. `{{item}}` is replaced with each item.
- `--mode <interactive|daemon|exec>`: choose interactive or non-interactive mode.
- `--cd <dir>`: pass a working directory when the agent supports it, or prefix the command with `cd`.
- `--model <model>`: pass a model when the agent supports it.
- `--profile <profile>`: supported only by the Codex wrapper.
- `--title-prefix <text>`: prefix launch log labels.
- `--dry-run`: print cmux commands without launching panes.
- Items after `--` or remaining positional arguments.

The common cmux logic uses `cmux new-pane --direction right` for the first item, then `cmux new-split down --surface <previous-right-surface>` for later items. It creates the full right-side stack before starting agents, then uses `cmux respawn-pane --command <command>` for each created surface.
