#!/usr/bin/env bash
# Usage: add_reviewer.sh <pr_number> <username[,username2,...]>
#
# 指定した PR にレビュー依頼を追加する.
# 複数のユーザーをカンマ区切りで指定できる.

set -euo pipefail

if [[ $# -lt 2 ]]; then
    echo "Usage: add_reviewer.sh <pr_number> <username[,username2,...]>" >&2
    exit 1
fi

PR_NUMBER="$1"
# gh コマンドが操作するリポジトリを "owner/repo" 形式で取得する.
REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')

# カンマ区切りのユーザー名を配列に展開し, GitHub API のフィールド形式に変換する.
IFS=',' read -ra REVIEWERS <<< "$2"
FIELDS=()
for r in "${REVIEWERS[@]}"; do
    FIELDS+=(-f "reviewers[]=${r// /}")
done

# GitHub API でレビュー依頼を追加し, 依頼したユーザー名を出力する.
gh api "repos/${REPO}/pulls/${PR_NUMBER}/requested_reviewers" \
    --method POST "${FIELDS[@]}" --jq '.requested_reviewers[].login'
