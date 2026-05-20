#!/usr/bin/env bash
# Install agents/skills as symlinks into ~/.claude/skills/ (global) or .claude/skills/ (project).
#
# Usage:
#   ./agents/install.sh            # install to ~/.claude/skills/ (global)
#   ./agents/install.sh --project  # install to ./.claude/skills/ (current project)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="$SCRIPT_DIR/skills"

if [[ "${1:-}" == "--project" ]]; then
    TARGET_DIR="$(pwd)/.claude/skills"
    scope="project ($(pwd))"
else
    TARGET_DIR="$HOME/.claude/skills"
    scope="global (~/.claude/skills)"
fi

mkdir -p "$TARGET_DIR"

linked=0
skipped=0

for skill_src in "$SKILLS_SRC"/*/; do
    [[ -d "$skill_src" ]] || continue
    skill_name="$(basename "$skill_src")"
    target="$TARGET_DIR/$skill_name"

    if [[ -e "$target" || -L "$target" ]]; then
        echo "skip:   $skill_name (already exists at $target)"
        skipped=$((skipped + 1))
    else
        ln -s "$skill_src" "$target"
        echo "linked: $skill_name -> $target"
        linked=$((linked + 1))
    fi
done

echo ""
echo "scope: $scope"
echo "linked: $linked  skipped: $skipped"
