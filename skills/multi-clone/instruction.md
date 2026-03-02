# Multi-Clone: Parallel Agent Workspace Setup

Clone a GitHub repository multiple times into numbered folders so you can run independent agents in each.

## Step 1: Ask for Inputs

Use AskUserQuestion to ask the user **two questions in a single prompt**:

1. **GitHub repository URL** — the HTTPS clone URL (e.g., `https://github.com/getsentry/sentry-docs.git`)
2. **Number of clones** — how many copies to create. Options: 3, 5 (Recommended), 7, or custom.

## Step 2: Extract Repository Name and Set Up Paths

From the URL, extract the repository name:
- `https://github.com/getsentry/sentry-docs.git` -> `sentry-docs`
- `https://github.com/getsentry/sentry-docs` -> `sentry-docs` (handle missing `.git` suffix)

Set the paths:
- **Parent directory**: `{current_working_directory}/{repo-name}/`
- **Clone directories**: `{parent}/{repo-name}-0`, `{parent}/{repo-name}-1`, ..., `{parent}/{repo-name}-{N-1}`

## Step 3: Validate

Before cloning, check:
1. The parent directory does NOT already exist. If it does, inform the user and ask whether to proceed (skip existing folders) or abort.
2. The URL looks like a valid GitHub URL.

## Step 4: Create Parent Directory

```bash
mkdir -p {parent_directory}
```

## Step 5: Clone in Parallel

Run ALL `git clone` commands in parallel using background tasks:

```bash
git clone {url} {parent}/{repo-name}-0
git clone {url} {parent}/{repo-name}-1
# ... up to N-1
```

Wait for all clones to complete and verify each succeeded.

## Step 6: Verify and Report

List the created directories and confirm all clones succeeded:

```bash
ls -d {parent}/{repo-name}-*/
```

Output a summary:

```
Created {N} clones in {parent}/:
  {repo-name}-0/
  {repo-name}-1/
  ...
  {repo-name}-{N-1}/

Navigate into any folder to start working:
  cd {parent}/{repo-name}-0
```

## Error Handling

- If a clone fails, report which ones failed and which succeeded.
- Do NOT retry failed clones automatically — inform the user and let them decide.
- Do NOT delete partially cloned directories without asking.

## Safety Constraints

- Never force-push or run destructive git operations.
- Never modify existing repositories.
- Only create new directories and clone into them.
