#!/usr/bin/env bash
#
# flaky-ci-watcher background watcher (one-shot wake model).
#
# Cheap poller for the flaky-ci-watcher skill. Every POLL_INTERVAL seconds it
# checks your approved open PRs. As soon as it sees something ACTIONABLE it
# prints a single loop sentinel line and EXITS — so the agent harness, which
# re-invokes the agent when a tracked background task exits, wakes the skill to
# do real work. While checks are merely pending it stays silent and keeps
# polling, so a tight 10s cadence costs almost nothing.
#
# Actionable = any approved PR has a failing check (-> classify/re-run), OR all
# approved PRs have fully settled with no pending checks (-> final pass).
#
# Run it via the harness's BACKGROUND mode (run_in_background), NOT nohup/&/
# disown — a detached process is invisible to the harness and can never wake the
# agent. On exit, handle one pass, then re-arm a fresh watcher.
#
# Usage:   bash watch.sh [poll_interval_seconds]
# Env:     POLL_INTERVAL  seconds between polls (default 10; arg overrides)
# Output:  one line `AGENT_LOOP_WAKE_flakyci {"prompt": "..."}` then exit 0.

set -uo pipefail

POLL_INTERVAL="${1:-${POLL_INTERVAL:-10}}"
SENTINEL="AGENT_LOOP_WAKE_flakyci"

while true; do
  # Sleep first so a just-triggered re-run has time to flip to "pending"
  # before we poll — otherwise a fresh arming could re-fire on a stale failure.
  sleep "$POLL_INTERVAL"

  prs=$(gh search prs --author=@me --state=open --review=approved \
        --json number,repository --limit 50 \
        --jq '.[] | "\(.repository.nameWithOwner) \(.number)"' 2>/dev/null || true)

  fails=0
  pending=0
  any=0
  while read -r repo num; do
    [ -z "$repo" ] && continue
    any=1
    checks=$(gh pr checks "$num" --repo "$repo" --json bucket,state 2>/dev/null) || continue
    echo "$checks" | jq -e '.[] | select(.bucket=="pending")' >/dev/null 2>&1 && pending=1
    echo "$checks" | jq -e '.[] | select(.bucket=="fail" or .state=="failure" or .state=="error")' >/dev/null 2>&1 && fails=1
  done <<< "$prs"

  if [ "$fails" -eq 1 ]; then
    echo "$SENTINEL {\"prompt\": \"/flaky-ci-watcher\"}"            # a check failed -> wake to classify/re-run
    exit 0
  elif [ "$any" -eq 1 ] && [ "$pending" -eq 0 ]; then
    echo "$SENTINEL {\"prompt\": \"/flaky-ci-watcher (final pass - all CI settled)\"}"
    exit 0                                                          # everything green/done -> final pass
  fi
  # else: still pending, or no approved PRs yet -> keep polling silently.
done
