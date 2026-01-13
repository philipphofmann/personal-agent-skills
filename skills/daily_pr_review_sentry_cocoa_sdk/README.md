# Daily PR Review: Sentry Cocoa SDK

A read-only skill for getting an overview of easy-to-approve PRs in the Sentry Cocoa SDK repository.

## Purpose

This skill helps you quickly identify pull requests that:
- Are small in scope
- Have low risk
- Can be reviewed and approved quickly
- Don't require deep code analysis

Run this anytime to quickly triage and clear out simple PRs before tackling more complex work.

## Requirements

### Tools
- **GitHub CLI (`gh`)**: Must be installed and authenticated
  ```bash
  # Install (macOS)
  brew install gh

  # Authenticate
  gh auth login
  ```

### Permissions
- Read access to `getsentry/sentry-cocoa` repository

## Usage

### Option 1: Run via Claude Code CLI

If you have this skill registered in your Claude Code configuration:

```bash
claude /daily_pr_review_sentry_cocoa_sdk
```

### Option 2: Manual Invocation

Copy the contents of `instruction.md` and paste it into your Claude Code session.

### Option 3: Direct Command

Run the filtered query directly:

```bash
gh pr list --repo getsentry/sentry-cocoa --state open --json number,title,url,author,isDraft,reviews,additions,deletions,labels,updatedAt --limit 100 | jq -r '
# Calculate date 7 days ago
def seven_days_ago: now - (7 * 24 * 60 * 60);

# Check if PR is approved
def is_approved: .reviews | any(.state == "APPROVED");

# Check for blocking labels
def has_blocking_labels: .labels | any(.name | test("do-not-merge|blocked|wip"; "i"));

# Filter and display PRs
map(select(
  (.updatedAt | fromdateiso8601) >= seven_days_ago and
  (is_approved | not) and
  (.isDraft | not) and
  (has_blocking_labels | not)
)) | map({
  number,
  title,
  url,
  additions,
  deletions,
  total_lines: (.additions + .deletions)
}) | sort_by(.total_lines)[]
'
```

Then ask Claude Code to analyze the output using the criteria in `instruction.md`.

**Note:** The command uses `jq` to avoid token limit errors when processing large amounts of PR data.

## What It Does

1. **Fetches** all open PRs from getsentry/sentry-cocoa
2. **Filters out**:
   - PRs older than 7 days
   - Already-approved PRs
   - Draft PRs
   - PRs with blocking labels
3. **Analyzes** remaining PRs for "easy to approve" criteria:
   - Small diff size (≤20 files, ≤150 lines)
   - Low-risk file types (docs, tests, config)
   - Simple changes (typos, comments, minor updates)
4. **Ranks** PRs by ease of approval
5. **Outputs** a scannable list with title, URL, and rationale

## What It Does NOT Do

- ❌ Approve PRs
- ❌ Leave comments
- ❌ Push commits
- ❌ Modify code
- ❌ Make assumptions about correctness

This is a **read-only information tool**.

## Example Output

```
## Easy-to-Approve PRs for Sentry Cocoa SDK
Found 3 easy-to-approve PRs out of 12 open PRs

---

### [PR #1234] Fix typo in README
🔗 https://github.com/getsentry/sentry-cocoa/pull/1234
📊 Stats: 1 file changed, +2/-2 lines
📝 Rationale: Documentation-only typo fix in README.md

---

### [PR #1235] Add tests for network error handling
🔗 https://github.com/getsentry/sentry-cocoa/pull/1235
📊 Stats: 2 files changed, +67/-0 lines
📝 Rationale: Test-only change adding unit tests for error scenarios

---
```

## Configuration

The skill uses these heuristics (defined in `skill.json`):

### Easy Approve Criteria
- **Max age**: 7 days (only PRs updated within the last week)
- **Max files changed**: 20
- **Max lines changed**: 150
- **Preferred file types**: `.md`, `.txt`, `.yml`, `.yaml`
- **Low-risk patterns**: docs, README, changelog, comments, typos, tests

You can adjust these values in `skill.json` to match your preferences.

## Customization

To adapt this skill for other repositories:

1. Update `repository` in `skill.json`
2. Modify the `gh pr list --repo` command in `instruction.md`
3. Adjust the size/risk criteria to match the project's needs

## Troubleshooting

### "gh: command not found"
Install the GitHub CLI: `brew install gh`

### "authentication required"
Run: `gh auth login`

### "repository not found"
Ensure you have read access to the repository. Check with:
```bash
gh repo view getsentry/sentry-cocoa
```

### "File content exceeds maximum allowed tokens"
This error occurs when trying to process too much PR data at once. The skill has been updated to:
- Use `jq` to filter data immediately (never store raw output)
- Exclude the `files` field from initial queries
- Fetch file details per-PR only after filtering

If you still encounter this error, ensure you're using the updated `instruction.md` that processes data with `jq` in the initial query.

## Design Decisions

### Why these specific criteria?
- **≤7 days old**: Focuses on recent PRs that are likely still relevant and active
- **≤20 files, ≤150 lines**: Empirically, PRs of this size can be reviewed in 2-5 minutes
- **Documentation/tests preferred**: Lowest risk of breaking production code
- **Exclude drafts**: Author hasn't signaled readiness for review
- **Exclude approved**: Already reviewed, no action needed

### Why read-only?
- Safety: prevents accidental approvals
- Transparency: you see the reasoning before acting
- Flexibility: you can override any recommendation

## Future Enhancements

Potential additions (not yet implemented):
- Integration with Claude Code's scheduling for true "daily" runs
- Filtering by specific reviewers or teams
- Integration with linear velocity metrics
- Machine learning on past approval patterns
- Slack/email notifications

## License

Part of the personal-agent-skills collection.
