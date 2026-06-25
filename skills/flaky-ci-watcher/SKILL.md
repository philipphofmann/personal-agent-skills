---
name: flaky-ci-watcher
description: Watch your own approved open PRs across all repos, automatically re-run flaky CI failures (up to 2x), and alert in the terminal when a failure looks real (caused by your changes) or stays flaky. Use when you want CI monitored and flaky jobs re-run on your behalf while you let auto-merge handle the rest. Runs continuously as a cheap background watcher that polls every ~10s and only wakes for real work when a check fails.
---

# Flaky CI Watcher

You monitor the user's **own, already-approved** open pull requests whose CI is
still running, automatically re-run failures that look **flaky**, and **stop and
alert** the user (in the terminal) when a failure looks **real** (caused by the
PR's own changes) or when a flaky-looking job has already been re-run the maximum
number of times.

The user enables auto-merge themselves. **This skill never approves, merges,
comments, or pushes code.** Its only write actions are re-running CI jobs.

## Configuration

```
RERUN_CAP        = 2        # max automatic re-runs of a flaky-looking job before escalating
POLL_INTERVAL    = 10       # seconds between cheap CI polls in the background watcher (10–30s)
SCOPE            = my approved open PRs, across all repositories
NOTIFY_CHANNEL   = terminal (print the alert in this session)
STATE_DIR        = ${FLAKY_CI_WATCHER_HOME:-$HOME/.claude/flaky-ci-watcher}
STATE_FILE       = $STATE_DIR/state.json
```

`STATE_DIR` lives under Claude Code's own user-data directory (`~/.claude`): a
stable, user-owned location that persists across sessions and repos, is writable
without per-write approval, and stays out of any git checkout. Override it with
the `FLAKY_CI_WATCHER_HOME` env var if needed.

This skill is meant to be run **repeatedly**. The preferred way is the
**continuous background mode** below: a cheap bash watcher polls CI every
`POLL_INTERVAL` seconds and only wakes the agent to do real work (fetch logs,
classify, re-run, alert) when a check actually **fails** — so a tight 10s cadence
costs almost nothing while CI is merely pending. You can also re-invoke it
manually for a single pass. Each wake-up is **one pass**. State (re-run counts,
what was already reported) persists in `STATE_FILE` between passes so you never
exceed `RERUN_CAP` and never alert twice for the same thing.

## Continuous background mode (preferred)

Run the skill as a long-lived **background watcher** that polls CI every
`POLL_INTERVAL` seconds but only wakes you when there is something to act on.
This honours a tight 10–30s cadence without spending model tokens or GitHub API
quota on every tick.

The watcher lives in its own file next to this skill — [`watch.sh`](./watch.sh) —
so it's easy to maintain and test independently of this doc. It uses a **one-shot
wake model**: it polls quietly while CI is pending and, the moment it sees
something actionable (a failing check, or all PRs fully settled), it prints a
single sentinel line and **exits**. The agent harness re-invokes the agent when a
tracked background task exits, so the exit *is* the wake.

**Arm it via the harness's background mode** (the `loop` skill, or a backgrounded
tool call the harness tracks) — **never** `nohup`/`&`/`disown`. A detached
process is invisible to the harness and can never wake the agent (it just writes
the sentinel to a log nobody reads). Track its task id/PID so it can be stopped.

```bash
bash "$SKILL_DIR/watch.sh" "$POLL_INTERVAL"   # run in the harness's BACKGROUND mode
# $SKILL_DIR is this skill's directory, e.g. ~/.claude/skills/flaky-ci-watcher
# POLL_INTERVAL (seconds) is optional; defaults to 10.
```

The cycle:
1. Arm `watch.sh` in the background. It polls every `POLL_INTERVAL`s.
2. **While everything is pending/pass** → silent, no agent wake, no model cost.
3. **A check fails** *or* **all PRs settle** → it prints the sentinel and exits →
   the harness wakes the agent → run **one pass** (§§1–7).
4. After the pass (e.g. you re-ran a flaky job, sending it back to pending),
   **re-arm a fresh `watch.sh`** to continue watching. The `RERUN_CAP` in
   `STATE_FILE` bounds re-runs across passes and escalates when exhausted.

Don't arm a second watcher if one is already armed. Polling every 10s does ~2
`gh` calls per approved PR per tick — comfortably within GitHub's authenticated
rate limit for a normal number of open PRs; raise `POLL_INTERVAL` toward 30s if
you watch many PRs at once.

## One pass

### 1. Load state

Read `STATE_FILE` if it exists (JSON). If missing/corrupt, start from `{}`
(create `STATE_DIR` with `mkdir -p` first if it doesn't exist — `watch.sh` does
this for you, but a manual pass may run without it).
The state maps a key `"<repo>#<pr>#<workflow>"` to:

```json
{ "rerun_count": 0, "alerted": false, "last_head_sha": "<sha>" }
```

If a PR's head SHA changed since `last_head_sha` (new commit pushed), reset that
PR's entries (`rerun_count` back to 0, `alerted` back to false) — a new push is a
fresh CI run, not a continuation of the old flaky one.

### 2. Find candidate PRs

Fetch the user's own approved, open PRs across all repos. Filter to those whose
CI is **still running** (has pending/in-progress checks) OR has **failing**
checks (a flaky failure may have already landed):

