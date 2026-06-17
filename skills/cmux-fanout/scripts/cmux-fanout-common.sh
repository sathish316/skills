#!/usr/bin/env bash

cmux_fanout_usage() {
  cat <<USAGE
Usage:
  ${0##*/} [options] [--] [item ...]

Options:
  --file PATH           Read newline-separated input items from PATH.
  --skill NAME          Prefix each prompt with this agent's skill instruction.
  --prompt TEXT         Prompt template. {{item}} is replaced with each item.
  --mode MODE           interactive, daemon, or exec. Default: ask, then interactive.
  --cd DIR              Working directory passed to the agent when supported.
  --model MODEL         Model passed to the agent when supported.
  --profile PROFILE     Profile passed to the agent when supported.
  --title-prefix TEXT   Prefix for launch log labels. Default: agent name.
  --dry-run             Print commands without launching cmux.
  -h, --help            Show this help.

The current cmux workspace is split into one left panel plus a right-side
vertical stack with one ${CMUX_FANOUT_AGENT_NAME:-agent} pane per input item.
Items can come from --file, stdin, or positional arguments. Blank lines are
ignored.
USAGE
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

shell_quote() {
  local value=${1-}
  printf "'%s'" "$(printf "%s" "$value" | sed "s/'/'\\\\''/g")"
}

extract_ref() {
  local kind=$1
  local text=${2-}
  printf "%s\n" "$text" | grep -Eo "${kind}:[0-9]+" | head -n 1 || true
}

slugify() {
  local value=${1-}
  value=$(printf "%s" "$value" | tr '\n' ' ' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  value=$(printf "%s" "$value" | tr -cs '[:alnum:]._-' '-')
  value=${value#-}
  value=${value%-}
  printf "%.48s" "${value:-item}"
}

prefix_cd_if_needed() {
  local cmd=$1
  if [[ -n "${cd_dir:-}" ]]; then
    printf 'cd %s && %s' "$(shell_quote "$cd_dir")" "$cmd"
  else
    printf '%s' "$cmd"
  fi
}

default_skill_instruction() {
  local skill_name=$1
  printf 'Use the %s skill.' "$skill_name"
}

skill_instruction_for_agent() {
  local skill_name=$1
  if declare -F cmux_fanout_skill_instruction >/dev/null 2>&1; then
    cmux_fanout_skill_instruction "$skill_name"
  else
    default_skill_instruction "$skill_name"
  fi
}

prompt_for_item() {
  local item=$1
  local text=$prompt

  if [[ "$text" == *'{{item}}'* ]]; then
    text=${text//'{{item}}'/$item}
  else
    text="${text}"$'\n\n'"Input item:"$'\n'"${item}"
  fi

  if [[ -n "$skill" ]]; then
    text="$(skill_instruction_for_agent "$skill")"$'\n\n'"${text}"
  fi

  printf "%s" "$text"
}

normalize_mode() {
  case "$1" in
    interactive|i|'')
      printf "interactive"
      ;;
    daemon|d|exec|e|print|p|headless)
      printf "daemon"
      ;;
    *)
      return 1
      ;;
  esac
}

choose_mode() {
  local selected=$mode
  local agent_name=${CMUX_FANOUT_AGENT_NAME:-agent}

  if [[ -z "$selected" ]]; then
    if [[ "$dry_run" -eq 1 ]]; then
      selected=interactive
    elif [[ -r /dev/tty ]]; then
      printf 'Run %s panes in interactive mode or daemon/exec mode? [interactive] ' "$agent_name" > /dev/tty
      IFS= read -r selected < /dev/tty
    else
      selected=interactive
    fi
  fi

  mode=$(normalize_mode "$selected") || die "--mode must be interactive, daemon, or exec"
}

run_command_in_surface() {
  local workspace_ref=$1
  local surface_ref=$2
  local cmd=$3

  if cmux respawn-pane --workspace "$workspace_ref" --surface "$surface_ref" --command "$cmd" >/dev/null 2>&1; then
    return
  fi

  cmux send --workspace "$workspace_ref" --surface "$surface_ref" "$cmd" >/dev/null
  cmux send-key --workspace "$workspace_ref" --surface "$surface_ref" Enter >/dev/null
}

cmux_fanout_parse_args() {
  file=
  skill=
  prompt=
  mode=
  cd_dir=
  model=
  profile=
  title_prefix=${CMUX_FANOUT_TITLE_PREFIX:-${CMUX_FANOUT_AGENT_NAME:-agent}}
  dry_run=0
  items=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --file)
        [[ $# -ge 2 ]] || die "--file requires a path"
        file=$2
        shift 2
        ;;
      --skill)
        [[ $# -ge 2 ]] || die "--skill requires a name"
        skill=$2
        shift 2
        ;;
      --prompt)
        [[ $# -ge 2 ]] || die "--prompt requires text"
        prompt=$2
        shift 2
        ;;
      --mode)
        [[ $# -ge 2 ]] || die "--mode requires a value"
        mode=$2
        shift 2
        ;;
      --cd)
        [[ $# -ge 2 ]] || die "--cd requires a directory"
        cd_dir=$2
        shift 2
        ;;
      --model)
        [[ $# -ge 2 ]] || die "--model requires a model"
        model=$2
        shift 2
        ;;
      --profile)
        [[ $# -ge 2 ]] || die "--profile requires a profile"
        profile=$2
        shift 2
        ;;
      --title-prefix)
        [[ $# -ge 2 ]] || die "--title-prefix requires text"
        title_prefix=$2
        shift 2
        ;;
      --dry-run)
        dry_run=1
        shift
        ;;
      -h|--help)
        cmux_fanout_usage
        exit 0
        ;;
      --)
        shift
        while [[ $# -gt 0 ]]; do
          items+=("$1")
          shift
        done
        ;;
      -*)
        die "unknown option: $1"
        ;;
      *)
        items+=("$1")
        shift
        ;;
    esac
  done

  [[ -n "$prompt" ]] || die "--prompt is required"

  if [[ -n "$file" ]]; then
    [[ -r "$file" ]] || die "input file not readable: $file"
    while IFS= read -r line || [[ -n "$line" ]]; do
      [[ -n "${line//[[:space:]]/}" ]] || continue
      items+=("$line")
    done < "$file"
  fi

  if [[ ${#items[@]} -eq 0 && ! -t 0 ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
      [[ -n "${line//[[:space:]]/}" ]] || continue
      items+=("$line")
    done
  fi

  [[ ${#items[@]} -gt 0 ]] || die "provide at least one item via --file, stdin, or arguments"
  choose_mode
}

cmux_fanout_require_tools() {
  local binary=${CMUX_FANOUT_BINARY:?CMUX_FANOUT_BINARY is required}

  if [[ "$dry_run" -eq 0 ]]; then
    command -v "$binary" >/dev/null 2>&1 || die "$binary not found on PATH"
    command -v cmux >/dev/null 2>&1 || die "cmux not found on PATH"
    cmux ping >/dev/null 2>&1 || die "cmux socket is not available; start cmux first or set CMUX_SOCKET_PATH/CMUX_SOCKET_PASSWORD"
    current_workspace_output=$(cmux current-workspace)
    workspace_ref=$(extract_ref workspace "$current_workspace_output")
    workspace_ref=${workspace_ref:-${CMUX_WORKSPACE_ID:-}}
    [[ -n "$workspace_ref" ]] || die "could not determine current cmux workspace; run from inside cmux or set CMUX_WORKSPACE_ID"
  else
    workspace_ref='<current-workspace>'
  fi
}

cmux_fanout_build_stack() {
  created_surfaces=()
  created_titles=()
  created_commands=()
  split_target_surface=

  local index=0
  local item cmd title surface_ref pane_output pane_ref
  for item in "${items[@]}"; do
    cmd=$(cmux_fanout_agent_command "$(prompt_for_item "$item")")
    title="${title_prefix}: $(slugify "$item")"

    if [[ "$index" -eq 0 ]]; then
      if [[ "$dry_run" -eq 1 ]]; then
        printf 'cmux new-pane --type terminal --direction right --workspace %s\n' "$workspace_ref"
        surface_ref='<right-surface-1>'
      else
        pane_output=$(cmux new-pane --type terminal --direction right --workspace "$workspace_ref")
        surface_ref=$(extract_ref surface "$pane_output")
        pane_ref=$(extract_ref pane "$pane_output")
        if [[ -z "$surface_ref" && -n "$pane_ref" ]]; then
          surface_ref=$(extract_ref surface "$(cmux list-pane-surfaces --workspace "$workspace_ref" --pane "$pane_ref")")
        fi
        [[ -n "$surface_ref" ]] || die "created first right pane for $title, but could not determine its terminal surface"
      fi
    else
      if [[ "$dry_run" -eq 1 ]]; then
        printf 'cmux new-split down --workspace %s --surface %s\n' "$workspace_ref" "$split_target_surface"
        surface_ref="<right-surface-$((index + 1))>"
      else
        pane_output=$(cmux new-split down --workspace "$workspace_ref" --surface "$split_target_surface")
        surface_ref=$(extract_ref surface "$pane_output")
        pane_ref=$(extract_ref pane "$pane_output")
        if [[ -z "$surface_ref" && -n "$pane_ref" ]]; then
          surface_ref=$(extract_ref surface "$(cmux list-pane-surfaces --workspace "$workspace_ref" --pane "$pane_ref")")
        fi
        [[ -n "$surface_ref" ]] || die "created right-stack split for $title, but could not determine its terminal surface"
      fi
    fi

    created_surfaces+=("$surface_ref")
    created_titles+=("$title")
    created_commands+=("$cmd")
    split_target_surface="$surface_ref"
    index=$((index + 1))
  done
}

cmux_fanout_start_agents() {
  local index surface_ref cmd title
  for index in "${!created_surfaces[@]}"; do
    surface_ref=${created_surfaces[$index]}
    cmd=${created_commands[$index]}
    title=${created_titles[$index]}

    if [[ "$dry_run" -eq 1 ]]; then
      printf 'cmux respawn-pane --workspace %s --surface %s --command %s\n' "$workspace_ref" "$surface_ref" "$(shell_quote "$cmd")"
    else
      run_command_in_surface "$workspace_ref" "$surface_ref" "$cmd"
      printf 'launched pane: %s\n' "$title"
    fi
  done
}

cmux_fanout_main() {
  set -euo pipefail
  cmux_fanout_parse_args "$@"
  cmux_fanout_require_tools
  cmux_fanout_build_stack
  cmux_fanout_start_agents
}
