# Personal Agent Skills

A collection of reusable Claude Code CLI skills for automating recurring engineering workflows.

## Overview

This repository contains independent skills that can be invoked via the Claude Code CLI. Each skill automates a specific workflow and follows a consistent structure.

## Structure

```
personal-agent-skills/
├── README.md
└── skills/
    └── <skill-name>/
        ├── skill.json          # Skill metadata and configuration
        ├── instruction.md      # The actual prompt/instructions for Claude
        └── README.md           # Human-readable documentation
```

## Available Skills

- **daily_pr_review_sentry_cocoa_sdk**: Overview of easy-to-approve PRs for the Sentry Cocoa SDK

## Usage

See **[USAGE.md](USAGE.md)** for detailed instructions on running skills.

**Quick Start:**

```bash
# Start Claude Code
claude

# In Claude session, execute a skill
> Execute the skill at /path/to/personal-agent-skills/skills/daily_pr_review_sentry_cocoa_sdk/instruction.md
```

Or simply copy the contents of `instruction.md` and paste into Claude Code.

Refer to individual skill READMEs for specific usage instructions.

## Design Principles

- **Read-only by default**: Skills should be informational unless explicitly designed for modification
- **Safety first**: No destructive operations without clear confirmation
- **Clarity over cleverness**: Simple, understandable logic
- **Reusable**: Skills should work across different contexts where applicable
