#!/usr/bin/env bash
# Usage: reply_review.sh <pr_number> <review_node_id> <body_file> <commit_hash|->
#
# 指定したレビューの本文を引用ブロックとして付けたうえで、
# <body_file> の内容を返答コメントとして投稿する。
# 返答本文の末尾に署名 `*This comment was posted by AI Agent.*` を自動付加する。
# commit_hash にハッシュ値を渡すと、該当コミットの URL を署名直前に挿入する。
# 採用時は、該当指摘への対応を含むコミットを明示的に指定すること。
# 非採用などコミット URL が不要な場合は `-` を渡すことで挿入をスキップする。
#
# 本文はファイル経由で渡す (--body-file 相当)。ヒアドキュメントでの
# バッククォートエスケープ事故を避けるための設計。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $# -lt 4 ]]; then
    echo "Usage: reply_review.sh <pr_number> <review_node_id> <body_file> <commit_hash|->" >&2
    exit 1
fi

PR_NUMBER="$1"
REVIEW_NODE_ID="$2"
BODY_FILE="$3"
COMMIT_ARG="$4"

if [[ ! -f "$BODY_FILE" ]]; then
    echo "Error: body file not found: $BODY_FILE" >&2
    exit 1
fi

REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')

# レビューの存在を確認する。
REVIEW_EXISTS=$(gh pr view "$PR_NUMBER" --json reviews \
    --jq ".reviews[] | select(.id == \"$REVIEW_NODE_ID\") | .id")
if [[ -z "$REVIEW_EXISTS" ]]; then
    echo "Error: review not found (id: $REVIEW_NODE_ID)" >&2
    exit 1
fi

# レビュー本文を取得する (本文なし APPROVE などで空になることがある)。
REVIEW_BODY=$(gh pr view "$PR_NUMBER" --json reviews \
    --jq ".reviews[] | select(.id == \"$REVIEW_NODE_ID\") | .body")

# 引用ブロック (あれば) + 空行 + 返答本文 を一時ファイルに組み立てる。
SEND_FILE=$(mktemp)
trap 'rm -f "$SEND_FILE"' EXIT

if [[ -n "$REVIEW_BODY" ]]; then
    echo "$REVIEW_BODY" | sed 's/^/> /' >> "$SEND_FILE"
    echo "" >> "$SEND_FILE"
fi
cat "$BODY_FILE" >> "$SEND_FILE"

# 署名を自動追加
SIG_FILE=$(mktemp)
trap 'rm -f "$SIG_FILE" "$FINAL_FILE"' EXIT
bash "${SCRIPT_DIR}/_append_signature.sh" "$SEND_FILE" > "$SIG_FILE"

# commit URL を署名直前に挿入 ("-" の場合はスキップ)
FINAL_FILE="$SIG_FILE"
if [[ "$COMMIT_ARG" != "-" ]]; then
    if ! COMMIT_SHA=$(git rev-parse "$COMMIT_ARG" 2>/dev/null); then
        echo "Error: コミットが見つかりません: $COMMIT_ARG" >&2
        exit 1
    fi
    COMMIT_SHORT=$(git rev-parse --short "$COMMIT_ARG")
    COMMIT_LINE="反映コミット: [\`${COMMIT_SHORT}\`](https://github.com/${REPO}/commit/${COMMIT_SHA})"
    SIGNATURE='*This comment was posted by AI Agent.*'

    FINAL_FILE=$(mktemp)
    awk -v commit="$COMMIT_LINE" -v sig="$SIGNATURE" '
        $0 == sig && !inserted {
            print commit
            print ""
            inserted = 1
        }
        { print }
        END {
            if (!inserted) {
                print ""
                print commit
            }
        }
    ' "$SIG_FILE" > "$FINAL_FILE"
fi

# PR コメントとして投稿する。
gh pr comment "$PR_NUMBER" --body-file "$FINAL_FILE"
