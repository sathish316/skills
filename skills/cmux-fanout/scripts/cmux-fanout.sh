#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

usage() {
  cat <<'USAGE'
Usage:
  cmux-fanout.sh --agent AGENT [agent-options] [--] [item ...]

Agents:
  codex
  claude | claude-code
  cursor | cursor-agent
  rovo | rovodev

If --agent is omitted and a TTY is available, the script asks which agent to use.
Agent-specific options are passed through to the selected script.
USAGE
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

normalize_agent() {
  case "$1" in
    codex)
      printf "codex"
      ;;
    claude|claude-code)
      printf "claude"
      ;;
    cursor|cursor-agent)
      printf "cursor-agent"
      ;;
    rovo|rovodev)
      printf "rovodev"
      ;;
    *)
      return 1
      ;;
  esac
}

agent=
args=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --agent)
      [[ $# -ge 2 ]] || die "--agent requires a value"
      agent=$2
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      args+=("$1")
      shift
      ;;
  esac
done

if [[ -z "$agent" ]]; then
  if [[ -r /dev/tty ]]; then
    printf 'Which agent should cmux fan out? [codex/claude/cursor-agent/rovodev] ' > /dev/tty
    IFS= read -r agent < /dev/tty
  else
    die "agent not specified; pass --agent codex, claude, cursor-agent, or rovodev"
  fi
fi

raw_agent=$agent
agent=$(normalize_agent "$raw_agent") || die "unknown agent: $raw_agent"

case "$agent" in
  codex)
    exec "$script_dir/cmux-fanout-codex.sh" "${args[@]}"
    ;;
  claude)
    exec "$script_dir/cmux-fanout-claude.sh" "${args[@]}"
    ;;
  cursor-agent)
    exec "$script_dir/cmux-fanout-cursor-agent.sh" "${args[@]}"
    ;;
  rovodev)
    exec "$script_dir/cmux-fanout-rovodev.sh" "${args[@]}"
    ;;
esac
