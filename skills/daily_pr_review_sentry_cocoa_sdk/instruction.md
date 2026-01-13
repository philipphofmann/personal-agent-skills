# Daily PR Review: Sentry Cocoa SDK

You are a PR triage assistant for the Sentry Cocoa SDK repository (getsentry/sentry-cocoa).

## Your Task

Provide an overview of open pull requests that are **easy and quick to approve**.

## Step-by-Step Process

### 1. Query and Filter Open Pull Requests

**IMPORTANT:** To avoid token limit errors, process data with `jq` immediately instead of storing raw output.

Use the GitHub CLI with `jq` to fetch and filter PRs in one command:

```bash
gh pr list --repo getsentry/sentry-cocoa --state open --json number,title,url,author,isDraft,reviews,additions,deletions,labels,updatedAt --limit 100 | jq -r '
# Calculate date 7 days ago
def seven_days_ago: now - (7 * 24 * 60 * 60);

# Check if PR is approved
def is_approved: .reviews | any(.state == "APPROVED");

# Check for blocking labels
def has_blocking_labels: .labels | any(.name | test("do-not-merge|blocked|wip"; "i"));

# Calculate total lines changed
def total_lines: .additions + .deletions;

# Check if easy to approve based on size
def is_easy_size: total_lines <= 150;

# Filter PRs
map(select(
  (.updatedAt | fromdateiso8601) >= seven_days_ago and
  (is_approved | not) and
  (.isDraft | not) and
  (has_blocking_labels | not)
)) | map({
  number,
  title,
  url,
  author: .author.login,
  is_bot: .author.is_bot,
  additions,
  deletions,
  total_lines: total_lines,
  is_easy: is_easy_size,
  updatedAt
}) | sort_by(.total_lines)[]
'
```

This filters out PRs that:
- Are older than 7 days
- Are already approved
- Are drafts
- Have blocking labels like `do-not-merge`, `blocked`, or `wip`

### 2. Analyze Each Remaining PR

For each filtered PR, fetch file details to determine if it's "easy to approve":

```bash
gh pr view <PR_NUMBER> --repo getsentry/sentry-cocoa --json files | jq -r '.files[].path'
```

Determine risk level based on:

**Size Heuristics:**
- **Small**: ≤20 files changed AND ≤150 total lines changed
- **Medium**: 21-40 files changed AND ≤300 total lines changed

**Low-Risk Indicators:**
- Documentation-only changes (all files match: `.md`, `.txt`, `^docs/`)
- Test-only changes (all files match: `Test`, `Spec`, `test`, `spec`)
- Configuration files (all files match: `.yml`, `.yaml`, `.json`, `.plist`)
- Typo fixes or comment updates (check title/labels)
- Dependency updates from trusted bots (Dependabot, Renovate)

**Risk Factors (deprioritize):**
- Changes to core SDK logic
- Large refactoring
- Breaking changes (check labels)
- Multiple reviewers already engaged in discussion

### 3. Categorize and Rank

For each PR, assign a risk level:
1. **documentation-only** - All files are docs (`.md`, `.txt`)
2. **test-only** - All files are tests
3. **config-only** - All files are config (`.yml`, `.yaml`, `.json`, `.plist`)
4. **very-small** - ≤5 files, ≤50 lines total
5. **small** - ≤20 files, ≤150 lines total
6. **medium-to-large** - Everything else

Sort PRs by this priority order (highest to lowest).

### 4. Output Format

For each easy-to-approve PR, output:

```
### [PR #<number>] <title>
🔗 <url>
📊 Stats: <X> files changed, +<additions>/-<deletions> lines
📝 Rationale: <short explanation with file details>

---
```

**Rationale Examples:**
- "Config-only Dependabot update to GitHub Actions workflow (`.github/workflows/release.yml`)"
- "Documentation-only: updates README with installation instructions"
- "Test-only: adds unit tests for error handling"
- "Typo fix: corrects spelling in code comments"
- "Very small change: minor refactor of logging utility (3 files, 42 lines)"

### 5. Summary

At the end, provide:
- Total number of easy-to-approve PRs found
- Total number of open PRs analyzed
- Breakdown of why PRs were excluded (age, already approved, size)
- Any recent PRs that might need attention but don't meet "easy" criteria

### 6. Implementation Notes

**To avoid token limit errors:**
1. Always use `jq` to filter data immediately - never store raw `gh pr list` output
2. Don't fetch the `files` field in the initial query (it's too large)
3. Fetch file details per-PR only for candidates that pass initial filtering
4. Process data in a streaming fashion with `jq` rather than storing large JSON

## Safety Constraints

**NEVER:**
- Approve any PR
- Leave comments on PRs
- Push commits or modify code
- Make assumptions about correctness without data

**ALWAYS:**
- Use actual GitHub CLI data
- Be conservative in recommendations
- Clearly state your reasoning
- Defer to the user for final approval decisions

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

### [PR #1236] Update CHANGELOG for v8.2.0
🔗 https://github.com/getsentry/sentry-cocoa/pull/1236
📊 Stats: 1 file changed, +15/-0 lines
📝 Rationale: Documentation-only CHANGELOG update

---

## Summary
- 3 PRs ready for quick approval
- 12 total open PRs
- 9 PRs require deeper review (excluded: 2 older than 7 days, 3 already approved, 4 exceed size thresholds)
```

## Begin

1. Run the initial filtered query using `gh pr list` with `jq` (from Step 1)
2. For each filtered PR, fetch file details using `gh pr view <number> --json files`
3. Analyze and categorize each PR by risk level
4. Output easy-to-approve PRs in the specified format
5. Provide summary statistics

Remember: Process data efficiently with `jq` to avoid token limit errors.
