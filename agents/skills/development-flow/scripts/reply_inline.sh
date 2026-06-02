#!/usr/bin/env bash
# Usage: reply_inline.sh <pr_number> <comment_id> <body_file> [--no-commit]
#
# PR のインライン review comment に返答を投稿する.
# デフォルトで直近の commit URL を本文中の署名直前に挿入する.
# 署名が見つからない場合は本文末尾に追加する.
# --no-commit を付けると, commit URL の挿入をスキップする.
#
# 本文はファイル経由で渡す (--body-file 相当). ヒアドキュメントでの
# バッククォートエスケープ事故を避けるための設計.

set -euo pipefail

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

# 送信用の本文ファイルを決定する.
# デフォルトでは本文中の署名直前に commit URL を挿入したファイルを作る.
# --no-commit のときはそのまま送信する.
SEND_FILE="$BODY_FILE"
if [[ "$NO_COMMIT" == false ]]; then
    SEND_FILE=$(mktemp)
    trap 'rm -f "$SEND_FILE"' EXIT
    if ! COMMIT_SHA=$(git rev-parse HEAD 2>/dev/null); then
        echo "Error: コミットが存在しないか git rev-parse HEAD に失敗しました." >&2
        exit 1
    fi
    COMMIT_SHORT=$(git rev-parse --short HEAD)
    COMMIT_LINE="反映コミット: [\`${COMMIT_SHORT}\`](https://github.com/${REPO}/commit/${COMMIT_SHA})"
    SIGNATURE='*This comment was posted by AI Agent.*'

    # 署名行 (`*This comment was posted by AI Agent.*`) を見つけたらその直前に commit URL と空行を挿入する.
    # 署名が無ければ末尾に空行 + commit URL を追加する.
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
    ' "$BODY_FILE" > "$SEND_FILE"
fi

# 返答コメントを投稿する.
# gh api の -F フィールドは型推論を伴うため, jq で JSON 化して --input で渡す.
jq -Rs '{body: .}' < "$SEND_FILE" \
    | gh api "repos/${REPO}/pulls/${PR_NUMBER}/comments/${COMMENT_ID}/replies" \
        --method POST --input - --jq '.html_url'
