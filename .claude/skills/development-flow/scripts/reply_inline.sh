#!/usr/bin/env bash
# Usage: reply_inline.sh <pr_number> <comment_id> <body_file> <commit_hash|->
#
# PR のインライン review comment に返答を投稿する.
# 本文ファイルの末尾に署名 `*This comment was posted by AI Agent.*` を自動付加する.
# commit_hash にハッシュ値を渡すと, 該当コミットの URL を署名直前に挿入する.
# 採用時は, 該当指摘への対応を含むコミットを明示的に指定すること.
# 非採用などコミット URL が不要な場合は `-` を渡すことで挿入をスキップする.
# 署名が見つからない場合は本文末尾に追加する.
#
# 本文はファイル経由で渡す (--body-file 相当). ヒアドキュメントでの
# バッククォートエスケープ事故を避けるための設計.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $# -lt 4 ]]; then
    echo "Usage: reply_inline.sh <pr_number> <comment_id> <body_file> <commit_hash|->" >&2
    exit 1
fi

PR_NUMBER="$1"
COMMENT_ID="$2"
BODY_FILE="$3"
COMMIT_ARG="$4"

if [[ ! -f "$BODY_FILE" ]]; then
    echo "Error: body file not found: $BODY_FILE" >&2
    exit 1
fi

REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')

# 1. 署名を自動追加
SIG_FILE=$(mktemp)
trap 'rm -f "$SIG_FILE" "$SEND_FILE"' EXIT
bash "${SCRIPT_DIR}/_append_signature.sh" "$BODY_FILE" > "$SIG_FILE"

# 2. commit URL を署名直前に挿入 (. "-" の場合はスキップ)
SEND_FILE="$SIG_FILE"
if [[ "$COMMIT_ARG" != "-" ]]; then
    if ! COMMIT_SHA=$(git rev-parse "$COMMIT_ARG" 2>/dev/null); then
        echo "Error: コミットが見つかりません: $COMMIT_ARG" >&2
        exit 1
    fi
    COMMIT_SHORT=$(git rev-parse --short "$COMMIT_ARG")
    COMMIT_LINE="反映コミット: [\`${COMMIT_SHORT}\`](https://github.com/${REPO}/commit/${COMMIT_SHA})"
    SIGNATURE='*This comment was posted by AI Agent.*'

    SEND_FILE=$(mktemp)
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
    ' "$SIG_FILE" > "$SEND_FILE"
fi

# 返答コメントを投稿する.
# gh api の -F フィールドは型推論を伴うため, jq で JSON 化して --input で渡す.
jq -Rs '{body: .}' < "$SEND_FILE" \
    | gh api "repos/${REPO}/pulls/${PR_NUMBER}/comments/${COMMENT_ID}/replies" \
        --method POST --input - --jq '.html_url'