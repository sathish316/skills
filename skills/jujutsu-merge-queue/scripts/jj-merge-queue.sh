#!/usr/bin/env bash
# jj-merge-queue.sh — a Jujutsu (jj) based merge-queue worker.
#
# Serializes integration of approved GitHub PRs: fetch, stack each eligible PR
# onto the latest trunk in order, optionally run a CI command against the stacked
# result, drop any PR that conflicts or fails, and only advance `main` (via the
# bookmark) when the whole surviving stack is green.
#
# Designed to run inside a dedicated jj workspace/clone that no human edits.
set -euo pipefail

script_name=$(basename "$0")

BASE="main"
CI_CMD=""
REQUIRE_CI_STATUS=0
DRY_RUN=0
SEARCH="review:approved"
REMOTE="origin"

usage() {
  cat <<USAGE
Usage:
  ${script_name} [options]

Runs one pass of a jj-based merge queue: stacks eligible approved PRs onto the
trunk bookmark, tests each, and pushes the trunk only if the stack is green.

Options:
  --base BOOKMARK        Trunk bookmark to advance (default: ${BASE})
  --remote NAME          Git remote name as known to jj (default: ${REMOTE})
  --search QUERY         Extra gh PR search filter (default: "${SEARCH}")
  --ci-cmd "CMD"         Command to run as the CI gate against each stacked PR.
                         Non-zero exit drops that PR from this cycle.
  --require-ci-status    Only consider PRs whose GitHub status checks are all
                         passing (or have no checks) via statusCheckRollup.
  --dry-run              Do everything except pushing the trunk bookmark.
  -h, --help             Show this help.

Requires: jj, gh (authenticated), jq.
USAGE
}

die() { printf 'error: %s\n' "$*" >&2; exit 1; }
log() { printf '[merge-queue] %s\n' "$*"; }

while [ "$#" -gt 0 ]; do
  case "$1" in
    --base) BASE="${2:?--base needs a value}"; shift 2;;
    --remote) REMOTE="${2:?--remote needs a value}"; shift 2;;
    --search) SEARCH="${2:?--search needs a value}"; shift 2;;
    --ci-cmd) CI_CMD="${2:?--ci-cmd needs a value}"; shift 2;;
    --require-ci-status) REQUIRE_CI_STATUS=1; shift;;
    --dry-run) DRY_RUN=1; shift;;
    -h|--help) usage; exit 0;;
    *) die "unknown argument: $1 (see --help)";;
  esac
done

command -v jj >/dev/null 2>&1 || die "jj not found on PATH"
command -v gh >/dev/null 2>&1 || die "gh not found on PATH"
command -v jq >/dev/null 2>&1 || die "jq not found on PATH"

# Build the jq selector. When --require-ci-status is set, keep only PRs whose
# checks are all SUCCESS (or that have no checks at all).
if [ "${REQUIRE_CI_STATUS}" -eq 1 ]; then
  jq_filter='.[] | select((.statusCheckRollup | length) == 0 or (all(.statusCheckRollup[]; (.conclusion == "SUCCESS") or (.state == "SUCCESS")))) | "\(.number)\t\(.headRefName)"'
else
  jq_filter='.[] | "\(.number)\t\(.headRefName)"'
fi

is_conflicted() {
  # Prints non-empty if the given revision carries a conflict.
  jj log -r "$1" --no-graph -T 'if(conflict, "conflict", "")' 2>/dev/null
}

commit_id() {
  jj log -r "$1" --no-graph -T 'commit_id' 2>/dev/null
}

log "fetching from ${REMOTE}"
jj git fetch --remote "${REMOTE}"

log "querying eligible PRs (is:open ${SEARCH})"
mapfile -t prs < <(gh pr list --state open --search "${SEARCH}" \
  --json number,headRefName,statusCheckRollup --jq "${jq_filter}")

if [ "${#prs[@]}" -eq 0 ]; then
  log "no eligible PRs; nothing to do"
  exit 0
fi

base_rev="${BASE}"
merged=()
dropped=()

for entry in "${prs[@]}"; do
  number="${entry%%$'\t'*}"
  head_ref="${entry#*$'\t'}"
  [ -n "${number}" ] && [ -n "${head_ref}" ] || { log "skipping malformed entry: ${entry}"; continue; }

  log "stacking PR #${number} (${head_ref}) onto ${base_rev}"

  # Create a new empty change on top of the current stack tip, then rebase the
  # PR's commits onto it. jj auto-rebases descendants and records conflicts as
  # first-class commit state instead of failing the command.
  jj new -m "merge-queue: stack PR #${number}" "${base_rev}"
  if ! jj rebase -d @ -s "${head_ref}@${REMOTE}" 2>/dev/null; then
    log "PR #${number}: rebase failed, dropping"
    gh pr comment "${number}" --body "merge-queue: could not rebase onto ${BASE}, dropped from this cycle" || true
    dropped+=("${number}")
    continue
  fi

  tip=$(commit_id @)
  if [ -n "$(is_conflicted @)" ]; then
    log "PR #${number}: conflict, dropping"
    gh pr comment "${number}" --body "merge-queue: conflict against ${BASE}, dropped from this cycle" || true
    dropped+=("${number}")
    continue
  fi

  if [ -n "${CI_CMD}" ]; then
    log "PR #${number}: running CI gate: ${CI_CMD}"
    if ! bash -c "${CI_CMD}"; then
      log "PR #${number}: CI failed, dropping"
      gh pr comment "${number}" --body "merge-queue: failed CI, dropped from this cycle" || true
      dropped+=("${number}")
      continue
    fi
  fi

  log "PR #${number}: green, advancing stack"
  base_rev="${tip}"
  merged+=("${number}")
done

if [ "${#merged[@]}" -eq 0 ]; then
  log "no PRs survived the stack; not advancing ${BASE}"
  log "dropped: ${dropped[*]:-none}"
  exit 0
fi

log "advancing ${BASE} bookmark to the stacked tip"
jj bookmark set "${BASE}" -r "${base_rev}"

if [ "${DRY_RUN}" -eq 1 ]; then
  log "dry-run: skipping push"
  log "would push ${BASE} with merged PRs: ${merged[*]}"
else
  log "pushing ${BASE}"
  jj git push --bookmark "${BASE}" --remote "${REMOTE}"
fi

log "merged: ${merged[*]}"
log "dropped: ${dropped[*]:-none}"
log "done"
