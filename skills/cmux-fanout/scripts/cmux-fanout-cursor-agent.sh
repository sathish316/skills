#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$script_dir/cmux-fanout-common.sh"

CMUX_FANOUT_AGENT_NAME="cursor-agent"
CMUX_FANOUT_BINARY=${CMUX_FANOUT_BINARY:-cursor-agent}
CMUX_FANOUT_TITLE_PREFIX=cursor

cmux_fanout_skill_instruction() {
  local skill_name=$1
  printf 'Use the %s skill.' "$skill_name"
}

cmux_fanout_agent_command() {
  local starter_prompt=$1
  local cmd="cursor-agent"

  [[ -z "$profile" ]] || die "Cursor Agent wrapper does not support --profile"
  if [[ "$mode" == "daemon" ]]; then
    cmd+=" --print"
  fi
  if [[ -n "$cd_dir" ]]; then
    cmd+=" --workspace $(shell_quote "$cd_dir")"
  fi
  if [[ -n "$model" ]]; then
    cmd+=" --model $(shell_quote "$model")"
  fi
  cmd+=" $(shell_quote "$starter_prompt")"

  printf "%s" "$cmd"
}

cmux_fanout_main "$@"
