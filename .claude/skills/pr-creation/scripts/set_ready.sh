#!/usr/bin/env bash
# Usage: set_ready.sh <pr_number>
#
# draft PR を ready for review に切り替える。
# gh pr ready と異なり GitHub API を直接呼ぶため、gh の認証スコープに依存しにくい。

set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: set_ready.sh <pr_number>" >&2
    exit 1
fi

PR_NUMBER="$1"
# gh コマンドが操作するリポジトリを "owner/repo" 形式で取得する。
REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')

# PR の draft フラグを false に更新し、結果を "ready" または "still draft" で出力する。
gh api "repos/${REPO}/pulls/${PR_NUMBER}" \
    --method PATCH -F draft=false --jq '.draft | if . then "still draft" else "ready" end'
