#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$script_dir/cmux-fanout-common.sh"

CMUX_FANOUT_AGENT_NAME=rovodev
CMUX_FANOUT_BINARY=${CMUX_FANOUT_BINARY:-rovodev}
CMUX_FANOUT_TITLE_PREFIX=rovodev

cmux_fanout_skill_instruction() {
  local skill_name=$1
  printf 'Use the %s skill.' "$skill_name"
}

cmux_fanout_agent_command() {
  local starter_prompt=$1
  local cmd="rovodev"

  [[ -z "$profile" ]] || die "Rovo Dev wrapper does not support --profile"
  if [[ "$mode" == "daemon" ]]; then
    cmd+=" --print"
  fi
  if [[ -n "$model" ]]; then
    cmd+=" --model $(shell_quote "$model")"
  fi
  cmd+=" $(shell_quote "$starter_prompt")"

  prefix_cd_if_needed "$cmd"
}

cmux_fanout_main "$@"
