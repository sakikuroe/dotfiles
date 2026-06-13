#!/usr/bin/env bash
# Install agents/skills as symlinks into ~/.claude/skills/ (global) or .claude/skills/ (project).
# In --project mode, also symlinks agents/CLAUDE.md to <project>/.claude/CLAUDE.md if it does
# not already exist, as a pointer to help Claude/Codex use the installed skills reliably.
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

link_or_skip() {
    local src="$1" target="$2" name="$3"

    if [[ -e "$target" || -L "$target" ]]; then
        echo "skip:   $name (already exists at $target)"
        skipped=$((skipped + 1))
    else
        ln -s "$src" "$target"
        echo "linked: $name -> $target"
        linked=$((linked + 1))
    fi
}

for skill_src in "$SKILLS_SRC"/*/; do
    [[ -d "$skill_src" ]] || continue
    skill_name="$(basename "$skill_src")"
    link_or_skip "$skill_src" "$TARGET_DIR/$skill_name" "$skill_name"
done

if [[ "${1:-}" == "--project" ]]; then
    link_or_skip "$SCRIPT_DIR/CLAUDE.md" "$(pwd)/.claude/CLAUDE.md" "CLAUDE.md"
fi

echo ""
echo "scope: $scope"
echo "linked: $linked  skipped: $skipped"
