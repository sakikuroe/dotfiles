#!/usr/bin/env bash
# Usage: reply_review.sh <pr_number> <review_node_id> <body_file>
#
# 指定したレビューの本文を引用ブロックとして付けたうえで,
# <body_file> の内容を返答コメントとして投稿する.
#
# 本文はファイル経由で渡す (--body-file 相当). ヒアドキュメントでの
# バッククォートエスケープ事故を避けるための設計.

set -euo pipefail

if [[ $# -lt 3 ]]; then
    echo "Usage: reply_review.sh <pr_number> <review_node_id> <body_file>" >&2
    exit 1
fi

PR_NUMBER="$1"
REVIEW_NODE_ID="$2"
BODY_FILE="$3"

if [[ ! -f "$BODY_FILE" ]]; then
    echo "Error: body file not found: $BODY_FILE" >&2
    exit 1
fi

# レビュー本文を取得する.
REVIEW_BODY=$(gh pr view "$PR_NUMBER" --json reviews \
    --jq ".reviews[] | select(.id == \"$REVIEW_NODE_ID\") | .body")

if [[ -z "$REVIEW_BODY" ]]; then
    echo "Error: review not found (id: $REVIEW_NODE_ID)" >&2
    exit 1
fi

# 引用ブロック + 空行 + 返答本文 を一時ファイルに組み立てる.
SEND_FILE=$(mktemp)
trap 'rm -f "$SEND_FILE"' EXIT

echo "$REVIEW_BODY" | sed 's/^/> /' > "$SEND_FILE"
echo "" >> "$SEND_FILE"
cat "$BODY_FILE" >> "$SEND_FILE"

# PR コメントとして投稿する.
gh pr comment "$PR_NUMBER" --body-file "$SEND_FILE"
