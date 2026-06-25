# Stacked PR: Merge Main with Conflict Preference

Safely merge `main` into a feature branch created from another branch that was already merged.

## Use Case

**Scenario:**
1. Created `feature-B` from `feature-A`
2. `feature-A` merged into `main`
3. Now merging `main` into `feature-B` shows many false conflicts

**Solution:** Use `-X ours` to prefer your branch's version for conflicts.

## What It Does

1. Verifies clean working directory
2. Creates backup branch (e.g., `feature-B-pre-merge-backup`)
3. Pulls latest `main` from remote
4. Merges `main` with `-X ours` (prefers your branch)
5. Auto-resolves remaining conflicts with your version
6. Runs tests only if conflicts occurred (skips for clean merges)
7. Prompts before pushing
8. Prompts to verify CI before cleanup
9. Deletes backup after confirmation

## Safety Features

- **Backup first**: Creates local backup before any changes
- **No force operations**: Never force-pushes
- **User approval required**: Prompts before push and cleanup
- **Conflict preference**: Always keeps your branch's code
- **Smart testing**: Skips tests for clean merges (relies on CI)

## Usage

```bash
claude

# Execute the skill
> Execute the skill at /path/to/personal-agent-skills/skills/stacked-pr-merge-main/SKILL.md
```

## Conditional Testing

- **Clean merge (no conflicts)**: Skips tests - CI will validate
- **Merge with conflicts**: Runs quick check (`cargo check`, `go build`, `npm test`)

Clean merges are low-risk. Only validate locally when conflicts occurred.

## Recovery

If something goes wrong:

```bash
# Restore pre-merge state
git reset --hard feature-B-pre-merge-backup

# Delete backup when done
git branch -D feature-B-pre-merge-backup
```

## When NOT to Use

- Want to rebase instead of merge
- Need manual conflict review
- Current branch should NOT be source of truth
- On `main` branch

## Design Principles

- Safety first - backup before changes
- User control - prompt before irreversible operations
- Automation - handle common cases automatically
- Simplicity - minimal steps, maximum clarity
