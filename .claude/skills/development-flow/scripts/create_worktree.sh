#!/usr/bin/env bash
# Usage: create_worktree.sh <branch_name>
#
# Creates a branch (if not already existing) and a worktree at the standard path:
#   ~/.worktrees/<repo>-<branch-with-slashes-as-dashes>

set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: create_worktree.sh <branch_name>" >&2
    exit 1
fi

BRANCH="$1"
# worktree 内から実行された場合でも正しいリポジトリ名を得るため,
# --show-toplevel ではなく worktree list の先頭行 (メイン worktree) を使う.
REPO_NAME=$(basename "$(git worktree list --porcelain | awk 'NR==1{print $2}')")
BRANCH_SAFE="${BRANCH//\//-}"
WORKTREE_PATH="$HOME/.worktrees/${REPO_NAME}-${BRANCH_SAFE}"

echo "branch:  $BRANCH"
echo "worktree: $WORKTREE_PATH"

# Worktree already exists
if git worktree list --porcelain | grep -q "^worktree $WORKTREE_PATH$"; then
    echo "already exists — reusing"
    exit 0
fi

git fetch origin --prune

BRANCH_LOCAL=$(git branch --list "$BRANCH")
BRANCH_REMOTE=$(git ls-remote --heads origin "$BRANCH" | wc -l)

mkdir -p "$(dirname "$WORKTREE_PATH")"

if [[ -n "$BRANCH_LOCAL" ]]; then
    echo "using existing local branch"
    git worktree add "$WORKTREE_PATH" "$BRANCH"
elif [[ "$BRANCH_REMOTE" -gt 0 ]]; then
    echo "tracking remote branch"
    git worktree add --track -b "$BRANCH" "$WORKTREE_PATH" "origin/$BRANCH"
else
    DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
    DEFAULT_BRANCH="${DEFAULT_BRANCH:-main}"
    echo "creating new branch from origin/$DEFAULT_BRANCH"
    git worktree add -b "$BRANCH" "$WORKTREE_PATH" "origin/$DEFAULT_BRANCH"
fi

echo "done: $WORKTREE_PATH"
