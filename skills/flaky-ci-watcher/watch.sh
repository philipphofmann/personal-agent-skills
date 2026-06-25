#!/usr/bin/env bash
#
# flaky-ci-watcher background watcher.
#
# Cheap poller for the flaky-ci-watcher skill. Every POLL_INTERVAL seconds it
# checks your approved open PRs and only prints the loop sentinel (waking the
# agent to do real work) when a NEW failure appears, or when all CI has settled.
# While checks are merely pending/passing it stays silent — so a tight 10s
# cadence costs almost nothing.
#
# Usage:   bash watch.sh [poll_interval_seconds]
# Env:     POLL_INTERVAL          seconds between polls (default 10; arg overrides)
#          FLAKY_CI_WATCHER_HOME  state dir (default ~/.claude/flaky-ci-watcher)
#
# Output:  lines beginning `AGENT_LOOP_WAKE_flakyci {...}` — wire this up with
#          the loop skill's notify_on_output on `^AGENT_LOOP_WAKE_flakyci`.

set -euo pipefail

POLL_INTERVAL="${1:-${POLL_INTERVAL:-10}}"
SENTINEL="AGENT_LOOP_WAKE_flakyci"
STATE_DIR="${FLAKY_CI_WATCHER_HOME:-$HOME/.claude/flaky-ci-watcher}"
SIG_FILE="$STATE_DIR/lastsig"

mkdir -p "$STATE_DIR"
rm -f "$SIG_FILE"

while true; do
  prs=$(gh search prs --author=@me --state=open --review=approved \
        --json number,repository --limit 50 \
        --jq '.[] | "\(.repository.nameWithOwner) \(.number)"' 2>/dev/null || true)

  fails=""
  pending=0
  while read -r repo num; do
    [ -z "$repo" ] && continue
    checks=$(gh pr checks "$num" --repo "$repo" --json bucket,state,workflow 2>/dev/null) || continue
    echo "$checks" | jq -e '.[] | select(.bucket=="pending")' >/dev/null 2>&1 && pending=1
    f=$(echo "$checks" | jq -r --arg k "$repo#$num" \
        '.[] | select(.bucket=="fail" or .state=="failure" or .state=="error") | "\($k)#\(.workflow)"')
    [ -n "$f" ] && fails="$fails$f
"
  done <<< "$prs"

  sig=$(printf '%s' "$fails" | sort -u | shasum | awk '{print $1}')
  last=$(cat "$SIG_FILE" 2>/dev/null || true)

  if [ -n "$fails" ] && [ "$sig" != "$last" ]; then
    printf '%s\n' "$sig" > "$SIG_FILE"
    echo "$SENTINEL {\"prompt\":\"/flaky-ci-watcher\"}"            # new failure -> wake the agent
  elif [ -z "$fails" ] && [ "$pending" -eq 0 ]; then
    echo "$SENTINEL {\"prompt\":\"/flaky-ci-watcher (final pass - all CI settled)\"}"
    break                                                          # everything green/done -> stop watching
  fi

  sleep "$POLL_INTERVAL"
done
