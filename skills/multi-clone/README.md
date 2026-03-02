# Multi-Clone: Parallel Agent Workspace Setup

Clone a GitHub repository multiple times into numbered folders for parallel agent work.

## Use Case

You want to run multiple Claude Code agents simultaneously on the same repository, each in its own isolated working copy.

## What It Does

1. Asks for a GitHub repository URL and number of clones
2. Extracts the repo name from the URL
3. Creates a parent folder named after the repo
4. Clones the repo N times into `{repo-name}-0`, `{repo-name}-1`, ..., `{repo-name}-{N-1}`
5. Runs all clones in parallel

## Example

```
Input:
  URL: https://github.com/getsentry/sentry-docs.git
  Count: 5

Result:
  sentry-docs/
  ├── sentry-docs-0/
  ├── sentry-docs-1/
  ├── sentry-docs-2/
  ├── sentry-docs-3/
  └── sentry-docs-4/
```

## Usage

```bash
claude

> /multi-clone
```

## Requirements

- `git` installed and configured
- Network access to clone from GitHub
