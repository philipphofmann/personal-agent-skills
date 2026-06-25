# Testing Guide

How to test the `daily-pr-review-sentry-cocoa-sdk` skill.

## Prerequisites

1. GitHub CLI installed and authenticated
2. Access to getsentry/sentry-cocoa repository

## Manual Testing Steps

### 1. Test GitHub CLI Access

```bash
gh auth status
gh repo view getsentry/sentry-cocoa
```

Expected: Both commands should succeed without errors.

### 2. Test PR Query

```bash
gh pr list --repo getsentry/sentry-cocoa --state open --json number,title,url,author,isDraft,reviews,files,additions,deletions,labels,updatedAt
```

Expected: JSON output with list of open PRs including their last update timestamp.

### 3. Test Full Skill

Run the skill via Claude Code CLI and verify:

**Should Include:**
- PRs updated within the last 7 days
- PRs with ≤20 files and ≤150 lines changed
- Documentation-only PRs (`.md` files)
- Test-only PRs
- Typo fixes
- Non-draft, non-approved PRs

**Should Exclude:**
- PRs older than 7 days
- Already-approved PRs
- Draft PRs
- Large PRs (>150 lines or >20 files)
- PRs with "do-not-merge" labels

### 4. Verify Read-Only Behavior

After running the skill, verify that:
- No PRs were approved
- No comments were posted
- No code was modified
- No commits were made

Check with:
```bash
gh pr list --repo getsentry/sentry-cocoa --state open | head -5
# Compare before/after to ensure nothing changed
```

## Test Scenarios

### Scenario 1: Documentation PR

**Setup**: Find or create a PR that only modifies `.md` files

**Expected Output**:
```
### [PR #XXXX] Update README
🔗 https://github.com/getsentry/sentry-cocoa/pull/XXXX
📊 Stats: 1 file changed, +10/-5 lines
📝 Rationale: Documentation-only change to README.md
```

### Scenario 2: Large PR

**Setup**: Find a PR with >150 lines or >20 files changed

**Expected**: PR should NOT appear in the easy-to-approve list

### Scenario 3: Old PR

**Setup**: Find a PR that hasn't been updated in more than 7 days

**Expected**: PR should NOT appear in the easy-to-approve list

**Verification**:
```bash
gh pr view <PR_NUMBER> --repo getsentry/sentry-cocoa --json updatedAt
# Check if updatedAt is older than 7 days
```

### Scenario 4: Already-Approved PR

**Setup**: Find a PR that has already been approved

**Expected**: PR should NOT appear in the easy-to-approve list

### Scenario 5: Draft PR

**Setup**: Find or create a draft PR

**Expected**: PR should NOT appear in the easy-to-approve list

### Scenario 6: Empty Result Set

**Setup**: Run the skill when no PRs meet the criteria

**Expected Output**:
```
## Easy-to-Approve PRs for Sentry Cocoa SDK
Found 0 easy-to-approve PRs out of X open PRs

No PRs currently meet the easy-to-approve criteria.
```

## Validation Checklist

- [ ] Skill queries GitHub successfully
- [ ] Filters exclude PRs older than 7 days
- [ ] Filters exclude approved PRs
- [ ] Filters exclude draft PRs
- [ ] Size heuristics work correctly (≤20 files, ≤150 lines)
- [ ] Documentation PRs are prioritized
- [ ] Test-only PRs are identified
- [ ] Output format is readable and scannable
- [ ] URLs are clickable
- [ ] Rationales are clear and accurate
- [ ] No write operations occur
- [ ] No PRs are approved
- [ ] No comments are posted

## Edge Cases

### No Open PRs

If there are no open PRs at all:

**Expected Output**:
```
## Easy-to-Approve PRs for Sentry Cocoa SDK
Found 0 easy-to-approve PRs out of 0 open PRs

No open PRs currently exist for this repository.
```

### All PRs Excluded

If all open PRs are old, large, approved, or drafts:

**Expected Output**:
```
## Easy-to-Approve PRs for Sentry Cocoa SDK
Found 0 easy-to-approve PRs out of 8 open PRs

All open PRs require deeper review:
- 2 PRs are older than 7 days
- 3 PRs are already approved
- 1 PR is a draft
- 2 PRs exceed size thresholds
```

### GitHub API Rate Limit

If rate limited:

**Expected**: Clear error message with retry suggestions

## Performance Testing

### Typical Runtime

With 10-20 open PRs, the skill should complete in:
- **PR query**: 1-2 seconds
- **Analysis**: 2-5 seconds
- **Total**: ~5-10 seconds

### Large PR Count

With 50+ open PRs:
- Should still complete in <30 seconds
- Output should be paginated or truncated if too long

## Debugging

### Enable Verbose Output

```bash
gh pr list --repo getsentry/sentry-cocoa --state open --json number,title,url,author,isDraft,reviews,files,additions,deletions,labels | jq .
```

### Check Individual PR Details

```bash
gh pr view <PR_NUMBER> --repo getsentry/sentry-cocoa --json number,title,url,files,additions,deletions,reviews
```

### Verify Filtering Logic

Manually verify the filtering logic by:
1. Listing all open PRs
2. Checking each PR's approval status
3. Checking each PR's size
4. Confirming the skill's output matches manual analysis

## Regression Testing

When updating the skill, test these scenarios:

1. **Before**: Run the skill and save output
2. **Change**: Make modifications to `SKILL.md` or `skill.json`
3. **After**: Run the skill again
4. **Compare**: Ensure changes behave as expected

## Continuous Validation

Consider running this skill daily and tracking:
- Number of PRs identified
- Accuracy of "easy to approve" classification
- False positives (PRs marked easy but weren't)
- False negatives (easy PRs that were missed)

This feedback can help tune the heuristics over time.
