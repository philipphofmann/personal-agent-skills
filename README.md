# Personal Agent Skills

A collection of reusable Claude Code CLI skills for automating recurring engineering workflows.

## Overview

This repository contains independent skills that can be invoked via the Claude Code CLI. Each skill automates a specific workflow and follows a consistent structure.

## Structure

```
personal-agent-skills/
├── README.md
├── bin/
│   └── sync-skills.sh          # Sync skills to Claude Code
└── skills/
    └── <skill-name>/
        ├── skill.json          # Skill metadata and configuration
        ├── instruction.md      # The actual prompt/instructions for Claude
        └── README.md           # Human-readable documentation
```

## Available Skills

- **daily_pr_review_sentry_cocoa_sdk**: Overview of easy-to-approve PRs for the Sentry Cocoa SDK
- **stacked-pr-merge-main**: Safely merge main into feature branch created from another merged branch, preferring current branch on conflicts

## Setup

Sync all skills to Claude Code (one-time setup):

```bash
./bin/sync-skills.sh
```

This creates symlinks in `~/.claude/skills/` for all skills in this repo. Run it again when you add new skills.

## Usage

See **[USAGE.md](USAGE.md)** for detailed instructions.

**Quick Start:**

```bash
# Start Claude Code
claude

# Use a skill directly (after running sync-skills.sh)
> /stacked-pr-merge-main
> /daily_pr_review_sentry_cocoa_sdk
```

**Alternative:** Execute by file path or copy-paste the `instruction.md` content.

Refer to individual skill READMEs for specific usage instructions.

## Design Principles

- **Read-only by default**: Skills should be informational unless explicitly designed for modification
- **Safety first**: No destructive operations without clear confirmation
- **Clarity over cleverness**: Simple, understandable logic
- **Reusable**: Skills should work across different contexts where applicable
