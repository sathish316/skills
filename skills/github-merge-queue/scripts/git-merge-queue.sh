#!/usr/bin/env bash
# git-merge-queue.sh — a git-based merge-queue worker.
#
# Serializes integration of approved GitHub PRs: fetch trunk into a disposable
# attempt branch, stack each eligible PR onto it with a merge, optionally run a
# CI command against the stacked result, drop any PR that conflicts or fails,
# and fast-forward `main` only when the whole surviving stack is green.
#
# Designed to run inside a dedicated clone/workspace that no human edits.
set -euo pipefail

script_name=$(basename "$0")

BASE="main"
REMOTE="origin"
CI_CMD=""
REQUIRE_CI_STATUS=0
DRY_RUN=0
SEARCH="review:approved"
ATTEMPT_BRANCH="mq-attempt"

usage() {
  cat <<USAGE
Usage:
  ${script_name} [options]

Runs one pass of a git-based merge queue: stacks eligible approved PRs onto the
trunk in a disposable branch, tests each, and pushes to trunk only if green.

Options:
  --base BRANCH          Trunk branch to advance (default: ${BASE})
  --remote NAME          Git remote (default: ${REMOTE})
  --search QUERY         Extra gh PR search filter (default: "${SEARCH}")
  --attempt-branch NAME  Disposable stacking branch (default: ${ATTEMPT_BRANCH})
  --ci-cmd "CMD"         Command to run as the CI gate against each stacked PR.
                         Non-zero exit drops that PR from this cycle.
  --require-ci-status    Only consider PRs whose GitHub status checks are all
                         passing (or have no checks) via statusCheckRollup.
  --dry-run              Do everything except pushing to the trunk branch.
  -h, --help             Show this help.

Requires: git, gh (authenticated), jq.
USAGE
}

die() { printf 'error: %s\n' "$*" >&2; exit 1; }
log() { printf '[merge-queue] %s\n' "$*"; }

while [ "$#" -gt 0 ]; do
  case "$1" in
    --base) BASE="${2:?--base needs a value}"; shift 2;;
    --remote) REMOTE="${2:?--remote needs a value}"; shift 2;;
    --search) SEARCH="${2:?--search needs a value}"; shift 2;;
    --attempt-branch) ATTEMPT_BRANCH="${2:?--attempt-branch needs a value}"; shift 2;;
    --ci-cmd) CI_CMD="${2:?--ci-cmd needs a value}"; shift 2;;
    --require-ci-status) REQUIRE_CI_STATUS=1; shift;;
    --dry-run) DRY_RUN=1; shift;;
    -h|--help) usage; exit 0;;
    *) die "unknown argument: $1 (see --help)";;
  esac
done

command -v git >/dev/null 2>&1 || die "git not found on PATH"
command -v gh >/dev/null 2>&1 || die "gh not found on PATH"
command -v jq >/dev/null 2>&1 || die "jq not found on PATH"

if [ "${REQUIRE_CI_STATUS}" -eq 1 ]; then
  jq_filter='.[] | select((.statusCheckRollup | length) == 0 or (all(.statusCheckRollup[]; (.conclusion == "SUCCESS") or (.state == "SUCCESS")))) | "\(.number)\t\(.headRefName)"'
else
  jq_filter='.[] | "\(.number)\t\(.headRefName)"'
fi

log "fetching ${REMOTE}/${BASE}"
git fetch "${REMOTE}" "${BASE}"

log "starting attempt branch ${ATTEMPT_BRANCH} from ${REMOTE}/${BASE}"
git checkout -B "${ATTEMPT_BRANCH}" "${REMOTE}/${BASE}"

log "querying eligible PRs (is:open ${SEARCH})"
mapfile -t prs < <(gh pr list --state open --search "${SEARCH}" \
  --json number,headRefName,statusCheckRollup --jq "${jq_filter}")

if [ "${#prs[@]}" -eq 0 ]; then
  log "no eligible PRs; nothing to do"
  exit 0
fi

merged=()
dropped=()

for entry in "${prs[@]}"; do
  number="${entry%%$'\t'*}"
  head_ref="${entry#*$'\t'}"
  [ -n "${number}" ] && [ -n "${head_ref}" ] || { log "skipping malformed entry: ${entry}"; continue; }

  log "stacking PR #${number} (${head_ref})"
  git fetch "${REMOTE}" "pull/${number}/head:pr-${number}"

  if git merge --no-ff "pr-${number}" -m "merge-queue: PR #${number}"; then
    if [ -n "${CI_CMD}" ]; then
      log "PR #${number}: running CI gate: ${CI_CMD}"
      if ! bash -c "${CI_CMD}"; then
        log "PR #${number}: CI failed, dropping"
        git reset --hard HEAD~1
        gh pr comment "${number}" --body "merge-queue: failed CI, dropped from this cycle" || true
        dropped+=("${number}")
        continue
      fi
    fi
    log "PR #${number}: green, kept on the stack"
    merged+=("${number}")
  else
    log "PR #${number}: conflict, dropping"
    git merge --abort
    gh pr comment "${number}" --body "merge-queue: conflict against ${BASE}, dropped from this cycle" || true
    dropped+=("${number}")
    continue
  fi
done

if [ "${#merged[@]}" -eq 0 ]; then
  log "no PRs survived the stack; not advancing ${BASE}"
  log "dropped: ${dropped[*]:-none}"
  exit 0
fi

if [ "${DRY_RUN}" -eq 1 ]; then
  log "dry-run: skipping push"
  log "would push ${ATTEMPT_BRANCH} -> ${BASE} with merged PRs: ${merged[*]}"
else
  log "pushing ${ATTEMPT_BRANCH} to ${REMOTE}/${BASE}"
  git push "${REMOTE}" "${ATTEMPT_BRANCH}:${BASE}"
fi

log "merged: ${merged[*]}"
log "dropped: ${dropped[*]:-none}"
log "done"