```bash
gh search prs --author=@me --state=open --review=approved \
  --json number,repository,title,url --limit 50
```

For each result, check the rollup status (skip drafts and PRs with no checks):

```bash
gh pr checks <number> --repo <owner/repo> \
  --json name,state,bucket,workflow,link 2>/dev/null
```

Keep a PR as a candidate if any check is `pending`/`in_progress` **or** `fail`.
Ignore PRs whose checks are all `pass`/`skipping` — nothing to do.

### 3. For each candidate PR, inspect failing checks

Only failed checks need action. For each check with `bucket == "fail"` (or
`state == "failure"/"error"`):

1. Resolve the run ID from the check's `link` (the `…/actions/runs/<run-id>` URL),
   or via `gh run list --repo <owner/repo> --branch <pr-branch> --limit 10 --json databaseId,headSha,status,conclusion,workflowName`.
2. Pull the failing log (keep it small — only the failed steps):

   ```bash
   gh run view <run-id> --repo <owner/repo> --log-failed 2>/dev/null | tail -c 20000
   ```
3. Fetch the PR's changed files once (cache for the pass):

   ```bash
   gh pr view <number> --repo <owner/repo> --json files,headRefOid \
     --jq '{sha: .headRefOid, files: [.files[].path]}'
   ```

### 4. Short analysis — flaky vs. real

Decide **real** (caused by the PR) vs. **flaky** (infra/intermittent) from the
failed log. Lean toward **real** when uncertain — re-running a genuinely broken
build wastes CI and delays the alert the user actually wants.

**Signals it is REAL (caused by the PR's changes) → STOP, do not re-run:**
- Compile/build/type errors, or lint errors, in a file the PR changed.
- A failing test that exercises code in the PR's changed files.
- The same test/step fails in the **same place** across re-runs (deterministic).
- Assertion failures whose message reflects logic the PR touched.

**Signals it is FLAKY (intermittent/infra) → eligible for re-run:**
- Network/timeout errors: `ETIMEDOUT`, `ECONNREFUSED`, `could not resolve host`,
  `connection reset`, `timed out`, rate-limit / `429`.
- Runner/infra: `runner has received a shutdown signal`, `lost communication`,
  `no space left on device`, simulator/emulator boot failure, image pull failure.
- A failing test **unrelated** to the PR's changed files.
- Known intermittent patterns: random segfaults/crashes in unrelated subsystems,
  `Resource not accessible`, flaky-tagged tests.

Write a one-to-two sentence rationale citing the specific log line(s).

### 5. Act

For each failed check, using its state key `"<repo>#<pr>#<workflow>"`:

- **REAL failure** → do **not** re-run. If `alerted` is false, emit a **real-failure
  alert** (§6) and set `alerted = true`.
- **FLAKY** and `rerun_count < RERUN_CAP` → re-run the failed jobs, increment
  `rerun_count`:

  ```bash
  gh run rerun <run-id> --repo <owner/repo> --failed
  ```

  Print a short line: `↻ re-ran flaky <workflow> on <repo>#<pr> (attempt N/RERUN_CAP)`.
- **FLAKY** and `rerun_count >= RERUN_CAP` → do **not** re-run again. If `alerted`
  is false, emit a **persistent-flaky alert** (§6) and set `alerted = true`.

Update `last_head_sha` for each PR. Save `STATE_FILE`.

### 6. Terminal alerts

Print alerts plainly in this session. Two kinds:

**Real failure (needs your attention):**
```
🔴 Real failure — <repo>#<pr>: <title>
   Workflow: <workflow> · <url>
   Why real: <one-line rationale citing the log>
   Action: stopped re-running. This looks caused by your changes, not flaky.
```

**Persistent flaky (gave up re-running):**
```
🟡 Flaky test — <repo>#<pr>: <title>
   Workflow: <workflow> · <url>
   Re-ran <RERUN_CAP>× and it keeps failing intermittently: <one-line rationale>
   Action: stopped re-running. "Hey, this looks like another flaky test."
```

### 7. Pass summary

End every pass with a compact summary so a `loop` run stays readable:

```
CI watch pass @ <time>: <N> approved PRs with active/failed CI · <R> jobs re-run · <A> alerts
- <repo>#<pr>: <pass | pending | re-ran flaky (1/2) | 🔴 real | 🟡 flaky>
```

If there are no candidate PRs, print one line: `No approved PRs with running or
failed CI. Nothing to do.`

## Safety constraints

**NEVER:** approve, merge, enable auto-merge, comment on PRs, or push/modify code.
**ONLY write action:** `gh run rerun … --failed` on flaky-looking failures, capped
at `RERUN_CAP` per workflow per head SHA.
**ALWAYS:** prefer "real" when the analysis is ambiguous; cite the actual log line
in every alert; never alert twice for the same key unless a new commit was pushed.

## Begin

If invoked to **start watching** (and no watcher is already running), arm the
background watcher from *Continuous background mode* above, confirm the interval
and PID, then run one pass immediately. On each sentinel wake-up — or when
invoked manually for a single pass — do:

1. Load `STATE_FILE`.
2. Find your approved open PRs and filter to those with running or failing CI.
3. For each failing check: get the failed log, classify flaky vs. real.
4. Re-run flaky failures (up to `RERUN_CAP`); alert on real or persistent-flaky.
5. Save state and print the pass summary.
