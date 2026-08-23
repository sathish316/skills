#!/usr/bin/env bash
# jj-trunk.sh — small helpers for Jujutsu (jj) trunk-based development.
#
# For simple/solo projects where you mostly push straight to `main` and only
# occasionally open a PR for review. Thin wrappers over the jj commands; nothing
# here advances `main` without you asking it to.
set -euo pipefail

script_name=$(basename "$0")
TRUNK="main"
REMOTE="origin"

usage() {
  cat <<USAGE
Usage:
  ${script_name} <command> [args]

Commands:
  sync                       Fetch and rebase current work onto the trunk.
                               jj git fetch && jj rebase -d ${REMOTE}/${TRUNK}
  push-main [-m "message"]    Push the current change directly to ${TRUNK}.
                               Optionally set the commit message first, then
                               advance the ${TRUNK} bookmark to @ and push.
  feature <name>             Start a review branch: new change on ${TRUNK},
                               create bookmark <name>, push it for a PR.
  graph                      Show the commit graph (jj log --graph -r 'all()').
  cleanup <name>             Delete a merged feature bookmark.

Environment:
  TRUNK   trunk bookmark/branch name (default: ${TRUNK})
  REMOTE  git remote name (default: ${REMOTE})

Requires: jj. (Older jj used --branch where current jj uses --bookmark.)
USAGE
}

die() { printf 'error: %s\n' "$*" >&2; exit 1; }
log() { printf '[jj-trunk] %s\n' "$*"; }

command -v jj >/dev/null 2>&1 || die "jj not found on PATH"

cmd="${1:-}"
[ -n "${cmd}" ] || { usage; exit 2; }
shift || true

case "${cmd}" in
  sync)
    log "fetching and rebasing onto ${REMOTE}/${TRUNK}"
    jj git fetch --remote "${REMOTE}"
    jj rebase -d "${REMOTE}/${TRUNK}"
    ;;

  push-main)
    message=""
    while [ "$#" -gt 0 ]; do
      case "$1" in
        -m|--message) message="${2:?-m needs a value}"; shift 2;;
        *) die "unknown argument: $1";;
      esac
    done
    if [ -n "${message}" ]; then
      log "describing current change"
      jj describe -m "${message}"
    fi
    log "advancing ${TRUNK} to the current change and pushing"
    jj bookmark set "${TRUNK}" -r @
    jj git push --bookmark "${TRUNK}" --remote "${REMOTE}"
    ;;

  feature)
    name="${1:?usage: ${script_name} feature <name>}"
    log "starting feature '${name}' on ${TRUNK}"
    jj new "${TRUNK}"
    jj bookmark create "${name}"
    jj git push --bookmark "${name}" --remote "${REMOTE}"
    log "open a PR for '${name}' on GitHub when ready"
    ;;

  graph)
    jj log --graph -r 'all()'
    ;;

  cleanup)
    name="${1:?usage: ${script_name} cleanup <name>}"
    log "deleting bookmark '${name}'"
    jj bookmark delete "${name}"
    ;;

  -h|--help|help)
    usage
    ;;

  *)
    die "unknown command: ${cmd} (see --help)"
    ;;
esac
