#!/usr/bin/env bash
# Usage: cleanup.sh <pr_number> [--yes]
#
# マージ後の後処理を正しい順序で実行する。
#   1. リモートブランチを削除する
#   2. worktree を削除する
#   3. ローカルブランチを削除する
#   4. default branch を origin と同期する
#
# --yes: リモートブランチ削除の確認プロンプトをスキップする

set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: cleanup.sh <pr_number> [--yes]" >&2
    exit 1
fi

PR_NUMBER="$1"
# --yes が指定された場合は対話確認をスキップする。
AUTO_YES=false
[[ "${2:-}" == "--yes" ]] && AUTO_YES=true

# PR がマージ済みであることを確認する。未マージの場合は後処理を行わずに終了する。
PR_STATE=$(gh pr view "$PR_NUMBER" --json state --jq '.state')
if [[ "$PR_STATE" != "MERGED" ]]; then
    echo "Error: PR #$PR_NUMBER is not merged (state: $PR_STATE)" >&2
    exit 1
fi

# PR のブランチ名を取得し、worktree パスを算出する。
# スラッシュをハイフンに置換して、ファイルシステムで安全なパスを生成する。
BRANCH=$(gh pr view "$PR_NUMBER" --json headRefName --jq '.headRefName')
# worktree 内から実行された場合でも正しいリポジトリ名を得るため、
# --show-toplevel ではなく worktree list の先頭行 (メイン worktree) を使う。
MAIN_REPO=$(git worktree list --porcelain | awk 'NR==1{print $2}')
REPO_NAME=$(basename "$MAIN_REPO")
BRANCH_SAFE="${BRANCH//\//-}"
WORKTREE_PATH="$HOME/.worktrees/${REPO_NAME}-${BRANCH_SAFE}"

echo "branch:   $BRANCH"
echo "worktree: $WORKTREE_PATH"
echo ""

# 1. リモートブランチを削除する。
# --yes が指定されていない場合はユーザーに確認を取る。
echo "=== 1/4 remote branch ==="
if git ls-remote --exit-code origin "$BRANCH" &>/dev/null; then
    if [[ "$AUTO_YES" == false ]]; then
        read -rp "Delete remote branch '$BRANCH'? [y/N] " confirm
        if [[ "${confirm,,}" != "y" ]]; then
            echo "skipped"
        else
            git push origin --delete "$BRANCH"
            echo "deleted"
        fi
    else
        git push origin --delete "$BRANCH"
        echo "deleted"
    fi
else
    echo "already deleted"
fi

# 2. worktree を削除する。
# 未コミットの変更がある場合は誤って消さないよう中断する。
# worktree 削除後はカレントディレクトリが消えるため、先にメインリポジトリへ移動する。
echo ""
echo "=== 2/4 worktree ==="
if git worktree list --porcelain | grep -q "^worktree $WORKTREE_PATH$"; then
    if ! git -C "$WORKTREE_PATH" diff --quiet 2>/dev/null \
        || ! git -C "$WORKTREE_PATH" diff --cached --quiet 2>/dev/null; then
        echo "Error: worktree has uncommitted changes. Aborting." >&2
        exit 1
    fi
    cd "$MAIN_REPO"
    git worktree remove "$WORKTREE_PATH"
    echo "removed"
else
    echo "not found (already removed or path differs)"
fi

# 3. ローカルブランチを削除する。
# 現在そのブランチにいる場合は先に default branch へ移動が必要なため中断する。
echo ""
echo "=== 3/4 local branch ==="
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$CURRENT_BRANCH" == "$BRANCH" ]]; then
    echo "Error: currently on $BRANCH. Switch to the default branch first." >&2
    exit 1
fi
if git branch --list "$BRANCH" | grep -q .; then
    # マージ済みブランチは -d で削除できるが、念のため失敗時は -D にフォールバックする。
    git branch -d "$BRANCH" 2>/dev/null \
        || { echo "Warning: -d failed, using -D"; git branch -D "$BRANCH"; }
    echo "deleted"
else
    echo "already deleted"
fi

# 4. default branch を origin と同期する。
echo ""
echo "=== 4/4 sync default branch ==="
git fetch origin --prune
git pull --ff-only
echo "done"

echo ""
echo "cleanup complete."
