#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <src-source> <src-command-name> <dest-command-name>"
  exit 2
fi

src_source="$1"
src_command_name="$2"
dest_command_name="$3"
repo_root="$(cd "$(dirname "$0")" && pwd)"

resolve_source_dir() {
  case "$1" in
    addyosmani-skills)
      echo "$repo_root/resources/addyosmani-skills/.claude/commands"
      ;;
    local-commands|commands)
      echo "$repo_root/commands"
      ;;
    *)
      if [ -d "$1" ]; then
        echo "$1"
      elif [ -d "$repo_root/$1" ]; then
        echo "$repo_root/$1"
      elif [ -d "$repo_root/resources/$1/.claude/commands" ]; then
        echo "$repo_root/resources/$1/.claude/commands"
      else
        return 1
      fi
      ;;
  esac
}

if ! src_dir="$(resolve_source_dir "$src_source")"; then
  echo "Unknown source '$src_source'."
  echo "Known sources: addyosmani-skills, commands"
  exit 2
fi

src_file="${src_dir}/${src_command_name}.md"
dest_file="${repo_root}/commands/${dest_command_name}.md"

if [ ! -f "$src_file" ]; then
  echo "Source file not found: $src_file"
  exit 2
fi

if [ ! -f "$dest_file" ]; then
  echo "Destination file not found: $dest_file"
  exit 2
fi

echo "Comparing:"
echo "  $src_file"
echo "  $dest_file"
echo

set +e
git --no-pager diff --no-index --color=always "$src_file" "$dest_file"
diff_exit_code=$?
set -e

if [ "$diff_exit_code" -eq 0 ]; then
  echo "No differences found."
elif [ "$diff_exit_code" -eq 1 ]; then
  echo "Differences found."
  exit 1
else
  echo "Diff command failed."
  exit "$diff_exit_code"
fi
