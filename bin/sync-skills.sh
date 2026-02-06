#!/bin/bash
# Sync all skills from this repo to Claude Code's skills directory
# Usage: ./bin/sync-skills.sh

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_SOURCE="$REPO_ROOT/skills"
SKILLS_TARGET="$HOME/.claude/skills"

echo "Syncing skills from: $SKILLS_SOURCE"
echo "To: $SKILLS_TARGET"
echo ""

# Create target directory if it doesn't exist
mkdir -p "$SKILLS_TARGET"

# Symlink each skill
for skill_path in "$SKILLS_SOURCE"/*; do
  if [ -d "$skill_path" ]; then
    skill_name=$(basename "$skill_path")
    target="$SKILLS_TARGET/$skill_name"

    if [ -L "$target" ]; then
      echo "✓ $skill_name (already linked)"
    else
      ln -sf "$skill_path" "$target"
      echo "✅ $skill_name (linked)"
    fi
  fi
done

echo ""
echo "Done! Available skills:"
ls -1 "$SKILLS_TARGET"
