# Using Personal Agent Skills with Claude Code

This guide explains how to use skills from this repository with the Claude Code CLI.

## Quick Start

### Method 1: Copy-Paste Instructions (Simplest)

1. Navigate to the skill directory:
   ```bash
   cd skills/daily_pr_review_sentry_cocoa_sdk
   ```

2. Open `instruction.md` and copy its contents

3. In your Claude Code session, paste the instructions

4. Claude will execute the skill

### Method 2: Reference from Claude Code

If you're in a Claude Code session:

```
Please execute the skill at /Users/philipp.hofmann/git-repos/personal-agent-skills/skills/daily_pr_review_sentry_cocoa_sdk/instruction.md
```

Claude will read and execute the instruction file.

### Method 3: Register as a Claude Code Skill (Advanced)

If you want to invoke skills with a short command like `/daily_pr_review`:

1. Check if Claude Code supports custom skill registration in your settings
2. Add the skill path to your configuration
3. Invoke with `/daily_pr_review_sentry_cocoa_sdk`

(Note: This depends on your Claude Code CLI configuration capabilities)

## Understanding Skill Structure

Each skill has three files:

### `skill.json`
Metadata about the skill:
- Name, version, description
- Required tools and permissions
- Configuration parameters
- Safety constraints

**You don't usually need to read this file** - it's for documentation and potential automation.

### `instruction.md`
The actual prompt that Claude executes. This is the **core of the skill**.

**This is what you copy-paste or reference** when running the skill manually.

### `README.md`
Human-readable documentation:
- What the skill does
- How to use it
- Requirements
- Example output
- Troubleshooting

**Read this first** to understand the skill before running it.

## Running Skills

### Interactive Mode

Most skills are designed to be run interactively:

1. Start Claude Code CLI:
   ```bash
   claude
   ```

2. Load the skill:
   ```
   Execute the daily PR review skill from /Users/philipp.hofmann/git-repos/personal-agent-skills/skills/daily_pr_review_sentry_cocoa_sdk/instruction.md
   ```

3. Claude will execute the steps in `instruction.md`

### Non-Interactive Mode

Some skills can be run non-interactively by:

1. Extracting the shell commands from `instruction.md`
2. Running them directly in your terminal
3. Feeding the output to Claude for analysis

Example:
```bash
# Extract PR data
gh pr list --repo getsentry/sentry-cocoa --state open --json number,title,url,author,isDraft,reviews,files,additions,deletions,labels > /tmp/prs.json

# Ask Claude to analyze
claude "Analyze this PR data according to the daily_pr_review_sentry_cocoa_sdk skill" < /tmp/prs.json
```

## Creating Your Own Skills

To create a new skill:

1. Create a directory under `skills/`:
   ```bash
   mkdir skills/my-new-skill
   ```

2. Create the three required files:
   ```bash
   touch skills/my-new-skill/skill.json
   touch skills/my-new-skill/instruction.md
   touch skills/my-new-skill/README.md
   ```

3. Use an existing skill as a template

4. Test your skill following the patterns in existing `TESTING.md` files

### Skill Design Best Practices

- **Be explicit**: State exactly what Claude should do, step by step
- **Include examples**: Show expected output formats
- **Set boundaries**: Clearly state what NOT to do (safety constraints)
- **Use real tools**: Reference actual CLI commands (gh, git, etc.)
- **Stay deterministic**: Prefer concrete criteria over subjective judgment
- **Read-only by default**: Make skills informational unless modification is required

## Troubleshooting

### "Skill not found"

Ensure the path is correct:
```bash
ls -la /Users/philipp.hofmann/git-repos/personal-agent-skills/skills/
```

### "Permission denied"

Check file permissions:
```bash
chmod +r skills/*/instruction.md
```

### "Command not found" (e.g., `gh`)

Install required tools:
```bash
brew install gh  # For GitHub CLI
```

### "Claude doesn't follow the instructions"

- Ensure `instruction.md` is clear and unambiguous
- Break complex tasks into smaller steps
- Add more examples of expected output
- Test with simpler inputs first

## Tips

1. **Read the README first**: Each skill has specific requirements and usage notes

2. **Check prerequisites**: Ensure you have required tools installed (gh, git, etc.)

3. **Understand safety constraints**: Know what the skill will and won't do

4. **Start simple**: Test skills with simple inputs before complex scenarios

5. **Customize as needed**: Skills are templates - adjust them for your workflow

6. **Chain skills**: Use the output of one skill as input to another

7. **Keep skills focused**: One skill should do one thing well

## Examples

### Example 1: Daily PR Review

```bash
# Start Claude
claude

# In Claude session
> Execute /Users/philipp.hofmann/git-repos/personal-agent-skills/skills/daily_pr_review_sentry_cocoa_sdk/instruction.md

# Claude will:
# 1. Query open PRs
# 2. Filter by criteria
# 3. Rank by ease of approval
# 4. Output a scannable list
```

### Example 2: Chain Multiple Skills

```bash
# Run PR review skill to get easy PRs
> Execute daily_pr_review_sentry_cocoa_sdk

# Then use output to prioritize work
> Based on these results, create a prioritized task list for today
```

## Additional Resources

- [Claude Code Documentation](https://docs.anthropic.com/claude-code)
- [GitHub CLI Documentation](https://cli.github.com/manual/)
- Individual skill READMEs in `skills/*/README.md`

## Support

For issues with:
- **Skills in this repo**: Check the skill's README and TESTING.md
- **Claude Code CLI**: See [Claude Code Issues](https://github.com/anthropics/claude-code/issues)
- **GitHub CLI**: See [GitHub CLI Docs](https://cli.github.com/manual/)
