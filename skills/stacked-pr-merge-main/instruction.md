# Stacked PR: Merge Main with Conflict Preference

Merge `main` into a feature branch created from another branch that was merged into `main`. Use `-X ours` to prefer the current branch on conflicts.

## Workflow

### Step 1: Pre-flight Checks

```bash
CURRENT_BRANCH=$(git branch --show-current)

# Verify not on main
[ "$CURRENT_BRANCH" = "main" ] || [ "$CURRENT_BRANCH" = "master" ] && echo "ERROR: Already on main" && exit 1

# Verify clean working directory
git diff-index --quiet HEAD -- || { echo "ERROR: Uncommitted changes"; git status --short; exit 1; }

echo "✅ On branch: $CURRENT_BRANCH (clean)"
```

### Step 2: Create Backup and Pull Main

```bash
BACKUP_BRANCH="${CURRENT_BRANCH}-pre-merge-backup"
git branch -f "$BACKUP_BRANCH"
echo "✅ Created backup: $BACKUP_BRANCH"

git fetch origin main:main
echo "✅ Pulled latest main from remote"
echo ""
git log --oneline "$CURRENT_BRANCH"..main
```

### Step 3: Merge Main

```bash
HAD_CONFLICTS=false

if git merge -X ours main -m "Merge main into $CURRENT_BRANCH (prefer current branch on conflicts)"; then
  echo "✅ Clean merge - no conflicts"
else
  echo "⚠️  Conflicts detected - resolving with current branch version"
  HAD_CONFLICTS=true

  # Auto-resolve by keeping current branch version
  for file in $(git diff --name-only --diff-filter=U); do
    echo "  Resolving $file: keeping current branch version"
    git checkout --ours "$file"
    git add "$file"
  done

  git commit --no-edit
  echo "✅ Conflicts resolved"
fi

MERGE_COMMIT=$(git rev-parse HEAD)
echo "Merge commit: $MERGE_COMMIT"
```

### Step 4: Conditional Testing

```bash
if [ "$HAD_CONFLICTS" = "true" ]; then
  echo "⚠️  Running quick validation (had conflicts)..."

  if [ -f "package.json" ] && grep -q "\"test\"" package.json; then
    npm test
  elif [ -f "Cargo.toml" ]; then
    cargo check
  elif [ -f "go.mod" ]; then
    go build ./...
  else
    git status
  fi
else
  echo "✅ Skipping tests (clean merge, CI will validate)"
  git status
fi
```

### Step 5: Prompt Before Push

Use AskUserQuestion:

**Question:** "Ready to push merge commit to origin/{current_branch}?"

**Show summary:**
```
✅ Merged main into {current_branch}
- Commit: {merge_commit}
- Backup: {backup_branch}
- Conflicts: {count or "none"}
- Tests: {ran or "skipped (clean merge)"}
```

**Options:**
- "Yes, push now (Recommended)"
- "No, review locally first"

### Step 6: Push (if approved)

```bash
git push origin "$CURRENT_BRANCH"
echo "✅ Pushed to origin/$CURRENT_BRANCH"
```

### Step 7: Verify and Cleanup

Use AskUserQuestion:

**Question:** "Verify CI is passing. Delete backup branch?"

**Options:**
- "Yes, all good - delete backup (Recommended)"
- "No, keep backup"

If yes:
```bash
git branch -D "$BACKUP_BRANCH"
echo "✅ Merge complete!"
```

If no:
```
Keeping backup: {backup_branch}
Restore with: git reset --hard {backup_branch}
```

## Safety Rules

- Never rebase, only merge
- Never force-push automatically
- Always create backup before merging
- Always prefer current branch on conflicts (`-X ours`)
- Only delete backup after user confirms

## Error Recovery

If anything fails:
```bash
git merge --abort  # if merge in progress
git reset --hard "$BACKUP_BRANCH"
```

The backup branch is your safety net.
