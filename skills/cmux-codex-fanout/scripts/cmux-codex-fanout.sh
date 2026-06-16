#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  cmux-codex-fanout.sh [options] [--] [item ...]

Options:
  --file PATH           Read newline-separated input items from PATH.
  --skill NAME          Prefix each prompt with "Use $NAME." to trigger a skill.
  --prompt TEXT         Prompt template. {{item}} is replaced with each item.
  --layout LAYOUT       new-workspaces or right-stack. Default: new-workspaces.
  --cd DIR              Working directory passed to codex exec.
  --model MODEL         Model passed to codex exec.
  --profile PROFILE     Profile passed to codex exec.
  --title-prefix TEXT   Prefix for cmux workspace titles. Default: codex.
  --dry-run             Print commands without launching cmux.
  -h, --help            Show this help.

Items can come from --file, stdin, or positional arguments. Blank lines are ignored.
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

prompt_for_item() {
  local item=$1
  local text=$prompt

  if [[ "$text" == *'{{item}}'* ]]; then
    text=${text//'{{item}}'/$item}
  else
    text="${text}"$'\n\n'"Input item:"$'\n'"${item}"
  fi

  if [[ -n "$skill" ]]; then
    text="Use \$${skill}."$'\n\n'"${text}"
  fi

  printf "%s" "$text"
}

codex_command_for_item() {
  local item=$1
  local item_prompt
  item_prompt=$(prompt_for_item "$item")

  local cmd="codex exec"
  if [[ -n "$cd_dir" ]]; then
    cmd+=" --cd $(shell_quote "$cd_dir")"
  fi
  if [[ -n "$model" ]]; then
    cmd+=" --model $(shell_quote "$model")"
  fi
  if [[ -n "$profile" ]]; then
    cmd+=" --profile $(shell_quote "$profile")"
  fi
  cmd+=" $(shell_quote "$item_prompt")"

  printf "%s" "$cmd"
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

file=
skill=
prompt=
layout=new-workspaces
cd_dir=
model=
profile=
title_prefix=codex
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
    --layout)
      [[ $# -ge 2 ]] || die "--layout requires a value"
      layout=$2
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
      usage
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
case "$layout" in
  new-workspaces|right-stack) ;;
  *) die "--layout must be new-workspaces or right-stack" ;;
esac

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

command -v codex >/dev/null 2>&1 || die "codex not found on PATH"
if [[ "$dry_run" -eq 0 ]]; then
  command -v cmux >/dev/null 2>&1 || die "cmux not found on PATH"
  cmux ping >/dev/null 2>&1 || die "cmux socket is not available; start cmux first or set CMUX_SOCKET_PATH/CMUX_SOCKET_PASSWORD"
fi

if [[ "$layout" == "new-workspaces" ]]; then
  for item in "${items[@]}"; do
    cmd=$(codex_command_for_item "$item")
    title="${title_prefix}: $(slugify "$item")"

    if [[ "$dry_run" -eq 1 ]]; then
      printf 'cmux new-workspace --command %s\n' "$(shell_quote "$cmd")"
      printf 'cmux rename-workspace %s %s\n' "$(shell_quote "$title")" '# targets the new workspace when cmux returns its ref'
    else
      workspace_output=$(cmux new-workspace --command "$cmd")
      workspace_ref=$(extract_ref workspace "$workspace_output")
      if [[ -n "$workspace_ref" ]]; then
        cmux rename-workspace --workspace "$workspace_ref" "$title" >/dev/null 2>&1 || true
      else
        cmux rename-workspace "$title" >/dev/null 2>&1 || true
      fi
      printf 'launched: %s\n' "$title"
    fi
  done
else
  if [[ "$dry_run" -eq 1 ]]; then
    workspace_ref='<current-workspace>'
  else
    current_workspace_output=$(cmux current-workspace)
    workspace_ref=$(extract_ref workspace "$current_workspace_output")
    workspace_ref=${workspace_ref:-${CMUX_WORKSPACE_ID:-}}
    [[ -n "$workspace_ref" ]] || die "could not determine current cmux workspace; run from inside cmux or set CMUX_WORKSPACE_ID"
  fi

  index=0
  for item in "${items[@]}"; do
    cmd=$(codex_command_for_item "$item")
    direction=down
    if [[ "$index" -eq 0 ]]; then
      direction=right
    fi
    title="${title_prefix}: $(slugify "$item")"

    if [[ "$dry_run" -eq 1 ]]; then
      printf 'cmux new-pane --type terminal --direction %s --workspace %s\n' "$direction" "$workspace_ref"
      printf 'cmux respawn-pane --workspace %s --surface <new-surface> --command %s\n' "$workspace_ref" "$(shell_quote "$cmd")"
    else
      pane_output=$(cmux new-pane --type terminal --direction "$direction" --workspace "$workspace_ref")
      surface_ref=$(extract_ref surface "$pane_output")
      pane_ref=$(extract_ref pane "$pane_output")
      if [[ -z "$surface_ref" && -n "$pane_ref" ]]; then
        surface_ref=$(extract_ref surface "$(cmux list-pane-surfaces --workspace "$workspace_ref" --pane "$pane_ref")")
      fi
      [[ -n "$surface_ref" ]] || die "created pane for $title, but could not determine its terminal surface"
      run_command_in_surface "$workspace_ref" "$surface_ref" "$cmd"
      printf 'launched right-stack pane: %s\n' "$title"
    fi

    index=$((index + 1))
  done
fi
