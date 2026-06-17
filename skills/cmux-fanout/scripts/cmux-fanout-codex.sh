#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$script_dir/cmux-fanout-common.sh"

CMUX_FANOUT_AGENT_NAME=codex
CMUX_FANOUT_BINARY=${CMUX_FANOUT_BINARY:-codex}
CMUX_FANOUT_TITLE_PREFIX=codex

cmux_fanout_skill_instruction() {
  local skill_name=$1
  printf 'Use $%s.' "$skill_name"
}

cmux_fanout_agent_command() {
  local starter_prompt=$1
  local cmd="codex"

  if [[ "$mode" == "daemon" ]]; then
    cmd+=" exec"
  fi
  if [[ -n "$cd_dir" ]]; then
    cmd+=" --cd $(shell_quote "$cd_dir")"
  fi
  if [[ -n "$model" ]]; then
    cmd+=" --model $(shell_quote "$model")"
  fi
  if [[ -n "$profile" ]]; then
    cmd+=" --profile $(shell_quote "$profile")"
  fi
  cmd+=" $(shell_quote "$starter_prompt")"

  printf "%s" "$cmd"
}

cmux_fanout_main "$@"
