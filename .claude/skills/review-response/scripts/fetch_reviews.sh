#!/usr/bin/env bash
# Usage: fetch_reviews.sh <pr_number>
#
# PR の状態 / 全体レビュー / インライン review comment を 1 回で取得し,
# 統合した JSON を出力する.
#
# gh pr view --json reviews にはインライン review comment が含まれない.
# 別 API (`gh api .../pulls/<N>/comments`) を併用しないと取りこぼすため,
# このスクリプトで両者を 1 コマンドにまとめている.
#
# 出力フィールド:
#   state, isDraft, reviewDecision, mergeable, mergeStateStatus
#   checks           : statusCheckRollup の配列
#   reviews          : 全体レビュー (id, state, body, submittedAt, author)
#   inline_comments  : インライン comment (id, in_reply_to_id, path, line,
#                       original_line, original_commit_id, body, user)

set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: fetch_reviews.sh <pr_number>" >&2
    exit 1
fi

PR_NUMBER="$1"
REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')

# 全体状態 + 全体レビュー一覧
PR_INFO=$(gh pr view "$PR_NUMBER" \
    --json state,isDraft,reviewDecision,mergeable,mergeStateStatus,statusCheckRollup,reviews)

# インライン review comment 一覧
INLINE=$(gh api "repos/${REPO}/pulls/${PR_NUMBER}/comments")

# 両者を統合した JSON を出力
jq -n --argjson pr "$PR_INFO" --argjson inline "$INLINE" '{
    state: $pr.state,
    isDraft: $pr.isDraft,
    reviewDecision: $pr.reviewDecision,
    mergeable: $pr.mergeable,
    mergeStateStatus: $pr.mergeStateStatus,
    checks: $pr.statusCheckRollup,
    reviews: ($pr.reviews | map({
        id, state, body, submittedAt,
        author: .author.login
    })),
    inline_comments: ($inline | map({
        id, in_reply_to_id, path, line,
        original_line, original_start_line, original_commit_id, body,
        user: .user.login
    }))
}'
