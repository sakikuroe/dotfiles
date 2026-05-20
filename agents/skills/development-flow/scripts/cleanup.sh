#!/usr/bin/env bash
# Usage: cleanup.sh <pr_number>
#
# Post-merge cleanup in the correct order:
#   1. Delete remote branch
#   2. Remove worktree
#   3. Delete local branch
#   4. Sync main with origin/main

set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: cleanup.sh <pr_number>" >&2
    exit 1
fi

PR_NUMBER="$1"

PR_STATE=$(gh pr view "$PR_NUMBER" --json state --jq '.state')
if [[ "$PR_STATE" != "MERGED" ]]; then
    echo "Error: PR #$PR_NUMBER is not merged (state: $PR_STATE)" >&2
    exit 1
fi

BRANCH=$(gh pr view "$PR_NUMBER" --json headRefName --jq '.headRefName')
REPO_NAME=$(basename "$(git rev-parse --show-toplevel)")
BRANCH_SAFE="${BRANCH//\//-}"
WORKTREE_PATH="$HOME/.worktrees/${REPO_NAME}-${BRANCH_SAFE}"

echo "branch:   $BRANCH"
echo "worktree: $WORKTREE_PATH"
echo ""

# 1. Delete remote branch
echo "=== 1/4 remote branch ==="
if git ls-remote --exit-code origin "$BRANCH" &>/dev/null; then
    git push origin --delete "$BRANCH"
    echo "deleted"
else
    echo "already deleted"
fi

# 2. Remove worktree
echo ""
echo "=== 2/4 worktree ==="
if git worktree list --porcelain | grep -q "^worktree $WORKTREE_PATH$"; then
    if ! git -C "$WORKTREE_PATH" diff --quiet 2>/dev/null \
        || ! git -C "$WORKTREE_PATH" diff --cached --quiet 2>/dev/null; then
        echo "Error: worktree has uncommitted changes. Aborting." >&2
        exit 1
    fi
    git worktree remove "$WORKTREE_PATH"
    echo "removed"
else
    echo "not found (already removed or path differs)"
fi

# 3. Delete local branch
echo ""
echo "=== 3/4 local branch ==="
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$CURRENT_BRANCH" == "$BRANCH" ]]; then
    echo "Error: currently on $BRANCH. Switch to main first." >&2
    exit 1
fi
if git branch --list "$BRANCH" | grep -q .; then
    git branch -d "$BRANCH" 2>/dev/null \
        || { echo "Warning: -d failed, using -D"; git branch -D "$BRANCH"; }
    echo "deleted"
else
    echo "already deleted"
fi

# 4. Sync main
echo ""
echo "=== 4/4 sync main ==="
git fetch origin --prune
git pull --ff-only
echo "done"

echo ""
echo "cleanup complete."
