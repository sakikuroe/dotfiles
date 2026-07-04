#!/usr/bin/env bash
# Usage: reply_comment.sh <pr_number> <comment_id> <body_file>
#
# 指定した通常の PR コメント (issue コメント) の本文を引用ブロックとして
# 付けたうえで、<body_file> の内容を返答コメントとして投稿する。
# 返答本文の末尾に署名 `*This comment was posted by AI Agent.*` を自動付加する。
#
# GitHub の issue コメントはスレッド構造を持たないため、reply_inline.sh の
# ような返信 API ではなく、reply_review.sh と同様に引用付きの新規コメント
# 投稿という形で「返答」を表現する。
#
# 本文はファイル経由で渡す (--body-file 相当)。ヒアドキュメントでの
# バッククォートエスケープ事故を避けるための設計。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $# -lt 3 ]]; then
    echo "Usage: reply_comment.sh <pr_number> <comment_id> <body_file>" >&2
    exit 1
fi

PR_NUMBER="$1"
COMMENT_ID="$2"
BODY_FILE="$3"

if [[ ! -f "$BODY_FILE" ]]; then
    echo "Error: body file not found: $BODY_FILE" >&2
    exit 1
fi

REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')

# コメントの存在を確認し、本文を取得する。
COMMENT_BODY=$(gh api "repos/${REPO}/issues/comments/${COMMENT_ID}" --jq '.body' 2>/dev/null) || {
    echo "Error: comment not found (id: $COMMENT_ID)" >&2
    exit 1
}

# 引用ブロック + 空行 + 返答本文 を一時ファイルに組み立てる。
SEND_FILE=$(mktemp)
trap 'rm -f "$SEND_FILE"' EXIT

echo "$COMMENT_BODY" | sed 's/^/> /' >> "$SEND_FILE"
echo "" >> "$SEND_FILE"
cat "$BODY_FILE" >> "$SEND_FILE"

# 署名を自動追加
FINAL_FILE=$(mktemp)
trap 'rm -f "$SEND_FILE" "$FINAL_FILE"' EXIT
bash "${SCRIPT_DIR}/_append_signature.sh" "$SEND_FILE" > "$FINAL_FILE"

# PR コメントとして投稿する。
gh pr comment "$PR_NUMBER" --body-file "$FINAL_FILE"
