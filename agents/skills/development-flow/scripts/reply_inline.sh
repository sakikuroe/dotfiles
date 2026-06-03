#!/usr/bin/env bash
# Usage: reply_inline.sh <pr_number> <comment_id> <body_file> [--no-commit]
#
# PR のインライン review comment に返答を投稿する.
# 本文ファイルの末尾に署名 `*This comment was posted by AI Agent.*` を自動付加する.
# デフォルトで直近の commit URL を署名直前に挿入する.
# --no-commit を付けると, commit URL の挿入をスキップする.
#
# 本文はファイル経由で渡す (--body-file 相当). ヒアドキュメントでの
# バッククォートエスケープ事故を避けるための設計.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $# -lt 3 ]]; then
    echo "Usage: reply_inline.sh <pr_number> <comment_id> <body_file> [--no-commit]" >&2
    exit 1
fi

PR_NUMBER="$1"
COMMENT_ID="$2"
BODY_FILE="$3"
NO_COMMIT=false
[[ "${4:-}" == "--no-commit" ]] && NO_COMMIT=true

if [[ ! -f "$BODY_FILE" ]]; then
    echo "Error: body file not found: $BODY_FILE" >&2
    exit 1
fi

REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')

# 1. 署名を自動追加
SIG_FILE=$(mktemp)
trap 'rm -f "$SIG_FILE" "$SEND_FILE"' EXIT
bash "${SCRIPT_DIR}/_append_signature.sh" "$BODY_FILE" > "$SIG_FILE"

# 2. commit URL を署名直前に挿入（--no-commit の場合はスキップ）
SEND_FILE="$SIG_FILE"
if [[ "$NO_COMMIT" == false ]]; then
    SEND_FILE=$(mktemp)
    if ! COMMIT_SHA=$(git rev-parse HEAD 2>/dev/null); then
        echo "Error: コミットが存在しないか git rev-parse HEAD に失敗しました." >&2
        exit 1
    fi
    COMMIT_SHORT=$(git rev-parse --short HEAD)
    COMMIT_LINE="反映コミット: [\`${COMMIT_SHORT}\`](https://github.com/${REPO}/commit/${COMMIT_SHA})"
    SIGNATURE='*This comment was posted by AI Agent.*'

    awk -v commit="$COMMIT_LINE" -v sig="$SIGNATURE" '
        $0 == sig && !inserted {
            print commit
            print ""
            inserted = 1
        }
        { print }
    ' "$SIG_FILE" > "$SEND_FILE"
fi

# 返答コメントを投稿する.
# gh api の -F フィールドは型推論を伴うため, jq で JSON 化して --input で渡す.
jq -Rs '{body: .}' < "$SEND_FILE" \
    | gh api "repos/${REPO}/pulls/${PR_NUMBER}/comments/${COMMENT_ID}/replies" \
        --method POST --input - --jq '.html_url'
